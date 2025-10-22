# Performance Optimization Implementation Guide
**cc-tools Repository - Claude Code Plugins**
**Based on:** Performance Analysis Report 2025-10-22

---

## Quick Reference

### Optimization Impact Matrix

| Optimization | Priority | Effort | Token Savings | Size Savings | Scalability Gain |
|--------------|----------|--------|---------------|--------------|------------------|
| Split token-heavy commands | P1 | Medium | ~30K | ~120 KB | ⭐⭐ |
| Deduplicate agents | P1 | Low | ~69K | 271 KB | ⭐⭐⭐ |
| Fix metadata accuracy | P1 | Trivial | 0 | 0 | ⭐ (trust) |
| Progressive skill disclosure | P2 | Medium | ~50K | 0 | ⭐⭐⭐ |
| Deduplicate commands | P2 | Low | ~33K | 128 KB | ⭐⭐ |
| Enforce size budgets | P2 | Low | 0 | Prevent bloat | ⭐⭐⭐⭐ |
| Split marketplace | P3 | High | 0 | 0 | ⭐⭐⭐⭐⭐ |
| Content caching | P3 | Medium | 0 | 0 | ⭐⭐⭐ |
| Search indexing | P3 | High | 0 | 0 | ⭐⭐⭐⭐ |

---

## Priority 1: Critical Optimizations

### 1.1 Split Token-Heavy Commands

**Target Files:**
```
plugins/database-cloud-optimization/commands/cost-optimize.md (12,686 tokens)
plugins/api-testing-observability/commands/api-mock.md (10,879 tokens)
plugins/error-debugging/commands/error-trace.md (10,783 tokens)
plugins/error-diagnostics/commands/error-trace.md (10,783 tokens)
plugins/distributed-debugging/commands/debug-trace.md (10,229 tokens)
plugins/llm-application-dev/commands/ai-assistant.md (10,197 tokens)
```

**Strategy: Progressive Disclosure Pattern**

#### Step 1: Analyze Command Structure

For each command, identify:
- Core workflow (must-have)
- Examples (optional)
- Reference material (optional)
- Extended documentation (optional)

#### Step 2: Create Split Structure

**Example for `cost-optimize.md`:**

```
plugins/database-cloud-optimization/commands/
├── cost-optimize.md (3,000 tokens - main workflow)
├── cost-optimize/
│   ├── examples.md (3,500 tokens)
│   ├── reference.md (3,000 tokens)
│   └── advanced.md (3,186 tokens)
```

**Main file (`cost-optimize.md`):**
```markdown
# Cost Optimization Command

## Overview
[Core description - 200 tokens]

## Workflow
[Essential workflow steps - 2,500 tokens]

## Additional Resources
For detailed examples, see [examples.md](./cost-optimize/examples.md)
For reference material, see [reference.md](./cost-optimize/reference.md)
For advanced usage, see [advanced.md](./cost-optimize/advanced.md)

## Quick Start
[Minimal quick-start guide - 300 tokens]
```

#### Step 3: Update Command References

Update marketplace.json to point to the main file only:
```json
{
  "commands": [
    "./commands/cost-optimize.md"
  ]
}
```

**Validation:**
- Main file should be 2,500-4,000 tokens
- Supporting files referenced but not auto-loaded
- User can access detailed content when needed

**Estimated Savings:**
- 6 commands reduced from ~10,500 avg to ~3,500 avg
- Savings: 7,000 tokens × 6 = ~42,000 tokens initially loaded
- Total content preserved in separate files

---

### 1.2 Deduplicate Shared Agents

**Duplicated Agents Inventory:**

| Agent | Occurrences | Plugins Using It |
|-------|-------------|------------------|
| backend-architect.md | 6 | backend-development, backend-api-security, api-scaffolding, database-cloud-optimization, data-engineering, multi-platform-apps |
| code-reviewer.md | 6 | code-documentation, git-pr-workflows, code-refactoring, codebase-cleanup, full-stack-orchestration, api-scaffolding |
| test-automator.md | 4 | unit-testing, performance-testing-review, full-stack-orchestration, codebase-cleanup |
| debugger.md | 4 | debugging-toolkit, error-debugging, error-diagnostics, incident-response |
| ... | ... | ... |

