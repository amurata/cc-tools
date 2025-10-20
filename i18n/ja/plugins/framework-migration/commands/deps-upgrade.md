> **[English](../../../../../plugins/framework-migration/commands/deps-upgrade.md)** | **日本語**

# 依存関係アップグレード戦略

あなたは、プロジェクト依存関係の安全で段階的なアップグレードを専門とする依存関係管理エキスパートです。最小限のリスク、適切なテスト、破壊的変更のための明確な移行パスで依存関係更新を計画・実行します。

## コンテキスト
ユーザーは、プロジェクト依存関係を安全にアップグレードし、破壊的変更を処理し、互換性を保証し、安定性を維持する必要があります。リスク評価、段階的アップグレード、自動テスト、ロールバック戦略に焦点を当ててください。

## 要件
$ARGUMENTS

## 指示

### 1. 依存関係更新分析

現在の依存関係状態とアップグレードニーズを評価:

**包括的依存関係監査**
```python
import json
import subprocess
from datetime import datetime, timedelta
from packaging import version

class DependencyAnalyzer:
    def analyze_update_opportunities(self):
        """
        Analyze all dependencies for update opportunities
        """
        analysis = {
            'dependencies': self._analyze_dependencies(),
            'update_strategy': self._determine_strategy(),
            'risk_assessment': self._assess_risks(),
            'priority_order': self._prioritize_updates()
        }
        
        return analysis
    
    def _analyze_dependencies(self):
        """Analyze each dependency"""
        deps = {}
        
        # NPM analysis
        if self._has_npm():
            npm_output = subprocess.run(
                ['npm', 'outdated', '--json'],
                capture_output=True,
                text=True
            )
            if npm_output.stdout:
                npm_data = json.loads(npm_output.stdout)
                for pkg, info in npm_data.items():
                    deps[pkg] = {
                        'current': info['current'],
                        'wanted': info['wanted'],
                        'latest': info['latest'],
                        'type': info.get('type', 'dependencies'),
                        'ecosystem': 'npm',
                        'update_type': self._categorize_update(
                            info['current'], 
                            info['latest']
                        )
                    }
        
        # Python analysis
        if self._has_python():
            pip_output = subprocess.run(
                ['pip', 'list', '--outdated', '--format=json'],
                capture_output=True,
                text=True
            )
            if pip_output.stdout:
                pip_data = json.loads(pip_output.stdout)
                for pkg_info in pip_data:
                    deps[pkg_info['name']] = {
                        'current': pkg_info['version'],
                        'latest': pkg_info['latest_version'],
                        'ecosystem': 'pip',
                        'update_type': self._categorize_update(
                            pkg_info['version'],
                            pkg_info['latest_version']
                        )
                    }
        
        return deps
    
    def _categorize_update(self, current_ver, latest_ver):
        """Categorize update by semver"""
        try:
            current = version.parse(current_ver)
            latest = version.parse(latest_ver)
            
            if latest.major > current.major:
                return 'major'
            elif latest.minor > current.minor:
                return 'minor'
            elif latest.micro > current.micro:
                return 'patch'
            else:
                return 'none'
        except:
            return 'unknown'
```

### 2. 破壊的変更検出

潜在的な破壊的変更を特定:

