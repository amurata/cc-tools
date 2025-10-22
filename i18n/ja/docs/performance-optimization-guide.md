# パフォーマンス最適化実装ガイド
**cc-tools リポジトリ - Claude Code プラグイン**
**Based on:** [パフォーマンス分析レポート](./performance-analysis-report.md) 2025-10-22

---

## クイックリファレンス

### 最適化インパクトマトリクス

| 最適化項目 | 優先度 | 工数 | トークン削減量 | サイズ削減量 | スケーラビリティ向上 |
|--------------|----------|--------|---------------|--------------|------------------|
| トークン重量コマンドの分割 | P1 | 中 | ~30K | ~120 KB | ⭐⭐ |
| エージェント重複排除 | P1 | 低 | ~69K | 271 KB | ⭐⭐⭐ |
| メタデータ精度の修正 | P1 | 容易 | 0 | 0 | ⭐ (信頼性) |
| プログレッシブスキル開示 | P2 | 中 | ~50K | 0 | ⭐⭐⭐ |
| コマンド重複排除 | P2 | 低 | ~33K | 128 KB | ⭐⭐ |
| サイズ予算の強制適用 | P2 | 低 | 0 | 肥大化防止 | ⭐⭐⭐⭐ |
| マーケットプレイス分割 | P3 | 高 | 0 | 0 | ⭐⭐⭐⭐⭐ |
| コンテンツキャッシング | P3 | 中 | 0 | 0 | ⭐⭐⭐ |
| 検索インデックス化 | P3 | 高 | 0 | 0 | ⭐⭐⭐⭐ |

---

## 優先度1: クリティカル最適化

### 1.1 トークン重量コマンドの分割

**対象ファイル:**
```
plugins/database-cloud-optimization/commands/cost-optimize.md (12,686 tokens)
plugins/api-testing-observability/commands/api-mock.md (10,879 tokens)
plugins/error-debugging/commands/error-trace.md (10,783 tokens)
plugins/error-diagnostics/commands/error-trace.md (10,783 tokens)
plugins/distributed-debugging/commands/debug-trace.md (10,229 tokens)
plugins/llm-application-dev/commands/ai-assistant.md (10,197 tokens)
```

**戦略: プログレッシブディスクロージャーパターン**

#### ステップ1: コマンド構造の分析

各コマンドについて以下を識別:
- コアワークフロー (必須)
- 例 (オプション)
- リファレンス資料 (オプション)
- 拡張ドキュメント (オプション)

#### ステップ2: 分割構造の作成

**`cost-optimize.md` の例:**

```
plugins/database-cloud-optimization/commands/
├── cost-optimize.md (3,000 tokens - メインワークフロー)
├── cost-optimize/
│   ├── examples.md (3,500 tokens)
│   ├── reference.md (3,000 tokens)
│   └── advanced.md (3,186 tokens)
```

**メインファイル (`cost-optimize.md`):**
```markdown
# コスト最適化コマンド

## 概要
[コア説明 - 200 tokens]

## ワークフロー
[必須ワークフローステップ - 2,500 tokens]

## 追加リソース
詳細な例については、[examples.md](./cost-optimize/examples.md)を参照
リファレンス資料については、[reference.md](./cost-optimize/reference.md)を参照
高度な使用法については、[advanced.md](./cost-optimize/advanced.md)を参照

## クイックスタート
[最小限のクイックスタートガイド - 300 tokens]
```

#### ステップ3: コマンド参照の更新

marketplace.jsonをメインファイルのみを指すように更新:
```json
{
  "commands": [
    "./commands/cost-optimize.md"
  ]
}
```

**検証:**
- メインファイルは 2,500-4,000 tokens である
- サポートファイルは参照されるが自動ロードされない
- ユーザーは必要時に詳細コンテンツにアクセス可能

**推定削減量:**
- 6コマンドを平均~10,500から~3,500へ削減
- 削減量: 7,000 tokens × 6 = 初期ロード時に~42,000 tokens削減
- 全コンテンツは別ファイルに保存