#### Implementation Steps

**Step 1: Create Shared Directory**

```bash
mkdir -p .claude-plugin/shared/agents
```

**Step 2: Move Duplicated Agents**

```bash
# Move backend-architect.md
cp plugins/backend-development/agents/backend-architect.md \
   .claude-plugin/shared/agents/backend-architect.md

# Version it for stability
cp .claude-plugin/shared/agents/backend-architect.md \
   .claude-plugin/shared/agents/backend-architect@v1.2.md
```

**Step 3: Update Marketplace References**

Update all plugins using backend-architect:

```json
{
  "name": "backend-development",
  "agents": [
    "../../../.claude-plugin/shared/agents/backend-architect@v1.2.md",
    "./agents/graphql-architect.md",
    "./agents/tdd-orchestrator.md"
  ]
}
```

**Step 4: Remove Duplicates**

```bash
# Remove from individual plugins
rm plugins/backend-api-security/agents/backend-architect.md
rm plugins/api-scaffolding/agents/backend-architect.md
# ... repeat for all 6 instances
```

**Step 5: Add Version Management**

Create version manifest:

```json
// .claude-plugin/shared/agents/versions.json
{
  "backend-architect": {
    "current": "v1.2",
    "versions": {
      "v1.2": {
        "file": "backend-architect@v1.2.md",
        "size": "18.2 KB",
        "tokens": 4662,
        "updated": "2025-10-22"
      }
    }
  }
}
```

**Automation Script:**

```python
# scripts/deduplicate-agents.py
import json
from pathlib import Path
from collections import defaultdict

def find_duplicate_agents():
    """Find all duplicate agent files."""
    agents = defaultdict(list)

    for agent_file in Path('plugins').rglob('*/agents/*.md'):
        agent_name = agent_file.name
        agents[agent_name].append(agent_file)

    duplicates = {name: paths for name, paths in agents.items() if len(paths) > 1}
    return duplicates

def deduplicate_agent(agent_name, paths):
    """Move agent to shared directory and update references."""
    # 1. Copy to shared
    shared_path = Path('.claude-plugin/shared/agents') / agent_name
    shared_path.parent.mkdir(parents=True, exist_ok=True)

    # Use first occurrence as canonical version
    canonical = paths[0]
    shared_path.write_text(canonical.read_text())

    # 2. Update marketplace.json references
    marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

    for plugin in marketplace['plugins']:
        plugin_name = plugin['name']
        plugin_agents = plugin.get('agents', [])

        # Check if this plugin uses the duplicated agent
        for i, agent_path in enumerate(plugin_agents):
            if agent_name in agent_path:
                # Update to shared reference
                relative_path = f"../../../.claude-plugin/shared/agents/{agent_name}"
                plugin_agents[i] = relative_path

    # 3. Save updated marketplace
    Path('.claude-plugin/marketplace.json').write_text(
        json.dumps(marketplace, indent=2)
    )

    # 4. Remove duplicates
    for path in paths:
        path.unlink()

    print(f"✓ Deduplicated {agent_name}: {len(paths)} → 1 shared")

if __name__ == '__main__':
    duplicates = find_duplicate_agents()
    for agent_name, paths in duplicates.items():
        deduplicate_agent(agent_name, paths)

    print(f"\nTotal savings: {sum(len(p)-1 for p in duplicates.values())} files")
```

**Expected Results:**
- 30 agents: 87 files → 87 - 59 = 28 unique files + 30 shared = 58 total files
- Savings: 271 KB, ~69,414 tokens
- Maintenance: Single source of truth for shared agents

---

### 1.3 Fix Metadata Accuracy