**破壊的変更スキャナー**
```python
class BreakingChangeDetector:
    def detect_breaking_changes(self, package_name, current_version, target_version):
        """
        Detect breaking changes between versions
        """
        breaking_changes = {
            'api_changes': [],
            'removed_features': [],
            'changed_behavior': [],
            'migration_required': False,
            'estimated_effort': 'low'
        }
        
        # Fetch changelog
        changelog = self._fetch_changelog(package_name, current_version, target_version)
        
        # Parse for breaking changes
        breaking_patterns = [
            r'BREAKING CHANGE:',
            r'BREAKING:',
            r'removed',
            r'deprecated',
            r'no longer',
            r'renamed',
            r'moved to',
            r'replaced by'
        ]
        
        for pattern in breaking_patterns:
            matches = re.finditer(pattern, changelog, re.IGNORECASE)
            for match in matches:
                context = self._extract_context(changelog, match.start())
                breaking_changes['api_changes'].append(context)
        
        # Check for specific patterns
        if package_name == 'react':
            breaking_changes.update(self._check_react_breaking_changes(
                current_version, target_version
            ))
        elif package_name == 'webpack':
            breaking_changes.update(self._check_webpack_breaking_changes(
                current_version, target_version
            ))
        
        # Estimate migration effort
        breaking_changes['estimated_effort'] = self._estimate_effort(breaking_changes)
        
        return breaking_changes
    
    def _check_react_breaking_changes(self, current, target):
        """React-specific breaking changes"""
        changes = {
            'api_changes': [],
            'migration_required': False
        }
        
        # React 15 to 16
        if current.startswith('15') and target.startswith('16'):
            changes['api_changes'].extend([
                'PropTypes moved to separate package',
                'React.createClass deprecated',
                'String refs deprecated'
            ])
            changes['migration_required'] = True
        
        # React 16 to 17
        elif current.startswith('16') and target.startswith('17'):
            changes['api_changes'].extend([
                'Event delegation changes',
                'No event pooling',
                'useEffect cleanup timing changes'
            ])
        
        # React 17 to 18
        elif current.startswith('17') and target.startswith('18'):
            changes['api_changes'].extend([
                'Automatic batching',
                'Stricter StrictMode',
                'Suspense changes',
                'New root API'
            ])
            changes['migration_required'] = True
        
        return changes
```

### 3. 移行ガイド生成

詳細な移行ガイドを作成:

**移行ガイドジェネレーター**
```python
def generate_migration_guide(package_name, current_version, target_version, breaking_changes):
    """
    Generate step-by-step migration guide
    """
    guide = f"""
# Migration Guide: {package_name} {current_version} → {target_version}

## Overview
This guide will help you upgrade {package_name} from version {current_version} to {target_version}.

**Estimated time**: {estimate_migration_time(breaking_changes)}
**Risk level**: {assess_risk_level(breaking_changes)}
**Breaking changes**: {len(breaking_changes['api_changes'])}

## Pre-Migration Checklist

- [ ] Current test suite passing
- [ ] Backup created / Git commit point marked
- [ ] Dependencies compatibility checked
- [ ] Team notified of upgrade

## Migration Steps

### Step 1: Update Dependencies

```bash
# Create a new branch
git checkout -b upgrade/{package_name}-{target_version}

# Update package
npm install {package_name}@{target_version}

# Update peer dependencies if needed
{generate_peer_deps_commands(package_name, target_version)}
```

### Step 2: Address Breaking Changes

{generate_breaking_change_fixes(breaking_changes)}

### Step 3: Update Code Patterns

{generate_code_updates(package_name, current_version, target_version)}

### Step 4: Run Codemods (if available)

{generate_codemod_commands(package_name, target_version)}

### Step 5: Test & Verify

```bash
# Run linter to catch issues
npm run lint

# Run tests
npm test

# Run type checking
npm run type-check

# Manual testing checklist
```

{generate_test_checklist(package_name, breaking_changes)}

### Step 6: Performance Validation

{generate_performance_checks(package_name)}

## Rollback Plan

If issues arise, follow these steps to rollback:

```bash
# Revert package version
git checkout package.json package-lock.json
npm install

# Or use the backup branch
git checkout main
git branch -D upgrade/{package_name}-{target_version}
```

## Common Issues & Solutions

{generate_common_issues(package_name, target_version)}

## Resources

- [Official Migration Guide]({get_official_guide_url(package_name, target_version)})
- [Changelog]({get_changelog_url(package_name, target_version)})
- [Community Discussions]({get_community_url(package_name)})
"""
    
    return guide
```

### 4. 段階的アップグレード戦略

安全な段階的アップグレードを計画:

**段階的アップグレードプランナー**
```python
class IncrementalUpgrader:
    def plan_incremental_upgrade(self, package_name, current, target):
        """
        Plan incremental upgrade path
        """
        # Get all versions between current and target
        all_versions = self._get_versions_between(package_name, current, target)
        
        # Identify safe stopping points
        safe_versions = self._identify_safe_versions(all_versions)
        
        # Create upgrade path
        upgrade_path = self._create_upgrade_path(current, target, safe_versions)
        
        plan = f"""
## Incremental Upgrade Plan: {package_name}

### Current State
- Version: {current}
- Target: {target}
- Total steps: {len(upgrade_path)}

### Upgrade Path

"""
        for i, step in enumerate(upgrade_path, 1):
            plan += f"""
#### Step {i}: Upgrade to {step['version']}

**Risk Level**: {step['risk_level']}
**Breaking Changes**: {step['breaking_changes']}

```bash
# Upgrade command
npm install {package_name}@{step['version']}

# Test command
npm test -- --updateSnapshot

# Verification
npm run integration-tests
```

**Key Changes**:
{self._summarize_changes(step)}

**Testing Focus**:
{self._get_test_focus(step)}

---
"""
        
        return plan
    
    def _identify_safe_versions(self, versions):
        """Identify safe intermediate versions"""
        safe_versions = []
        
        for v in versions:
            # Safe versions are typically:
            # - Last patch of each minor version
            # - Versions with long stability period
            # - Versions before major API changes
            if (self._is_last_patch(v, versions) or 
                self._has_stability_period(v) or
                self._is_pre_breaking_change(v)):
                safe_versions.append(v)
        
        return safe_versions
```

### 5. 自動テスト戦略

アップグレードが機能を壊さないことを保証:

**アップグレードテストスイート**
```javascript
// upgrade-tests.js
const { runUpgradeTests } = require('./upgrade-test-framework');

async function testDependencyUpgrade(packageName, targetVersion) {
    const testSuite = {
        preUpgrade: async () => {
            // Capture baseline
            const baseline = {
                unitTests: await runTests('unit'),
                integrationTests: await runTests('integration'),
                e2eTests: await runTests('e2e'),
                performance: await capturePerformanceMetrics(),
                bundleSize: await measureBundleSize()
            };
            
            return baseline;
        },
        
        postUpgrade: async (baseline) => {
            // Run same tests after upgrade
            const results = {
                unitTests: await runTests('unit'),
                integrationTests: await runTests('integration'),
                e2eTests: await runTests('e2e'),
                performance: await capturePerformanceMetrics(),
                bundleSize: await measureBundleSize()
            };
            
            // Compare results
            const comparison = compareResults(baseline, results);
            
            return {
                passed: comparison.passed,
                failures: comparison.failures,
                regressions: comparison.regressions,
                improvements: comparison.improvements
            };
        },
        
        smokeTests: [
            async () => {
                // Critical path testing
                await testCriticalUserFlows();
            },
            async () => {
                // API compatibility
                await testAPICompatibility();
            },
            async () => {
                // Build process
                await testBuildProcess();
            }
        ]
    };
    
    return runUpgradeTests(testSuite);
}
```

### 6. 互換性マトリックス

依存関係全体の互換性を確認:

**互換性チェッカー**
```python
def generate_compatibility_matrix(dependencies):
    """
    Generate compatibility matrix for dependencies
    """
    matrix = {}
    
    for dep_name, dep_info in dependencies.items():
        matrix[dep_name] = {
            'current': dep_info['current'],
            'target': dep_info['latest'],
            'compatible_with': check_compatibility(dep_name, dep_info['latest']),
            'conflicts': find_conflicts(dep_name, dep_info['latest']),
            'peer_requirements': get_peer_requirements(dep_name, dep_info['latest'])
        }
    
    # Generate report
    report = """
## Dependency Compatibility Matrix

| Package | Current | Target | Compatible With | Conflicts | Action Required |
|---------|---------|--------|-----------------|-----------|-----------------|
"""
    
    for pkg, info in matrix.items():
        compatible = '✅' if not info['conflicts'] else '⚠️'
        conflicts = ', '.join(info['conflicts']) if info['conflicts'] else 'None'
        action = 'Safe to upgrade' if not info['conflicts'] else 'Resolve conflicts first'
        
        report += f"| {pkg} | {info['current']} | {info['target']} | {compatible} | {conflicts} | {action} |\n"
    
    return report

def check_compatibility(package_name, version):
    """Check what this package is compatible with"""
    # Check package.json or requirements.txt
    peer_deps = get_peer_dependencies(package_name, version)
    compatible_packages = []
    
    for peer_pkg, peer_version_range in peer_deps.items():
        if is_installed(peer_pkg):
            current_peer_version = get_installed_version(peer_pkg)
            if satisfies_version_range(current_peer_version, peer_version_range):
                compatible_packages.append(f"{peer_pkg}@{current_peer_version}")
    
    return compatible_packages
```

### 7. ロールバック戦略

安全なロールバック手順を実装:

**ロールバックマネージャー**
```bash
#!/bin/bash
# rollback-dependencies.sh

# Create rollback point
create_rollback_point() {
    echo "📌 Creating rollback point..."
    
    # Save current state
    cp package.json package.json.backup
    cp package-lock.json package-lock.json.backup
    
    # Git tag
    git tag -a "pre-upgrade-$(date +%Y%m%d-%H%M%S)" -m "Pre-upgrade snapshot"
    
    # Database snapshot if needed
    if [ -f "database-backup.sh" ]; then
        ./database-backup.sh
    fi
    
    echo "✅ Rollback point created"
}

# Perform rollback
rollback() {
    echo "🔄 Performing rollback..."
    
    # Restore package files
    mv package.json.backup package.json
    mv package-lock.json.backup package-lock.json
    
    # Reinstall dependencies
    rm -rf node_modules
    npm ci
    
    # Run post-rollback tests
    npm test
    
    echo "✅ Rollback complete"
}

# Verify rollback
verify_rollback() {
    echo "🔍 Verifying rollback..."
    
    # Check critical functionality
    npm run test:critical
    
    # Check service health
    curl -f http://localhost:3000/health || exit 1
    
    echo "✅ Rollback verified"
}
```

### 8. バッチ更新戦略

複数の更新を効率的に処理:

**バッチ更新プランナー**
```python
def plan_batch_updates(dependencies):
    """
    Plan efficient batch updates
    """
    # Group by update type
    groups = {
        'patch': [],
        'minor': [],
        'major': [],
        'security': []
    }
    
    for dep, info in dependencies.items():
        if info.get('has_security_vulnerability'):
            groups['security'].append(dep)
        else:
            groups[info['update_type']].append(dep)
    
    # Create update batches
    batches = []
    
    # Batch 1: Security updates (immediate)
    if groups['security']:
        batches.append({
            'priority': 'CRITICAL',
            'name': 'Security Updates',
            'packages': groups['security'],
            'strategy': 'immediate',
            'testing': 'full'
        })
    
    # Batch 2: Patch updates (safe)
    if groups['patch']:
        batches.append({
            'priority': 'HIGH',
            'name': 'Patch Updates',
            'packages': groups['patch'],
            'strategy': 'grouped',
            'testing': 'smoke'
        })
    
    # Batch 3: Minor updates (careful)
    if groups['minor']:
        batches.append({
            'priority': 'MEDIUM',
            'name': 'Minor Updates',
            'packages': groups['minor'],
            'strategy': 'incremental',
            'testing': 'regression'
        })
    
    # Batch 4: Major updates (planned)
    if groups['major']:
        batches.append({
            'priority': 'LOW',
            'name': 'Major Updates',
            'packages': groups['major'],
            'strategy': 'individual',
            'testing': 'comprehensive'
        })
    
    return generate_batch_plan(batches)
```