---

### 1.2 共有エージェントの重複排除

**重複エージェントインベントリ:**

| エージェント | 出現回数 | 使用プラグイン |
|-------|-------------|------------------|
| backend-architect.md | 6 | backend-development, backend-api-security, api-scaffolding, database-cloud-optimization, data-engineering, multi-platform-apps |
| code-reviewer.md | 6 | code-documentation, git-pr-workflows, code-refactoring, codebase-cleanup, full-stack-orchestration, api-scaffolding |
| test-automator.md | 4 | unit-testing, performance-testing-review, full-stack-orchestration, codebase-cleanup |
| debugger.md | 4 | debugging-toolkit, error-debugging, error-diagnostics, incident-response |
| ... | ... | ... |

#### 実装ステップ

**ステップ1: 共有ディレクトリの作成**

```bash
mkdir -p .claude-plugin/shared/agents
```

**ステップ2: 重複エージェントの移動**

```bash
# backend-architect.mdを移動
cp plugins/backend-development/agents/backend-architect.md \
   .claude-plugin/shared/agents/backend-architect.md

# 安定性のためにバージョン管理
cp .claude-plugin/shared/agents/backend-architect.md \
   .claude-plugin/shared/agents/backend-architect@v1.2.md
```

**ステップ3: マーケットプレイス参照の更新**

backend-architectを使用する全プラグインを更新:

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

**ステップ4: 重複の削除**

```bash
# 個別プラグインから削除
rm plugins/backend-api-security/agents/backend-architect.md
rm plugins/api-scaffolding/agents/backend-architect.md
# ... 6インスタンス全てに対して繰り返し
```

**ステップ5: バージョン管理の追加**

バージョンマニフェストを作成:

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

**自動化スクリプト:**

```python
# scripts/deduplicate-agents.py
import json
from pathlib import Path
from collections import defaultdict

def find_duplicate_agents():
    """全重複エージェントファイルを検出"""
    agents = defaultdict(list)

    for agent_file in Path('plugins').rglob('*/agents/*.md'):
        agent_name = agent_file.name
        agents[agent_name].append(agent_file)

    duplicates = {name: paths for name, paths in agents.items() if len(paths) > 1}
    return duplicates

def deduplicate_agent(agent_name, paths):
    """エージェントを共有ディレクトリに移動し参照を更新"""
    # 1. 共有に複製
    shared_path = Path('.claude-plugin/shared/agents') / agent_name
    shared_path.parent.mkdir(parents=True, exist_ok=True)

    # 最初の出現を正規バージョンとして使用
    canonical = paths[0]
    shared_path.write_text(canonical.read_text())

    # 2. marketplace.json参照を更新
    marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

    for plugin in marketplace['plugins']:
        plugin_name = plugin['name']
        plugin_agents = plugin.get('agents', [])

        # このプラグインが重複エージェントを使用しているか確認
        for i, agent_path in enumerate(plugin_agents):
            if agent_name in agent_path:
                # 共有参照に更新
                relative_path = f"../../../.claude-plugin/shared/agents/{agent_name}"
                plugin_agents[i] = relative_path

    # 3. 更新されたマーケットプレイスを保存
    Path('.claude-plugin/marketplace.json').write_text(
        json.dumps(marketplace, indent=2)
    )

    # 4. 重複を削除
    for path in paths:
        path.unlink()

    print(f"✓ {agent_name}の重複排除完了: {len(paths)} → 1 shared")

if __name__ == '__main__':
    duplicates = find_duplicate_agents()
    for agent_name, paths in duplicates.items():
        deduplicate_agent(agent_name, paths)

    print(f"\n総削減量: {sum(len(p)-1 for p in duplicates.values())} ファイル")
```