**Current Discrepancy:**
```json
// .claude-plugin/marketplace.json (line 9)
"description": "... 87 specialized agents ..."
// ACTUAL: 146 agents
```

**Fix:**

```json
{
  "metadata": {
    "description": "Production-ready workflow orchestration with 64 focused plugins, 146 specialized agents, 50 skills, and 70 commands - optimized for granular installation and minimal token usage",
    "version": "1.2.0",
    "stats": {
      "plugins": 64,
      "agents": 146,
      "unique_agents": 87,
      "skills": 50,
      "commands": 70,
      "total_components": 266
    }
  }
}
```

**Validation Script:**

```python
# scripts/validate-metadata.py
import json
from pathlib import Path

marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

# Count components
plugin_count = len(marketplace['plugins'])
agent_count = sum(len(p.get('agents', [])) for p in marketplace['plugins'])
skill_count = sum(len(p.get('skills', [])) for p in marketplace['plugins'])
command_count = sum(len(p.get('commands', [])) for p in marketplace['plugins'])

# Count unique agents
all_agents = [a.split('/')[-1] for p in marketplace['plugins'] for a in p.get('agents', [])]
unique_agents = len(set(all_agents))

print(f"Actual counts:")
print(f"  Plugins: {plugin_count}")
print(f"  Agents: {agent_count} ({unique_agents} unique)")
print(f"  Skills: {skill_count}")
print(f"  Commands: {command_count}")

# Validate against metadata
claimed_agents = 87  # from current description
if agent_count != claimed_agents:
    print(f"\n⚠️  MISMATCH: Claimed {claimed_agents}, actual {agent_count}")
```

---

## Priority 2: High-Impact Optimizations

### 2.1 Progressive Disclosure for Skills

**Current State:**
- Skills are directories with SKILL.md files
- Average skill: 11.9 KB (~3,057 tokens)
- Largest: 25.4 KB (~6,514 tokens)

**Target State:**
- Skills have metadata + summary (500 tokens)
- Full content loaded only when activated

**Implementation:**

#### Step 1: Add Skill Metadata

Create skill manifest:

```json
// plugins/javascript-typescript/skills/javascript-testing-patterns/skill.json
{
  "name": "javascript-testing-patterns",
  "version": "1.0.0",
  "summary": "Comprehensive testing strategies using Jest, Vitest, and Testing Library for unit tests, integration tests, and end-to-end testing with mocking, fixtures, and test-driven development.",
  "preview": {
    "description": "Master JavaScript/TypeScript testing with modern frameworks and best practices",
    "use_cases": [
      "Unit testing with Jest/Vitest",
      "Integration testing patterns",
      "E2E testing with Testing Library",
      "Mocking strategies",
      "Test-driven development"
    ],
    "technologies": ["Jest", "Vitest", "Testing Library", "Cypress", "Playwright"],
    "complexity": "intermediate",
    "estimated_tokens": 6514
  },
  "content": {
    "summary_file": "SUMMARY.md",
    "full_file": "SKILL.md",
    "references": ["references/", "examples/"]
  }
}
```

#### Step 2: Create Skill Summaries

**SUMMARY.md (500 tokens max):**
```markdown
# JavaScript Testing Patterns

## Overview
Comprehensive testing strategies for JavaScript/TypeScript applications using modern frameworks.

## Key Capabilities
- Unit testing with Jest and Vitest
- Integration and E2E testing
- Mocking and fixture patterns
- Test-driven development workflows

## When to Use
- Setting up new test infrastructure
- Improving test coverage and quality
- Implementing TDD/BDD workflows
- Migrating between testing frameworks

## Quick Example
[Minimal 10-line example]

For full content, activate this skill.
```

#### Step 3: Update Marketplace

```json
{
  "skills": [
    {
      "path": "./skills/javascript-testing-patterns",
      "manifest": "./skills/javascript-testing-patterns/skill.json",
      "preview_only": true
    }
  ]
}
```

**Automation:**

