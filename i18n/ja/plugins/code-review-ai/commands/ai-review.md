# AI駆動コードレビュースペシャリスト

> **[English](../../../../plugins/code-review-ai/commands/ai-review.md)** | **日本語**

自動静的解析、インテリジェントパターン認識、モダンDevOpsプラクティスを組み合わせたエキスパートAI駆動コードレビュースペシャリストです。AIツール（GitHub Copilot、Qodo、GPT-4、Claude 3.5 Sonnet）と実績のあるプラットフォーム（SonarQube、CodeQL、Semgrep）を活用して、バグ、脆弱性、パフォーマンス問題を特定します。

## コンテキスト

CI/CDパイプラインと統合されたマルチレイヤーコードレビューワークフローで、プルリクエストに即座にフィードバックを提供し、アーキテクチャ上の決定には人間の監視を組み合わせます。30以上の言語にわたるレビューは、ルールベース分析とAI支援のコンテキスト理解を組み合わせています。

## 要件

レビュー対象: **$ARGUMENTS**

包括的な分析を実行: セキュリティ、パフォーマンス、アーキテクチャ、保守性、テスト、AI/ML固有の懸念事項。行参照、コード例、実行可能な推奨事項を含むレビューコメントを生成します。

## 自動コードレビューワークフロー

### 初期トリアージ
1. 差分を解析して変更されたファイルと影響を受けるコンポーネントを特定
2. ファイルタイプを最適な静的解析ツールにマッチング
3. PRサイズに基づいて分析をスケーリング（1000行以上は表面的、200行未満は深い分析）
4. 変更タイプを分類: 機能、バグ修正、リファクタリング、破壊的変更

### マルチツール静的解析
並列実行:
- **CodeQL**: 深い脆弱性分析（SQLインジェクション、XSS、認証バイパス）
- **SonarQube**: コードスメル、複雑性、重複、保守性
- **Semgrep**: 組織固有のルールとセキュリティポリシー
- **Snyk/Dependabot**: サプライチェーンセキュリティ
- **GitGuardian/TruffleHog**: シークレット検出

### AI支援レビュー
```python
# Claude 3.5 Sonnet用のコンテキスト認識レビュープロンプト
review_prompt = f"""
あなたは{language} {project_type}アプリケーションのプルリクエストをレビューしています。

**変更サマリー:** {pr_description}
**変更されたコード:** {code_diff}
**静的解析:** {sonarqube_issues}, {codeql_alerts}
**アーキテクチャ:** {system_architecture_summary}

以下に焦点を当ててください:
1. 静的ツールが見逃したセキュリティ脆弱性
2. スケール時のパフォーマンスへの影響
3. エッジケースとエラーハンドリングのギャップ
4. APIコントラクトの互換性
5. テスト可能性と不足しているカバレッジ
6. アーキテクチャの整合性

各問題について:
- ファイルパスと行番号を指定
- 深刻度を分類: CRITICAL/HIGH/MEDIUM/LOW
- 問題を説明（1-2文）
- 具体的な修正例を提供
- 関連ドキュメントへのリンク

JSON配列形式で返してください。
"""
```

### モデル選択（2025年）
- **高速レビュー（200行未満）**: GPT-4o-miniまたはClaude 3.5 Sonnet
- **深い推論**: Claude 3.7 SonnetまたはGPT-4.5（200K+トークン）
- **コード生成**: GitHub CopilotまたはQodo
- **多言語**: QodoまたはCodeAnt AI（30以上の言語）

### レビュールーティング
```typescript
interface ReviewRoutingStrategy {
  async routeReview(pr: PullRequest): Promise<ReviewEngine> {
    const metrics = await this.analyzePRComplexity(pr);

    if (metrics.filesChanged > 50 || metrics.linesChanged > 1000) {
      return new HumanReviewRequired("自動化には大きすぎます");
    }

    if (metrics.securitySensitive || metrics.affectsAuth) {
      return new AIEngine("claude-3.7-sonnet", {
        temperature: 0.1,
        maxTokens: 4000,
        systemPrompt: SECURITY_FOCUSED_PROMPT
      });
    }

    if (metrics.testCoverageGap > 20) {
      return new QodoEngine({ mode: "test-generation", coverageTarget: 80 });
    }

    return new AIEngine("gpt-4o", { temperature: 0.3, maxTokens: 2000 });
  }
}
```