**期待される結果:**
- 30エージェント: 87ファイル → 87 - 59 = 28ユニークファイル + 30共有 = 58総ファイル
- 削減量: 271 KB, ~69,414 tokens
- メンテナンス: 共有エージェントの単一真実源

---

### 1.3 メタデータ精度の修正

**現在の不整合:**
```json
// .claude-plugin/marketplace.json (line 9)
"description": "... 87 specialized agents ..."
// 実際: 146 agents
```

**修正:**

```json
{
  "metadata": {
    "description": "64個の焦点を絞ったプラグイン、146個の専門エージェント、50個のスキル、70個のコマンドによる本番対応ワークフロー編成 - 細分化されたインストールと最小トークン使用に最適化",
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

**検証スクリプト:**

```python
# scripts/validate-metadata.py
import json
from pathlib import Path

marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

# コンポーネントをカウント
plugin_count = len(marketplace['plugins'])
agent_count = sum(len(p.get('agents', [])) for p in marketplace['plugins'])
skill_count = sum(len(p.get('skills', [])) for p in marketplace['plugins'])
command_count = sum(len(p.get('commands', [])) for p in marketplace['plugins'])

# ユニークエージェントをカウント
all_agents = [a.split('/')[-1] for p in marketplace['plugins'] for a in p.get('agents', [])]
unique_agents = len(set(all_agents))

print(f"実際のカウント:")
print(f"  プラグイン: {plugin_count}")
print(f"  エージェント: {agent_count} ({unique_agents} ユニーク)")
print(f"  スキル: {skill_count}")
print(f"  コマンド: {command_count}")

# メタデータと検証
claimed_agents = 87  # 現在の説明から
if agent_count != claimed_agents:
    print(f"\n⚠️  不整合: 主張 {claimed_agents}, 実際 {agent_count}")