```python
# scripts/generate-skill-summaries.py
from pathlib import Path

def generate_skill_summary(skill_dir: Path):
    """Generate summary from full SKILL.md."""
    skill_md = skill_dir / 'SKILL.md'
    content = skill_md.read_text()

    # Extract first 500 tokens (roughly first 2000 chars)
    summary = content[:2000]

    # Add call to action
    summary += "\n\n---\n**For full content, activate this skill.**\n"

    # Write summary
    (skill_dir / 'SUMMARY.md').write_text(summary)

    print(f"✓ Generated summary for {skill_dir.name}")

for skill_dir in Path('plugins').rglob('*/skills/*'):
    if skill_dir.is_dir() and (skill_dir / 'SKILL.md').exists():
        generate_skill_summary(skill_dir)
```

**Expected Savings:**
- 50 skills × avg 3,057 tokens = 152,850 tokens
- Preview only: 50 × 500 tokens = 25,000 tokens
- Savings when skill not activated: 127,850 tokens (83% reduction)

---

### 2.2 Deduplicate Commands

**Duplicated Commands:**

| Command | Occurrences | Size Each | Total Waste |
|---------|-------------|-----------|-------------|
| error-trace.md | 2 | 42 KB | 42 KB |
| error-analysis.md | 2 | 35 KB | 35 KB |
| refactor-clean.md | 2 | 24 KB | 24 KB |
| deps-audit.md | 2 | 28 KB | 28 KB |

**Strategy: Template Parameterization**

#### Example: error-trace.md

**Shared Template:**
```markdown
// .claude-plugin/shared/commands/error-trace-template.md

# Error Trace Command

## Configuration
<!-- Plugin-specific config loaded from error-trace.config.json -->

## Core Workflow
[Common workflow - 80% of content]

## Plugin-Specific Behavior
<!-- Loaded from plugin's error-trace-plugin.md -->

## Examples
<!-- Loaded from examples/ directory -->
```

**Plugin-Specific Config:**
```json
// plugins/error-debugging/commands/error-trace.config.json
{
  "plugin_name": "error-debugging",
  "focus": "development-time debugging",
  "additional_context": "./error-trace-plugin.md",
  "examples": ["./examples/nodejs-error.md", "./examples/browser-error.md"]
}
```

**Plugin-Specific Content (small):**
```markdown
// plugins/error-debugging/commands/error-trace-plugin.md (5 KB)

## Development-Time Debugging Focus
[Plugin-specific additions]
```

**Marketplace Reference:**
```json
{
  "commands": [
    {
      "template": "../../../.claude-plugin/shared/commands/error-trace-template.md",
      "config": "./commands/error-trace.config.json",
      "overrides": "./commands/error-trace-plugin.md"
    }
  ]
}
```

**Expected Savings:**
- 4 command pairs: 132 KB total waste
- After templating: 4 × 5 KB = 20 KB plugin-specific content
- Savings: 112 KB (~28,000 tokens)

---

### 2.3 Enforce Plugin Size Budgets

**Target:** Prevent future bloat, maintain consistent performance

**Budget Definitions:**

```yaml
# .claude-plugin/size-budgets.yml
plugin_limits:
  # Token limits
  max_total_tokens: 15000
  max_single_file_tokens: 8000
  warn_at_tokens: 10000

  # Component limits
  max_components: 6
  max_agents: 4
  max_skills: 4
  max_commands: 3

  # File size limits
  max_file_size_kb: 30
  warn_at_file_size_kb: 20

  # Overall limits
  max_plugin_size_mb: 0.5

  # Exceptions (plugins allowed to exceed limits)
  exceptions:
    - observability-monitoring  # 10 components
    - cloud-infrastructure      # 10 components
    - cicd-automation           # 10 components
```

**Validation Script:**