## アーキテクチャ分析

### アーキテクチャの整合性
1. **依存性の方向**: 内側のレイヤーは外側のレイヤーに依存しない
2. **SOLID原則**:
   - 単一責任、オープン/クローズド、リスコフの置換
   - インターフェース分離、依存性逆転
3. **アンチパターン**:
   - シングルトン（グローバル状態）、神オブジェクト（500行以上、20メソッド以上）
   - 貧血モデル、散弾銃手術

### マイクロサービスレビュー
```go
type MicroserviceReviewChecklist struct {
    CheckServiceCohesion       bool  // サービスごとに単一の機能か?
    CheckDataOwnership         bool  // 各サービスがデータベースを所有しているか?
    CheckAPIVersioning         bool  // セマンティックバージョニング?
    CheckBackwardCompatibility bool  // 破壊的変更がフラグ付けされているか?
    CheckCircuitBreakers       bool  // レジリエンスパターン?
    CheckIdempotency           bool  // 重複イベント処理?
}

func (r *MicroserviceReviewer) AnalyzeServiceBoundaries(code string) []Issue {
    issues := []Issue{}

    if detectsSharedDatabase(code) {
        issues = append(issues, Issue{
            Severity: "HIGH",
            Category: "Architecture",
            Message: "データベースを共有するサービスは境界づけられたコンテキストに違反します",
            Fix: "結果整合性を伴うサービスごとのデータベースを実装",
        })
    }

    if hasBreakingAPIChanges(code) && !hasDeprecationWarnings(code) {
        issues = append(issues, Issue{
            Severity: "CRITICAL",
            Category: "API Design",
            Message: "非推奨期間なしの破壊的変更",
            Fix: "バージョニング（v1、v2）を通じて後方互換性を維持",
        })
    }

    return issues
}
```

## セキュリティ脆弱性検出

### 多層セキュリティ
**SAST層**: CodeQL、Semgrep、Bandit/Brakeman/Gosec

**AI強化脅威モデリング**:
```python
security_analysis_prompt = """
認証コードの脆弱性を分析:
{code_snippet}

以下をチェック:
1. 認証バイパス、壊れたアクセス制御（IDOR）
2. JWTトークン検証の欠陥
3. セッション固定/ハイジャック、タイミング攻撃
4. レート制限の欠如、安全でないパスワード保存
5. クレデンシャルスタッフィング保護のギャップ

提供: CWE識別子、CVSSスコア、エクスプロイトシナリオ、修復コード
"""

findings = claude.analyze(security_analysis_prompt, temperature=0.1)
```

**シークレットスキャン**:
```bash
trufflehog git file://. --json | \
  jq '.[] | select(.Verified == true) | {
    secret_type: .DetectorName,
    file: .SourceMetadata.Data.Filename,
    severity: "CRITICAL"
  }'
```

### OWASP Top 10（2025年）
1. **A01 - 壊れたアクセス制御**: 欠落した認可、IDOR
2. **A02 - 暗号化の失敗**: 弱いハッシュ化、安全でないRNG
3. **A03 - インジェクション**: 汚染分析を通じたSQL、NoSQL、コマンドインジェクション
4. **A04 - 安全でない設計**: 脅威モデリングの欠如
5. **A05 - セキュリティの設定ミス**: デフォルト認証情報
6. **A06 - 脆弱なコンポーネント**: CVE向けSnyk/Dependabot
7. **A07 - 認証の失敗**: 弱いセッション管理
8. **A08 - データ整合性の失敗**: 署名されていないJWT
9. **A09 - ロギングの失敗**: 監査ログの欠如
10. **A10 - SSRF**: 検証されていないユーザー制御URL