```

---

## 優先度2: 高インパクト最適化

### 2.1 スキルのプログレッシブディスクロージャー

**現在の状態:**
- スキルはSKILL.mdファイルを持つディレクトリ
- 平均スキル: 11.9 KB (~3,057 tokens)
- 最大: 25.4 KB (~6,514 tokens)

**目標状態:**
- スキルはメタデータ + サマリー (500 tokens)
- 完全コンテンツはアクティブ化時のみロード

**実装:**

#### ステップ1: スキルメタデータの追加

スキルマニフェストを作成:

```json
// plugins/javascript-typescript/skills/javascript-testing-patterns/skill.json
{
  "name": "javascript-testing-patterns",
  "version": "1.0.0",
  "summary": "Jest、Vitest、Testing Libraryを使用したユニットテスト、統合テスト、E2Eテストのための包括的テスト戦略。モッキング、フィクスチャ、テスト駆動開発を含む。",
  "preview": {
    "description": "モダンフレームワークとベストプラクティスでJavaScript/TypeScriptテストをマスター",
    "use_cases": [
      "Jest/Vitestによるユニットテスト",
      "統合テストパターン",
      "Testing LibraryによるE2Eテスト",
      "モッキング戦略",
      "テスト駆動開発"
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

#### ステップ2: スキルサマリーの作成

**SUMMARY.md (最大500 tokens):**
```markdown
# JavaScript テストパターン

## 概要
モダンフレームワークを使用したJavaScript/TypeScriptアプリケーションのための包括的テスト戦略。

## 主要機能
- JestとVitestによるユニットテスト
- 統合テストとE2Eテスト
- モッキングとフィクスチャパターン
- テスト駆動開発ワークフロー

## 使用タイミング
- 新規テストインフラ構築時
- テストカバレッジと品質の改善
- TDD/BDDワークフローの実装
- テストフレームワーク間の移行

## クイックサンプル
[最小限の10行例]

完全なコンテンツについては、このスキルをアクティブ化してください。
```

#### ステップ3: マーケットプレイスの更新

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

**自動化:**

```python
# scripts/generate-skill-summaries.py
from pathlib import Path

def generate_skill_summary(skill_dir: Path):
    """完全なSKILL.mdからサマリーを生成"""
    skill_md = skill_dir / 'SKILL.md'
    content = skill_md.read_text()

    # 最初の500 tokensを抽出 (おおよそ最初の2000文字)
    summary = content[:2000]

    # アクションコールを追加
    summary += "\n\n---\n**完全なコンテンツについては、このスキルをアクティブ化してください。**\n"

    # サマリーを書き込み
    (skill_dir / 'SUMMARY.md').write_text(summary)

    print(f"✓ {skill_dir.name}のサマリーを生成")

for skill_dir in Path('plugins').rglob('*/skills/*'):
    if skill_dir.is_dir() and (skill_dir / 'SKILL.md').exists():
        generate_skill_summary(skill_dir)
```

**期待される削減量:**
- 50スキル × 平均3,057 tokens = 152,850 tokens
- プレビューのみ: 50 × 500 tokens = 25,000 tokens
- スキル非アクティブ時の削減量: 127,850 tokens (83%削減)

---

### 2.2 コマンドの重複排除

**重複コマンド:**

| コマンド | 出現回数 | 各サイズ | 総無駄 |
|---------|-------------|-----------|-------------|
| error-trace.md | 2 | 42 KB | 42 KB |
| error-analysis.md | 2 | 35 KB | 35 KB |
| refactor-clean.md | 2 | 24 KB | 24 KB |
| deps-audit.md | 2 | 28 KB | 28 KB |

**戦略: テンプレートパラメータ化**

#### 例: error-trace.md

**共有テンプレート:**
```markdown
// .claude-plugin/shared/commands/error-trace-template.md

# エラートレースコマンド

## 設定
<!-- プラグイン固有の設定を error-trace.config.json からロード -->

## コアワークフロー
[共通ワークフロー - コンテンツの80%]

## プラグイン固有の動作
<!-- プラグインの error-trace-plugin.md からロード -->

## 例
<!-- examples/ ディレクトリからロード -->
```

**プラグイン固有の設定:**
```json
// plugins/error-debugging/commands/error-trace.config.json
{
  "plugin_name": "error-debugging",
  "focus": "開発時デバッグ",
  "additional_context": "./error-trace-plugin.md",
  "examples": ["./examples/nodejs-error.md", "./examples/browser-error.md"]
}
```

**プラグイン固有コンテンツ (小サイズ):**
```markdown
// plugins/error-debugging/commands/error-trace-plugin.md (5 KB)

## 開発時デバッグフォーカス
[プラグイン固有の追加内容]
```

**マーケットプレイス参照:**
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

**期待される削減量:**
- 4コマンドペア: 総132 KB無駄
- テンプレート化後: 4 × 5 KB = 20 KBプラグイン固有コンテンツ
- 削減量: 112 KB (~28,000 tokens)

---

### 2.3 プラグインサイズ予算の強制適用

**目標:** 将来の肥大化防止、一貫したパフォーマンス維持

**予算定義:**

```yaml
# .claude-plugin/size-budgets.yml
plugin_limits:
  # トークン制限
  max_total_tokens: 15000
  max_single_file_tokens: 8000
  warn_at_tokens: 10000

  # コンポーネント制限
  max_components: 6
  max_agents: 4
  max_skills: 4
  max_commands: 3

  # ファイルサイズ制限
  max_file_size_kb: 30
  warn_at_file_size_kb: 20

  # 全体制限
  max_plugin_size_mb: 0.5

  # 例外 (制限超過許可プラグイン)
  exceptions:
    - observability-monitoring  # 10 components
    - cloud-infrastructure      # 10 components
    - cicd-automation           # 10 components
```

**検証スクリプト:**

```python
# scripts/validate-plugin-sizes.py
import yaml
from pathlib import Path

budgets = yaml.safe_load(Path('.claude-plugin/size-budgets.yml').read_text())

def check_plugin_size(plugin_dir: Path):
    """プラグインをサイズ予算に対して検証"""
    plugin_name = plugin_dir.name

    # 例外をスキップ
    if plugin_name in budgets['plugin_limits']['exceptions']:
        print(f"⏭️  {plugin_name}: 例外許可")
        return True

    # コンポーネントをカウント
    agents = len(list(plugin_dir.glob('agents/*.md')))
    skills = len(list(plugin_dir.glob('skills/*')))
    commands = len(list(plugin_dir.glob('commands/*.md')))
    total_components = agents + skills + commands

    # トークンを計算 (概算: ファイルサイズ / 4)
    total_size = sum(f.stat().st_size for f in plugin_dir.rglob('*.md'))
    total_tokens = total_size // 4

    # 制限をチェック
    violations = []

    if total_tokens > budgets['plugin_limits']['max_total_tokens']:
        violations.append(f"総トークン数 {total_tokens} が制限 {budgets['plugin_limits']['max_total_tokens']} を超過")

    if total_components > budgets['plugin_limits']['max_components']:
        violations.append(f"総コンポーネント数 {total_components} が制限 {budgets['plugin_limits']['max_components']} を超過")

    # 個別ファイルサイズをチェック
    for md_file in plugin_dir.rglob('*.md'):
        file_tokens = md_file.stat().st_size // 4
        if file_tokens > budgets['plugin_limits']['max_single_file_tokens']:
            violations.append(f"{md_file.name}: {file_tokens} tokens が {budgets['plugin_limits']['max_single_file_tokens']} を超過")

    # レポート
    if violations:
        print(f"❌ {plugin_name}: 失敗")
        for v in violations:
            print(f"   - {v}")
        return False
    else:
        print(f"✓ {plugin_name}: OK ({total_tokens} tokens, {total_components} components)")
        return True

# 全プラグインをチェック
all_pass = True
for plugin_dir in sorted(Path('plugins').iterdir()):
    if plugin_dir.is_dir():
        if not check_plugin_size(plugin_dir):
            all_pass = False

exit(0 if all_pass else 1)
```

**CI統合 (GitHub Actions):**

```yaml
# .github/workflows/validate-sizes.yml
name: プラグインサイズ検証

on: [pull_request, push]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: 依存関係インストール
        run: pip install pyyaml
      - name: プラグインサイズ検証
        run: python scripts/validate-plugin-sizes.py
```

---

## 優先度3: 長期スケーラビリティ

### 3.1 Marketplace.jsonの分割 (200+プラグイン向け)

**トリガー:** 150プラグイン到達時
**現在:** 1,956行, 56.6 KB (64プラグイン)
**200時の予測:** 6,112行, 176.9 KB

**目標アーキテクチャ:**

```
.claude-plugin/
├── index.json (メインレジストリ, 5-10 KB)
├── categories.json (カテゴリインデックス)
├── plugins/
│   ├── backend-development.json
│   ├── frontend-development.json
│   ├── database-design.json
│   └── ... (64+個別ファイル)
└── cache/
    └── full-marketplace.json (生成物, gitignore)
```

**実装:**

#### ステップ1: プラグインマニフェストスキーマの作成

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

#### ステップ2: レジストリインデックスの作成

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
    // ... 軽量参照のみ
  ],
  "categories": "./categories.json"
}
```

#### ステップ3: マイグレーションスクリプト

```python
# scripts/migrate-to-split-marketplace.py
import json
from pathlib import Path

def split_marketplace():
    """モノリシックmarketplace.jsonを個別プラグインマニフェストに分割"""

    # 現在のmarketplaceをロード
    marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

    # pluginsディレクトリを作成
    plugins_dir = Path('.claude-plugin/plugins')
    plugins_dir.mkdir(exist_ok=True)

    # インデックスを作成
    index = {
        'name': marketplace['name'],
        'version': marketplace['metadata']['version'],
        'registry_version': '2.0',
        'metadata': marketplace['metadata'],
        'plugins': []
    }

    # 各プラグインを分割
    for plugin in marketplace['plugins']:
        plugin_name = plugin['name']

        # 個別マニフェストを書き込み
        manifest_path = plugins_dir / f"{plugin_name}.json"
        manifest_path.write_text(json.dumps(plugin, indent=2))

        # インデックスに追加 (軽量参照)
        index['plugins'].append({
            'name': plugin_name,
            'manifest': f"./plugins/{plugin_name}.json",
            'category': plugin.get('category'),
            'version': plugin.get('version')
        })

    # インデックスを書き込み
    Path('.claude-plugin/index.json').write_text(json.dumps(index, indent=2))

    # オリジナルをバックアップ
    Path('.claude-plugin/marketplace.json.backup').write_text(
        Path('.claude-plugin/marketplace.json').read_text()
    )

    print(f"✓ {len(marketplace['plugins'])}個のプラグインを分割")
    print(f"  インデックス: {Path('.claude-plugin/index.json').stat().st_size / 1024:.1f} KB")
    print(f"  平均マニフェスト: {sum(p.stat().st_size for p in plugins_dir.glob('*.json')) / len(list(plugins_dir.glob('*.json'))) / 1024:.1f} KB")

split_marketplace()
```

**パフォーマンス改善:**

| 指標 | モノリシック (200プラグイン) | 分割アーキテクチャ |
|--------|-------------------------|-------------------|
| 初期ロード | 177 KB (全ファイル) | 10 KB (インデックスのみ) |
| プラグイン検索 | 全ファイルをパース | 単一マニフェスト読込 (0.9 KB) |
| 並行アクセス | 全ファイルをロック | 単一マニフェストをロック |
| Git競合 | 高リスク | 最小リスク |

---

### 3.2 コンテンツキャッシング

**実装:**

```python
# .claude-plugin/cache/plugin-cache.py
from pathlib import Path
import json
import hashlib
import time

class PluginCache:
    """ファイル監視による無効化を持つプラグインコンテンツのインメモリキャッシュ"""

    def __init__(self, cache_dir: Path = Path('.claude-plugin/cache')):
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(exist_ok=True)
        self.cache = {}
        self.file_hashes = {}

    def get_plugin_manifest(self, plugin_name: str):
        """キャッシュされたプラグインマニフェストを取得またはディスクからロード"""
        manifest_path = Path(f'.claude-plugin/plugins/{plugin_name}.json')

        # ファイルハッシュを計算
        file_hash = self._hash_file(manifest_path)

        # キャッシュをチェック
        if plugin_name in self.cache and self.file_hashes.get(plugin_name) == file_hash:
            return self.cache[plugin_name]

        # ディスクからロード
        manifest = json.loads(manifest_path.read_text())

        # キャッシュを更新
        self.cache[plugin_name] = manifest
        self.file_hashes[plugin_name] = file_hash

        return manifest

    def get_agent_content(self, agent_path: Path):
        """キャッシュされたエージェントコンテンツを取得"""
        cache_key = str(agent_path)
        file_hash = self._hash_file(agent_path)

        if cache_key in self.cache and self.file_hashes.get(cache_key) == file_hash:
            return self.cache[cache_key]

        content = agent_path.read_text()
        self.cache[cache_key] = content
        self.file_hashes[cache_key] = file_hash

        return content

    def _hash_file(self, path: Path) -> str:
        """キャッシュ無効化のためのファイルハッシュを計算"""
        stat = path.stat()
        return hashlib.md5(f"{stat.st_mtime}:{stat.st_size}".encode()).hexdigest()

    def invalidate(self, path: Path = None):
        """特定ファイルまたは全キャッシュを無効化"""
        if path:
            cache_key = str(path)
            self.cache.pop(cache_key, None)
            self.file_hashes.pop(cache_key, None)
        else:
            self.cache.clear()
            self.file_hashes.clear()
```

---

### 3.3 検索インデックス化

**実装:**

```python
# .claude-plugin/search/index.py
from pathlib import Path
import json
from collections import defaultdict

class PluginSearchIndex:
    """高速プラグイン/エージェント/スキル発見のためのインデックス検索"""

    def __init__(self):
        self.category_index = defaultdict(list)
        self.keyword_index = defaultdict(list)
        self.agent_index = defaultdict(list)
        self.skill_index = defaultdict(list)

    def build_index(self):
        """プラグインマニフェストから検索インデックスを構築"""
        index_data = Path('.claude-plugin/index.json')
        index = json.loads(index_data.read_text())

        for plugin_ref in index['plugins']:
            plugin_name = plugin_ref['name']
            manifest_path = Path('.claude-plugin') / plugin_ref['manifest']
            plugin = json.loads(manifest_path.read_text())

            # カテゴリでインデックス
            category = plugin.get('category', 'other')
            self.category_index[category].append(plugin_name)

            # キーワードでインデックス
            for keyword in plugin.get('keywords', []):
                self.keyword_index[keyword.lower()].append(plugin_name)

            # エージェントでインデックス
            for agent_path in plugin.get('agents', []):
                agent_name = agent_path.split('/')[-1].replace('.md', '')
                self.agent_index[agent_name].append(plugin_name)

            # スキルでインデックス
            for skill_path in plugin.get('skills', []):
                skill_name = skill_path.split('/')[-1]
                self.skill_index[skill_name].append(plugin_name)

    def search_by_category(self, category: str) -> list:
        """O(1) カテゴリ検索"""
        return self.category_index.get(category, [])

    def search_by_keyword(self, keyword: str) -> list:
        """O(1) キーワード検索"""
        return self.keyword_index.get(keyword.lower(), [])

    def search_by_agent(self, agent_name: str) -> list:
        """O(1) エージェント検索"""
        return self.agent_index.get(agent_name, [])

    def fuzzy_search(self, query: str) -> list:
        """全インデックスを横断したファジー検索"""
        query_lower = query.lower()
        results = set()

        # キーワードを検索
        for keyword, plugins in self.keyword_index.items():
            if query_lower in keyword:
                results.update(plugins)

        # エージェント名を検索
        for agent, plugins in self.agent_index.items():
            if query_lower in agent.lower():
                results.update(plugins)

        return list(results)

    def save_index(self, path: Path = Path('.claude-plugin/cache/search-index.json')):
        """高速起動のためインデックスをディスクに永続化"""
        index_data = {
            'category': dict(self.category_index),
            'keyword': dict(self.keyword_index),
            'agent': dict(self.agent_index),
            'skill': dict(self.skill_index)
        }
        path.write_text(json.dumps(index_data, indent=2))
```

**使用法:**

```python
# 高速プラグイン発見
index = PluginSearchIndex()
index.build_index()
index.save_index()

# O(1) 検索
backend_plugins = index.search_by_category('development')
api_plugins = index.search_by_keyword('api')
plugins_with_backend_architect = index.search_by_agent('backend-architect')

# ファジー検索
testing_plugins = index.fuzzy_search('test')
```

---

## 実装タイムライン

### スプリント1 (第1-2週): 優先度1 クリティカル修正

**目標:**
- 6個のトークン重量コマンドを分割
- 共有エージェントの重複排除
- メタデータ精度の修正

**成果物:**
- 6コマンドを各3K tokensに削減
- `.claude-plugin/shared/agents/`に30個の共有エージェント
- 正確なマーケットプレイスメタデータ
- 検証スクリプト

**成功指標:**
- 10K tokens超のコマンドが0個
- エージェント重複排除による271 KB削減
- メタデータが実際のカウントと一致

### スプリント2 (第3-4週): 優先度2 高インパクト

**目標:**
- プログレッシブスキルディスクロージャーの実装
- コマンドテンプレートの重複排除
- サイズ予算の強制適用

**成果物:**
- 50個のスキルサマリー生成
- コマンドテンプレートシステム
- サイズ予算CI検証

**成功指標:**
- 127K tokens削減 (スキルプレビュー)
- 128 KBコマンド重複排除削減
- 全プラグインがサイズ検証合格

### スプリント3 (第2-3ヶ月): 優先度3 長期

**目標:**
- マーケットプレイス分割アーキテクチャ
- キャッシングの実装
- 検索インデックスの構築

**成果物:**
- 分割レジストリシステム
- プラグインコンテンツキャッシュ
- 検索インデックスシステム

**成功指標:**
- 10 KBインデックスファイル (vs 57 KBモノリス)
- O(1)検索パフォーマンス
- 200+プラグイン対応準備完了

---

## モニタリング & 検証

### 自動化チェック

```yaml
# .github/workflows/performance-validation.yml
name: パフォーマンス検証

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: プラグインサイズ検証
        run: python scripts/validate-plugin-sizes.py

      - name: 重複チェック
        run: python scripts/check-duplicates.py

      - name: メタデータ検証
        run: python scripts/validate-metadata.py

      - name: パフォーマンスレポート
        run: python scripts/performance-report.py
```

### パフォーマンスダッシュボード

主要指標を追跡:

```python
# scripts/performance-report.py
def generate_performance_report():
    """パフォーマンス指標レポートを生成"""

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

    # ターゲットと比較
    targets = {
        'duplication_rate': 0.05,  # <5%
        'avg_plugin_tokens': 12000,
        'token_heavy_commands': 0,
        'marketplace_size_kb': 100
    }

    print("パフォーマンスレポート")
    print("=" * 50)
    for metric, value in metrics.items():
        target = targets.get(metric)
        status = "✓" if target and value <= target else "⚠️"
        print(f"{status} {metric}: {value}")
```

---

## 成功基準

### フェーズ1完了時:
- ✅ 10K tokens超のコマンドがゼロ
- ✅ 30個の共有エージェント全て重複排除済み
- ✅ メタデータ精度100%
- ✅ CIでサイズ検証実施

### フェーズ2完了時:
- ✅ 全スキルにサマリーあり
- ✅ コマンド重複が5%未満
- ✅ サイズ予算が強制適用
- ✅ トークン削減量>15%

### フェーズ3完了時:
- ✅ 分割アーキテクチャ導入
- ✅ 検索インデックス稼働
- ✅ キャッシングシステム稼働
- ✅ 200+プラグイン対応準備完了

---

## 付録: パフォーマンステスト

### 負荷テストスクリプト

```python
# scripts/performance-test.py
import time
import json
from pathlib import Path

def benchmark_marketplace_parse():
    """marketplace.jsonパース性能をベンチマーク"""
    path = Path('.claude-plugin/marketplace.json')

    times = []
    for _ in range(100):
        start = time.perf_counter()
        data = json.loads(path.read_text())
        times.append(time.perf_counter() - start)

    print(f"パース時間: {sum(times)/len(times)*1000:.2f}ms (100回実行の平均)")
    print(f"最小: {min(times)*1000:.2f}ms, 最大: {max(times)*1000:.2f}ms")

def benchmark_plugin_search():
    """プラグイン検索性能をベンチマーク"""
    marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())

    start = time.perf_counter()
    results = [p for p in marketplace['plugins'] if 'backend' in p['name']]
    elapsed = time.perf_counter() - start

    print(f"検索時間: {elapsed*1000:.2f}ms ({len(results)}件マッチ)")

benchmark_marketplace_parse()
benchmark_plugin_search()
```

---

## 関連ドキュメント

- [包括的コードレビューレポート](./comprehensive-review-report.md) - 全体的な品質評価
- [パフォーマンス分析レポート](./performance-analysis-report.md) - 詳細なパフォーマンス測定とスケーラビリティ評価

---

**最適化ガイド終了**