```python
# scripts/validate-plugin-sizes.py
import yaml
from pathlib import Path

budgets = yaml.safe_load(Path('.claude-plugin/size-budgets.yml').read_text())

def check_plugin_size(plugin_dir: Path):
    """Validate plugin against size budgets."""
    plugin_name = plugin_dir.name

    # Skip exceptions
    if plugin_name in budgets['plugin_limits']['exceptions']:
        print(f"⏭️  {plugin_name}: Exception allowed")
        return True

    # Count components
    agents = len(list(plugin_dir.glob('agents/*.md')))
    skills = len(list(plugin_dir.glob('skills/*')))
    commands = len(list(plugin_dir.glob('commands/*.md')))
    total_components = agents + skills + commands

    # Calculate tokens (rough: file size / 4)
    total_size = sum(f.stat().st_size for f in plugin_dir.rglob('*.md'))
    total_tokens = total_size // 4

    # Check limits
    violations = []

    if total_tokens > budgets['plugin_limits']['max_total_tokens']:
        violations.append(f"Total tokens {total_tokens} exceeds limit {budgets['plugin_limits']['max_total_tokens']}")

    if total_components > budgets['plugin_limits']['max_components']:
        violations.append(f"Total components {total_components} exceeds limit {budgets['plugin_limits']['max_components']}")

    # Check individual file sizes
    for md_file in plugin_dir.rglob('*.md'):
        file_tokens = md_file.stat().st_size // 4
        if file_tokens > budgets['plugin_limits']['max_single_file_tokens']:
            violations.append(f"{md_file.name}: {file_tokens} tokens exceeds {budgets['plugin_limits']['max_single_file_tokens']}")

    # Report
    if violations:
        print(f"❌ {plugin_name}: FAILED")
        for v in violations:
            print(f"   - {v}")
        return False
    else:
        print(f"✓ {plugin_name}: OK ({total_tokens} tokens, {total_components} components)")
        return True

# Check all plugins
all_pass = True
for plugin_dir in sorted(Path('plugins').iterdir()):
    if plugin_dir.is_dir():
        if not check_plugin_size(plugin_dir):
            all_pass = False

exit(0 if all_pass else 1)
```

**CI Integration (GitHub Actions):**

```yaml
# .github/workflows/validate-sizes.yml
name: Validate Plugin Sizes

on: [pull_request, push]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install pyyaml
      - name: Validate plugin sizes
        run: python scripts/validate-plugin-sizes.py
```

---

## Priority 3: Long-term Scalability

### 3.1 Split Marketplace.json (for 200+ plugins)

**Trigger:** When approaching 150 plugins
**Current:** 1,956 lines, 56.6 KB (64 plugins)
**Projected at 200:** 6,112 lines, 176.9 KB

**Target Architecture:**

```
.claude-plugin/
├── index.json (main registry, 5-10 KB)
├── categories.json (category index)
├── plugins/
│   ├── backend-development.json
│   ├── frontend-development.json
│   ├── database-design.json
│   └── ... (64+ individual files)
└── cache/
    └── full-marketplace.json (generated, gitignored)
```

**Implementation:**

#### Step 1: Create Plugin Manifest Schema

```json
// .claude-plugin/plugins/backend-development.json
{
  "name": "backend-development",
  "source": "../../../plugins/backend-development",
  "version": "1.2.0",
  "category": "development",
  "keywords": ["backend", "api", "architecture"],
  "agents": [
    "./agents/backend-architect.md",
    "./agents/graphql-architect.md",
    "./agents/tdd-orchestrator.md"
  ],
  "skills": [
    "./skills/api-design-principles",
    "./skills/architecture-patterns",
    "./skills/microservices-patterns"
  ],
  "commands": [
    "./commands/api-scaffold.md"
  ]
}
```

#### Step 2: Create Registry Index

```json
// .claude-plugin/index.json
{
  "name": "claude-code-workflows",
  "version": "1.2.0",
  "registry_version": "2.0",
  "metadata": {
    "plugins": 64,
    "agents": 146,
    "skills": 50,
    "commands": 70
  },
  "plugins": [
    {
      "name": "backend-development",
      "manifest": "./plugins/backend-development.json",
      "category": "development",
      "version": "1.2.0"
    },
    {
      "name": "frontend-development",
      "manifest": "./plugins/frontend-development.json",
      "category": "development",
      "version": "1.2.0"
    }
    // ... lightweight references only
  ],
  "categories": "./categories.json"
}
```