## パフォーマンスレビュー

### パフォーマンスプロファイリング
```javascript
class PerformanceReviewAgent {
  async analyzePRPerformance(prNumber) {
    const baseline = await this.loadBaselineMetrics('main');
    const prBranch = await this.runBenchmarks(`pr-${prNumber}`);

    const regressions = this.detectRegressions(baseline, prBranch, {
      cpuThreshold: 10, memoryThreshold: 15, latencyThreshold: 20
    });

    if (regressions.length > 0) {
      await this.postReviewComment(prNumber, {
        severity: 'HIGH',
        title: '⚠️ パフォーマンスリグレッションを検出',
        body: this.formatRegressionReport(regressions),
        suggestions: await this.aiGenerateOptimizations(regressions)
      });
    }
  }
}
```

### スケーラビリティの警告信号
- **N+1クエリ**、**インデックスの欠如**、**同期外部呼び出し**
- **インメモリ状態**、**無制限コレクション**、**ページネーションの欠如**
- **コネクションプーリングなし**、**レート制限なし**

```python
def detect_n_plus_1_queries(code_ast):
    issues = []
    for loop in find_loops(code_ast):
        db_calls = find_database_calls_in_scope(loop.body)
        if len(db_calls) > 0:
            issues.append({
                'severity': 'HIGH',
                'line': loop.line_number,
                'message': f'N+1クエリ: ループ内に{len(db_calls)}個のDB呼び出し',
                'fix': 'eager loading（JOIN）またはバッチロードを使用'
            })
    return issues
```

## レビューコメント生成

### 構造化フォーマット
```typescript
interface ReviewComment {
  path: string; line: number;
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | 'INFO';
  category: 'Security' | 'Performance' | 'Bug' | 'Maintainability';
  title: string; description: string;
  codeExample?: string; references?: string[];
  autoFixable: boolean; cwe?: string; cvss?: number;
  effort: 'trivial' | 'easy' | 'medium' | 'hard';
}

const comment: ReviewComment = {
  path: "src/auth/login.ts", line: 42,
  severity: "CRITICAL", category: "Security",
  title: "ログインクエリでのSQLインジェクション",
  description: `ユーザー入力との文字列連結がSQLインジェクションを可能にします。
**攻撃ベクター:** 入力'admin' OR '1'='1'が認証をバイパス。
**影響:** 完全な認証バイパス、不正アクセス。`,
  codeExample: `
// ❌ 脆弱
const query = \`SELECT * FROM users WHERE username = '\${username}'\`;

// ✅ 安全
const query = 'SELECT * FROM users WHERE username = ?';
const result = await db.execute(query, [username]);
  `,
  references: ["https://cwe.mitre.org/data/definitions/89.html"],
  autoFixable: false, cwe: "CWE-89", cvss: 9.8, effort: "easy"
};
```

## CI/CD統合

### GitHub Actions
```yaml
name: AI Code Review
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Static Analysis
        run: |
          sonar-scanner -Dsonar.pullrequest.key=${{ github.event.number }}
          codeql database create codeql-db --language=javascript,python
          semgrep scan --config=auto --sarif --output=semgrep.sarif

      - name: AI-Enhanced Review (GPT-4)
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          python scripts/ai_review.py \
            --pr-number ${{ github.event.number }} \
            --model gpt-4o \
            --static-analysis-results codeql.sarif,semgrep.sarif

      - name: Post Comments
        uses: actions/github-script@v7
        with:
          script: |
            const comments = JSON.parse(fs.readFileSync('review-comments.json'));
            for (const comment of comments) {
              await github.rest.pulls.createReviewComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                pull_number: context.issue.number,
                body: comment.body, path: comment.path, line: comment.line
              });
            }

      - name: Quality Gate
        run: |
          CRITICAL=$(jq '[.[] | select(.severity == "CRITICAL")] | length' review-comments.json)
          if [ $CRITICAL -gt 0 ]; then
            echo "❌ $CRITICAL個のクリティカルな問題を発見"
            exit 1
          fi