### 9. フレームワーク固有のアップグレード

フレームワークアップグレードを処理:

**フレームワークアップグレードガイド**
```python
framework_upgrades = {
    'angular': {
        'upgrade_command': 'ng update',
        'pre_checks': [
            'ng update @angular/core@{version} --dry-run',
            'npm audit',
            'ng lint'
        ],
        'post_upgrade': [
            'ng update @angular/cli',
            'npm run test',
            'npm run e2e'
        ],
        'common_issues': {
            'ivy_renderer': 'Enable Ivy in tsconfig.json',
            'strict_mode': 'Update TypeScript configurations',
            'deprecated_apis': 'Use Angular migration schematics'
        }
    },
    'react': {
        'upgrade_command': 'npm install react@{version} react-dom@{version}',
        'codemods': [
            'npx react-codemod rename-unsafe-lifecycles',
            'npx react-codemod error-boundaries'
        ],
        'verification': [
            'npm run build',
            'npm test -- --coverage',
            'npm run analyze-bundle'
        ]
    },
    'vue': {
        'upgrade_command': 'npm install vue@{version}',
        'migration_tool': 'npx @vue/migration-tool',
        'breaking_changes': {
            '2_to_3': [
                'Composition API',
                'Multiple root elements',
                'Teleport component',
                'Fragments'
            ]
        }
    }
}
```

### 10. アップグレード後の監視

アップグレード後のアプリケーションを監視:

```javascript
// post-upgrade-monitoring.js
const monitoring = {
    metrics: {
        performance: {
            'page_load_time': { threshold: 3000, unit: 'ms' },
            'api_response_time': { threshold: 500, unit: 'ms' },
            'memory_usage': { threshold: 512, unit: 'MB' }
        },
        errors: {
            'error_rate': { threshold: 0.01, unit: '%' },
            'console_errors': { threshold: 0, unit: 'count' }
        },
        bundle: {
            'size': { threshold: 5, unit: 'MB' },
            'gzip_size': { threshold: 1.5, unit: 'MB' }
        }
    },
    
    checkHealth: async function() {
        const results = {};
        
        for (const [category, metrics] of Object.entries(this.metrics)) {
            results[category] = {};
            
            for (const [metric, config] of Object.entries(metrics)) {
                const value = await this.measureMetric(metric);
                results[category][metric] = {
                    value,
                    threshold: config.threshold,
                    unit: config.unit,
                    status: value <= config.threshold ? 'PASS' : 'FAIL'
                };
            }
        }
        
        return results;
    },
    
    generateReport: function(results) {
        let report = '## Post-Upgrade Health Check\n\n';
        
        for (const [category, metrics] of Object.entries(results)) {
            report += `### ${category}\n\n`;
            report += '| Metric | Value | Threshold | Status |\n';
            report += '|--------|-------|-----------|--------|\n';
            
            for (const [metric, data] of Object.entries(metrics)) {
                const status = data.status === 'PASS' ? '✅' : '❌';
                report += `| ${metric} | ${data.value}${data.unit} | ${data.threshold}${data.unit} | ${status} |\n`;
            }
            
            report += '\n';
        }
        
        return report;
    }
};
```

## 出力フォーマット

1. **アップグレード概要**: リスク評価を含む利用可能な更新の要約
2. **優先度マトリックス**: 重要性と安全性による更新の順序付けリスト
3. **移行ガイド**: 各主要アップグレードのステップバイステップガイド
4. **互換性レポート**: 依存関係互換性分析
5. **テスト戦略**: アップグレードを検証するための自動テスト
6. **ロールバック計画**: 必要に応じて元に戻すための明確な手順
7. **監視ダッシュボード**: アップグレード後の健全性メトリクス
8. **タイムライン**: アップグレード実装のための現実的なスケジュール

システムの安定性を維持しながら、依存関係を最新かつ安全に保つ安全で段階的なアップグレードに焦点を当ててください。