#### Step 3: Migration Script

```python
# scripts/migrate-to-split-marketplace.py
import json
from pathlib import Path

def split_marketplace():
    """Split monolithic marketplace.json into individual plugin manifests."""

    # Load current marketplace
    marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

    # Create plugins directory
    plugins_dir = Path('.claude-plugin/plugins')
    plugins_dir.mkdir(exist_ok=True)

    # Create index
    index = {
        'name': marketplace['name'],
        'version': marketplace['metadata']['version'],
        'registry_version': '2.0',
        'metadata': marketplace['metadata'],
        'plugins': []
    }

    # Split each plugin
    for plugin in marketplace['plugins']:
        plugin_name = plugin['name']

        # Write individual manifest
        manifest_path = plugins_dir / f"{plugin_name}.json"
        manifest_path.write_text(json.dumps(plugin, indent=2))

        # Add to index (lightweight reference)
        index['plugins'].append({
            'name': plugin_name,
            'manifest': f"./plugins/{plugin_name}.json",
            'category': plugin.get('category'),
            'version': plugin.get('version')
        })

    # Write index
    Path('.claude-plugin/index.json').write_text(json.dumps(index, indent=2))

    # Backup original
    Path('.claude-plugin/marketplace.json.backup').write_text(
        Path('.claude-plugin/marketplace.json').read_text()
    )

    print(f"✓ Split {len(marketplace['plugins'])} plugins")
    print(f"  Index: {Path('.claude-plugin/index.json').stat().st_size / 1024:.1f} KB")
    print(f"  Avg manifest: {sum(p.stat().st_size for p in plugins_dir.glob('*.json')) / len(list(plugins_dir.glob('*.json'))) / 1024:.1f} KB")

split_marketplace()
```

**Performance Improvement:**

| Metric | Monolithic (200 plugins) | Split Architecture |
|--------|-------------------------|-------------------|
| Initial load | 177 KB (full file) | 10 KB (index only) |
| Plugin lookup | Parse full file | Read single manifest (0.9 KB) |
| Concurrent access | Lock entire file | Lock single manifest |
| Git conflicts | High risk | Minimal risk |

---

### 3.2 Content Caching

**Implementation:**

```python
# .claude-plugin/cache/plugin-cache.py
from pathlib import Path
import json
import hashlib
import time

class PluginCache:
    """In-memory cache for plugin content with file-watch invalidation."""

    def __init__(self, cache_dir: Path = Path('.claude-plugin/cache')):
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(exist_ok=True)
        self.cache = {}
        self.file_hashes = {}

    def get_plugin_manifest(self, plugin_name: str):
        """Get cached plugin manifest or load from disk."""
        manifest_path = Path(f'.claude-plugin/plugins/{plugin_name}.json')

        # Calculate file hash
        file_hash = self._hash_file(manifest_path)

        # Check cache
        if plugin_name in self.cache and self.file_hashes.get(plugin_name) == file_hash:
            return self.cache[plugin_name]

        # Load from disk
        manifest = json.loads(manifest_path.read_text())

        # Update cache
        self.cache[plugin_name] = manifest
        self.file_hashes[plugin_name] = file_hash

        return manifest

    def get_agent_content(self, agent_path: Path):
        """Get cached agent content."""
        cache_key = str(agent_path)
        file_hash = self._hash_file(agent_path)

        if cache_key in self.cache and self.file_hashes.get(cache_key) == file_hash:
            return self.cache[cache_key]

        content = agent_path.read_text()
        self.cache[cache_key] = content
        self.file_hashes[cache_key] = file_hash

        return content

    def _hash_file(self, path: Path) -> str:
        """Calculate file hash for cache invalidation."""
        stat = path.stat()
        return hashlib.md5(f"{stat.st_mtime}:{stat.st_size}".encode()).hexdigest()

    def invalidate(self, path: Path = None):
        """Invalidate cache for specific file or entire cache."""
        if path:
            cache_key = str(path)
            self.cache.pop(cache_key, None)
            self.file_hashes.pop(cache_key, None)
        else:
            self.cache.clear()
            self.file_hashes.clear()
```