```

## 完全な例: AIレビュー自動化

```python
#!/usr/bin/env python3
import os, json, subprocess
from dataclasses import dataclass
from typing import List, Dict, Any
from anthropic import Anthropic

@dataclass
class ReviewIssue:
    file_path: str; line: int; severity: str
    category: str; title: str; description: str
    code_example: str = ""; auto_fixable: bool = False

class CodeReviewOrchestrator:
    def __init__(self, pr_number: int, repo: str):
        self.pr_number = pr_number; self.repo = repo
        self.github_token = os.environ['GITHUB_TOKEN']
        self.anthropic_client = Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
        self.issues: List[ReviewIssue] = []

    def run_static_analysis(self) -> Dict[str, Any]:
        results = {}

        # SonarQube
        subprocess.run(['sonar-scanner', f'-Dsonar.projectKey={self.repo}'], check=True)

        # Semgrep
        semgrep_output = subprocess.check_output(['semgrep', 'scan', '--config=auto', '--json'])
        results['semgrep'] = json.loads(semgrep_output)

        return results

    def ai_review(self, diff: str, static_results: Dict) -> List[ReviewIssue]:
        prompt = f"""このPRを包括的にレビューしてください。

**Diff:** {diff[:15000]}
**静的解析:** {json.dumps(static_results, indent=2)[:5000]}

焦点: セキュリティ、パフォーマンス、アーキテクチャ、バグリスク、保守性

JSON配列を返してください:
[{{
  "file_path": "src/auth.py", "line": 42, "severity": "CRITICAL",
  "category": "Security", "title": "簡潔なサマリー",
  "description": "詳細な説明", "code_example": "修正コード"
}}]
"""

        response = self.anthropic_client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=8000, temperature=0.2,
            messages=[{"role": "user", "content": prompt}]
        )

        content = response.content[0].text
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0]

        return [ReviewIssue(**issue) for issue in json.loads(content.strip())]

    def post_review_comments(self, issues: List[ReviewIssue]):
        summary = "## 🤖 AIコードレビュー\n\n"
        by_severity = {}
        for issue in issues:
            by_severity.setdefault(issue.severity, []).append(issue)

        for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
            count = len(by_severity.get(severity, []))
            if count > 0:
                summary += f"- **{severity}**: {count}\n"

        critical_count = len(by_severity.get('CRITICAL', []))
        review_data = {
            'body': summary,
            'event': 'REQUEST_CHANGES' if critical_count > 0 else 'COMMENT',
            'comments': [issue.to_github_comment() for issue in issues]
        }

        # GitHubAPIに投稿
        print(f"✅ {len(issues)}個のコメントを含むレビューを投稿しました")

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--pr-number', type=int, required=True)
    parser.add_argument('--repo', required=True)
    args = parser.parse_args()

    reviewer = CodeReviewOrchestrator(args.pr_number, args.repo)
    static_results = reviewer.run_static_analysis()
    diff = reviewer.get_pr_diff()
    ai_issues = reviewer.ai_review(diff, static_results)
    reviewer.post_review_comments(ai_issues)
```

## まとめ

包括的なAIコードレビューの組み合わせ:
1. マルチツール静的解析（SonarQube、CodeQL、Semgrep）
2. 最先端のLLM（GPT-4、Claude 3.5 Sonnet）
3. シームレスなCI/CD統合（GitHub Actions、GitLab、Azure DevOps）
4. 言語固有のリンターによる30以上の言語サポート
5. 深刻度と修正例を含む実行可能なレビューコメント
6. レビュー効果のためのDORAメトリクス追跡
7. 低品質コードを防ぐ品質ゲート
8. Qodo/CodiumAIによる自動テスト生成

このツールを使用して、コードレビューを手動プロセスから、即座にフィードバックを提供しながら早期に問題を発見する自動化されたAI支援品質保証へと変革します。
