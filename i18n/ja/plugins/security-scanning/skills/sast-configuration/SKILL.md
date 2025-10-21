> **[English](../../../../../plugins/security-scanning/skills/sast-configuration/SKILL.md)** | **日本語**

---
name: sast-configuration
description: アプリケーションコードでの自動脆弱性検出のための静的アプリケーションセキュリティテスト（SAST）ツールを設定します。セキュリティスキャンの設定、DevSecOps実践の実装、またはコード脆弱性検出の自動化時に使用してください。
---

# SAST設定

複数のプログラミング言語にわたる包括的なセキュリティスキャンのための静的アプリケーションセキュリティテスト（SAST）ツールのセットアップ、設定、カスタムルール作成。

## 概要

このスキルは、Semgrep、SonarQube、CodeQLを含むSASTツールのセットアップと設定に関する包括的なガイダンスを提供します。次のような場合に使用します:

- CI/CDパイプラインでのSASTスキャンのセットアップ
- コードベースのカスタムセキュリティルール作成
- 品質ゲートとコンプライアンスポリシーの設定
- スキャンパフォーマンスの最適化と誤検知の削減
- 多層防御のための複数SASTツールの統合

## コア機能

### 1. Semgrep設定
- パターンマッチングを使用したカスタムルール作成
- 言語固有のセキュリティルール（Python、JavaScript、Go、Javaなど）
- CI/CD統合（GitHub Actions、GitLab CI、Jenkins）
- 誤検知調整とルール最適化
- 組織ポリシー実施

### 2. SonarQubeセットアップ
- 品質ゲート設定
- セキュリティホットスポット分析
- コードカバレッジと技術的負債追跡
- 言語のカスタム品質プロファイル
- LDAP/SAMLによるエンタープライズ統合

### 3. CodeQL分析
- GitHub Advanced Security統合
- カスタムクエリ開発
- 脆弱性バリアント分析
- セキュリティ研究ワークフロー
- SARIF結果処理

## クイックスタート

### 初期評価
1. コードベースの主要プログラミング言語を特定
2. コンプライアンス要件を決定（PCI-DSS、SOC 2など）
3. 言語サポートと統合ニーズに基づいてSASTツールを選択
4. ベースラインスキャンをレビューして現在のセキュリティ体制を把握

### 基本セットアップ
```bash
# Semgrepクイックスタート
pip install semgrep
semgrep --config=auto --error

# DockerでSonarQube
docker run -d --name sonarqube -p 9000:9000 sonarqube:latest

# CodeQL CLIセットアップ
gh extension install github/gh-codeql
codeql database create mydb --language=python
```

## リファレンスドキュメント

- [Semgrepルール作成](references/semgrep-rules.md) - パターンベースセキュリティルール開発
- [SonarQube設定](references/sonarqube-config.md) - 品質ゲートとプロファイル
- [CodeQLセットアップガイド](references/codeql-setup.md) - クエリ開発とワークフロー

## テンプレートとアセット

- [semgrep-config.yml](assets/semgrep-config.yml) - 本番環境対応Semgrep設定
- [sonarqube-settings.xml](assets/sonarqube-settings.xml) - SonarQube品質プロファイルテンプレート
- [run-sast.sh](scripts/run-sast.sh) - 自動SAST実行スクリプト

## 統合パターン

### CI/CDパイプライン統合
```yaml
# GitHub Actionsの例
- name: Run Semgrep
  uses: returntocorp/semgrep-action@v1
  with:
    config: >-
      p/security-audit
      p/owasp-top-ten
```

### プレコミットフック
```bash
# .pre-commit-config.yaml
- repo: https://github.com/returntocorp/semgrep
  rev: v1.45.0
  hooks:
    - id: semgrep
      args: ['--config=auto', '--error']
```

## ベストプラクティス

1. **ベースラインから開始**
   - 初回スキャンを実行してセキュリティベースラインを確立
   - クリティカルおよび高深刻度の発見を優先
   - 修復ロードマップを作成

2. **段階的導入**
   - セキュリティ重視のルールから開始
   - 徐々にコード品質ルールを追加
   - クリティカル問題のみにブロッキングを実装

3. **誤検知管理**
   - 正当な抑制を文書化
   - 既知の安全なパターンの許可リストを作成
   - 抑制された発見を定期的にレビュー

4. **パフォーマンス最適化**
   - テストファイルと生成コードを除外
   - 大規模コードベースには増分スキャンを使用
   - CI/CDでスキャン結果をキャッシュ

5. **チーム支援**
   - 開発者向けセキュリティトレーニングを提供
   - 一般的なパターンの内部ドキュメントを作成
   - セキュリティチャンピオンプログラムを確立

## 一般的な使用例

### 新規プロジェクトセットアップ
```bash
./scripts/run-sast.sh --setup --language python --tools semgrep,sonarqube
```

### カスタムルール開発
```yaml
# 詳細な例はreferences/semgrep-rules.mdを参照
rules:
  - id: hardcoded-jwt-secret
    pattern: jwt.encode($DATA, "...", ...)
    message: JWTシークレットはハードコードすべきではありません
    severity: ERROR
```

### コンプライアンススキャン
```bash
# PCI-DSS重視スキャン
semgrep --config p/pci-dss --json -o pci-scan-results.json
```

## トラブルシューティング

### 高い誤検知率
- ルールの感度をレビューして調整
- テストファイル除外のパスフィルタを追加
- ノイジーパターンにはnostmtメタデータを使用
- 組織固有のルール例外を作成

### パフォーマンス問題
- 増分スキャンを有効化
- モジュール間でスキャンを並列化
- 効率のためのルールパターンを最適化
- 依存関係とスキャン結果をキャッシュ

### 統合失敗
- APIトークンと認証情報を確認
- ネットワーク接続とプロキシ設定をチェック
- SARIF出力フォーマット互換性をレビュー
- CI/CDランナー権限を検証

## 関連スキル

- [OWASP Top 10チェックリスト](../owasp-top10-checklist/SKILL.md)
- [コンテナセキュリティ](../container-security/SKILL.md)
- [依存関係スキャン](../dependency-scanning/SKILL.md)

## ツール比較

| ツール | 最適用途 | 言語サポート | コスト | 統合 |
|------|----------|------------------|------|-------------|
| Semgrep | カスタムルール、高速スキャン | 30以上の言語 | 無料/エンタープライズ | 優秀 |
| SonarQube | コード品質+セキュリティ | 25以上の言語 | 無料/商用 | 良好 |
| CodeQL | 深い分析、研究 | 10以上の言語 | 無料（OSS） | GitHubネイティブ |

## 次のステップ

1. 初期SASTツールセットアップを完了
2. ベースラインセキュリティスキャンを実行
3. 組織固有のパターンのカスタムルールを作成
4. CI/CDパイプラインに統合
5. セキュリティゲートポリシーを確立
6. 発見と修復について開発チームをトレーニング