---

### 3.3 Search Indexing

**Implementation:**

```python
# .claude-plugin/search/index.py
from pathlib import Path
import json
from collections import defaultdict

class PluginSearchIndex:
    """Indexed search for fast plugin/agent/skill discovery."""

    def __init__(self):
        self.category_index = defaultdict(list)
        self.keyword_index = defaultdict(list)
        self.agent_index = defaultdict(list)
        self.skill_index = defaultdict(list)

    def build_index(self):
        """Build search indexes from plugin manifests."""
        index_data = Path('.claude-plugin/index.json')
        index = json.loads(index_data.read_text())

        for plugin_ref in index['plugins']:
            plugin_name = plugin_ref['name']
            manifest_path = Path('.claude-plugin') / plugin_ref['manifest']
            plugin = json.loads(manifest_path.read_text())

            # Index by category
            category = plugin.get('category', 'other')
            self.category_index[category].append(plugin_name)

            # Index by keywords
            for keyword in plugin.get('keywords', []):
                self.keyword_index[keyword.lower()].append(plugin_name)

            # Index by agents
            for agent_path in plugin.get('agents', []):
                agent_name = agent_path.split('/')[-1].replace('.md', '')
                self.agent_index[agent_name].append(plugin_name)

            # Index by skills
            for skill_path in plugin.get('skills', []):
                skill_name = skill_path.split('/')[-1]
                self.skill_index[skill_name].append(plugin_name)

    def search_by_category(self, category: str) -> list:
        """O(1) category lookup."""
        return self.category_index.get(category, [])

    def search_by_keyword(self, keyword: str) -> list:
        """O(1) keyword lookup."""
        return self.keyword_index.get(keyword.lower(), [])

    def search_by_agent(self, agent_name: str) -> list:
        """O(1) agent lookup."""
        return self.agent_index.get(agent_name, [])

    def fuzzy_search(self, query: str) -> list:
        """Fuzzy search across all indexes."""
        query_lower = query.lower()
        results = set()

        # Search keywords
        for keyword, plugins in self.keyword_index.items():
            if query_lower in keyword:
                results.update(plugins)

        # Search agent names
        for agent, plugins in self.agent_index.items():
            if query_lower in agent.lower():
                results.update(plugins)

        return list(results)

    def save_index(self, path: Path = Path('.claude-plugin/cache/search-index.json')):
        """Persist index to disk for fast startup."""
        index_data = {
            'category': dict(self.category_index),
            'keyword': dict(self.keyword_index),
            'agent': dict(self.agent_index),
            'skill': dict(self.skill_index)
        }
        path.write_text(json.dumps(index_data, indent=2))
```

**Usage:**

```python
# Fast plugin discovery
index = PluginSearchIndex()
index.build_index()
index.save_index()

# O(1) lookups
backend_plugins = index.search_by_category('development')
api_plugins = index.search_by_keyword('api')
plugins_with_backend_architect = index.search_by_agent('backend-architect')

# Fuzzy search
testing_plugins = index.fuzzy_search('test')
```

---

## Implementation Timeline

### Sprint 1 (Week 1-2): Priority 1 Critical Fixes

**Goals:**
- Split 6 token-heavy commands
- Deduplicate shared agents
- Fix metadata accuracy

**Deliverables:**
- 6 commands reduced to 3K tokens each
- 30 shared agents in `.claude-plugin/shared/agents/`
- Accurate marketplace metadata
- Validation scripts

**Success Metrics:**
- 0 commands over 10K tokens
- 271 KB savings from agent deduplication
- Metadata matches actual counts

### Sprint 2 (Week 3-4): Priority 2 High-Impact

**Goals:**
- Implement progressive skill disclosure
- Deduplicate command templates
- Enforce size budgets

**Deliverables:**
- 50 skill summaries generated
- Command template system
- Size budget CI validation

**Success Metrics:**
- 127K token savings (skill previews)
- 128 KB command deduplication savings
- All plugins pass size validation

### Sprint 3 (Month 2-3): Priority 3 Long-term

**Goals:**
- Split marketplace architecture
- Implement caching
- Build search indexes

**Deliverables:**
- Split registry system
- Plugin content cache
- Search index system

**Success Metrics:**
- 10 KB index file (vs 57 KB monolith)
- O(1) search performance
- Ready for 200+ plugins

---

## Monitoring & Validation

### Automated Checks

```yaml
# .github/workflows/performance-validation.yml
name: Performance Validation

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Validate plugin sizes
        run: python scripts/validate-plugin-sizes.py

      - name: Check for duplicates
        run: python scripts/check-duplicates.py

      - name: Validate metadata
        run: python scripts/validate-metadata.py

      - name: Performance report
        run: python scripts/performance-report.py
```

### Performance Dashboard

Track key metrics:

```python
# scripts/performance-report.py
def generate_performance_report():
    """Generate performance metrics report."""

    metrics = {
        'total_plugins': count_plugins(),
        'total_agents': count_agents(),
        'unique_agents': count_unique_agents(),
        'duplication_rate': calculate_duplication_rate(),
        'avg_plugin_tokens': calculate_avg_plugin_tokens(),
        'token_heavy_commands': count_heavy_commands(),
        'marketplace_size_kb': get_marketplace_size(),
        'total_tokens': calculate_total_tokens()
    }

    # Compare against targets
    targets = {
        'duplication_rate': 0.05,  # <5%
        'avg_plugin_tokens': 12000,
        'token_heavy_commands': 0,
        'marketplace_size_kb': 100
    }

    print("Performance Report")
    print("=" * 50)
    for metric, value in metrics.items():
        target = targets.get(metric)
        status = "✓" if target and value <= target else "⚠️"
        print(f"{status} {metric}: {value}")
```

---

## Success Criteria

### Phase 1 Complete When:
- ✅ Zero commands over 10K tokens
- ✅ All 30 shared agents deduplicated
- ✅ Metadata accuracy at 100%
- ✅ Size validation in CI

### Phase 2 Complete When:
- ✅ All skills have summaries
- ✅ Command duplication under 5%
- ✅ Size budgets enforced
- ✅ Token savings >15%

### Phase 3 Complete When:
- ✅ Split architecture deployed
- ✅ Search index operational
- ✅ Caching system active
- ✅ Ready for 200+ plugins

---

## Appendix: Performance Testing

### Load Testing Script

```python
# scripts/performance-test.py
import time
import json
from pathlib import Path

def benchmark_marketplace_parse():
    """Benchmark marketplace.json parsing."""
    path = Path('.claude-plugin/marketplace.json')

    times = []
    for _ in range(100):
        start = time.perf_counter()
        data = json.loads(path.read_text())
        times.append(time.perf_counter() - start)

    print(f"Parse time: {sum(times)/len(times)*1000:.2f}ms (avg over 100 runs)")
    print(f"Min: {min(times)*1000:.2f}ms, Max: {max(times)*1000:.2f}ms")

def benchmark_plugin_search():
    """Benchmark plugin search."""
    marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

    start = time.perf_counter()
    results = [p for p in marketplace['plugins'] if 'backend' in p['name']]
    elapsed = time.perf_counter() - start

    print(f"Search time: {elapsed*1000:.2f}ms for {len(results)} matches")

benchmark_marketplace_parse()
benchmark_plugin_search()
```

---

**End of Optimization Guide**
