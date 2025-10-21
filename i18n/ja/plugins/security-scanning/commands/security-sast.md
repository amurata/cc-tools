> **[English](../../../plugins/security-scanning/commands/security-sast.md)** | **日本語**

---
description: 複数の言語とフレームワークにわたるコード脆弱性分析のための静的アプリケーションセキュリティテスト（SAST）
globs: ['**/*.py', '**/*.js', '**/*.ts', '**/*.java', '**/*.rb', '**/*.go', '**/*.rs', '**/*.php']
keywords: [sast, 静的分析, コードセキュリティ, 脆弱性スキャン, bandit, semgrep, eslint, sonarqube, codeql, セキュリティパターン, コードレビュー, AST分析]
---

# SASTセキュリティプラグイン

複数の言語、フレームワーク、セキュリティパターンにわたる包括的なコード脆弱性検出のための静的アプリケーションセキュリティテスト（SAST）。

## 能力

- **多言語SAST**: Python、JavaScript/TypeScript、Java、Ruby、PHP、Go、Rust
- **ツール統合**: Bandit、Semgrep、ESLint Security、SonarQube、CodeQL、PMD、SpotBugs、Brakeman、gosec、cargo-clippy
- **脆弱性パターン**: SQLインジェクション、XSS、ハードコードされたシークレット、パストラバーサル、IDOR、CSRF、安全でない逆シリアル化
- **フレームワーク分析**: Django、Flask、React、Express、Spring Boot、Rails、Laravel
- **カスタムルール作成**: 組織固有のセキュリティポリシーのためのSemgrepパターン開発

## このツールを使用する場合

コードレビューセキュリティ分析、インジェクション脆弱性、ハードコードされたシークレット、フレームワーク固有パターン、カスタムセキュリティポリシー実施、デプロイ前検証、レガシーコード評価、コンプライアンス（OWASP、PCI-DSS、SOC2）に使用します。

**専門ツール**: 高度な認証情報スキャンには`security-secrets.md`、Top 10マッピングには`security-owasp.md`、REST/GraphQLエンドポイントには`security-api.md`を使用してください。

## SASTツール選択

### Python: Bandit

```bash
# インストールとスキャン
pip install bandit
bandit -r . -f json -o bandit-report.json
bandit -r . -ll -ii -f json  # 高/クリティカルのみ
```

**設定**: `.bandit`
```yaml
exclude_dirs: ['/tests/', '/venv/', '/.tox/', '/build/']
tests: [B201, B301, B302, B303, B304, B305, B307, B308, B312, B323, B324, B501, B502, B506, B602, B608]
skips: [B101]
```

### JavaScript/TypeScript: ESLint Security

```bash
npm install --save-dev eslint @eslint/plugin-security eslint-plugin-no-secrets
eslint . --ext .js,.jsx,.ts,.tsx --format json > eslint-security.json
```

**設定**: `.eslintrc-security.json`
```json
{
  "plugins": ["@eslint/plugin-security", "eslint-plugin-no-secrets"],
  "extends": ["plugin:security/recommended"],
  "rules": {
    "security/detect-object-injection": "error",
    "security/detect-non-literal-fs-filename": "error",
    "security/detect-eval-with-expression": "error",
    "security/detect-pseudo-random-prng": "error",
    "no-secrets/no-secrets": "error"
  }
}
```

### 多言語: Semgrep

```bash
pip install semgrep
semgrep --config=auto --json --output=semgrep-report.json
semgrep --config=p/security-audit --json
semgrep --config=p/owasp-top-ten --json
semgrep ci --config=auto  # CIモード
```

**カスタムルール**: `.semgrep.yml`
```yaml
rules:
  - id: sql-injection-format-string
    pattern: cursor.execute("... %s ..." % $VAR)
    message: 文字列フォーマットによるSQLインジェクション
    severity: ERROR
    languages: [python]
    metadata:
      cwe: "CWE-89"
      owasp: "A03:2021-Injection"

  - id: dangerous-innerHTML
    pattern: $ELEM.innerHTML = $VAR
    message: innerHTMLによるXSS
    severity: ERROR
    languages: [javascript, typescript]
    metadata:
      cwe: "CWE-79"

  - id: hardcoded-aws-credentials
    patterns:
      - pattern: $KEY = "AKIA..."
      - metavariable-regex:
          metavariable: $KEY
          regex: "(aws_access_key_id|AWS_ACCESS_KEY_ID)"
    message: ハードコードされたAWS認証情報を検出
    severity: ERROR
    languages: [python, javascript, java]

  - id: path-traversal-open
    patterns:
      - pattern: open($PATH, ...)
      - pattern-not: open(os.path.join(SAFE_DIR, ...), ...)
      - metavariable-pattern:
          metavariable: $PATH
          patterns:
            - pattern: $REQ.get(...)
    message: ユーザー入力によるパストラバーサル
    severity: ERROR
    languages: [python]

  - id: command-injection
    patterns:
      - pattern-either:
          - pattern: os.system($CMD)
          - pattern: subprocess.call($CMD, shell=True)
      - metavariable-pattern:
          metavariable: $CMD
          patterns:
            - pattern-either:
                - pattern: $X + $Y
                - pattern: f"...{$VAR}..."
    message: shell=Trueによるコマンドインジェクション
    severity: ERROR
    languages: [python]
```

### その他の言語ツール

**Java**: `mvn spotbugs:check`
**Ruby**: `brakeman -o report.json -f json`
**Go**: `gosec -fmt=json -out=gosec.json ./...`
**Rust**: `cargo clippy -- -W clippy::unwrap_used`

## 脆弱性パターン

### SQLインジェクション

**脆弱**: SQLクエリでユーザー入力を使った文字列フォーマット/連結

**セキュア**:
```python
# パラメータ化されたクエリ
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
User.objects.filter(id=user_id)  # ORM
```

### クロスサイトスクリプティング（XSS）

**脆弱**: サニタイズされていないユーザー入力による直接HTML操作（innerHTML、outerHTML、document.write）

**セキュア**:
```javascript
// プレーンテキストにはtextContentを使用
element.textContent = userInput;

// Reactは自動エスケープ
<div>{userInput}</div>

// HTML必要時はサニタイズ
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

### ハードコードされたシークレット

**脆弱**: ソースコードにハードコードされたAPIキー、パスワード、トークン

**セキュア**:
```python
import os
API_KEY = os.environ.get('API_KEY')
PASSWORD = os.getenv('DB_PASSWORD')
```

### パストラバーサル

**脆弱**: サニタイズされていないユーザー入力を使用したファイルオープン

**セキュア**:
```python
import os
ALLOWED_DIR = '/var/www/uploads'
file_name = request.args.get('file')
file_path = os.path.join(ALLOWED_DIR, file_name)
file_path = os.path.realpath(file_path)
if not file_path.startswith(os.path.realpath(ALLOWED_DIR)):
    raise ValueError("Invalid file path")
with open(file_path, 'r') as f:
    content = f.read()
```

### 安全でない逆シリアル化

**脆弱**: 信頼できないデータでのpickle.loads()、yaml.load()

**セキュア**:
```python
import json
data = json.loads(user_input)  # セキュア
import yaml
config = yaml.safe_load(user_input)  # セキュア
```

### コマンドインジェクション

**脆弱**: ユーザー入力を伴うos.system()またはshell=Trueのsubprocess

**セキュア**:
```python
subprocess.run(['ping', '-c', '4', user_input])  # 配列引数
import shlex
safe_input = shlex.quote(user_input)  # 入力検証
```

### 安全でないランダム

**脆弱**: セキュリティクリティカル操作でのrandomモジュール

**セキュア**:
```python
import secrets
token = secrets.token_hex(16)
session_id = secrets.token_urlsafe(32)
```

## フレームワークセキュリティ

### Django

**脆弱**: @csrf_exempt、DEBUG=True、弱いSECRET_KEY、欠落したセキュリティミドルウェア

**セキュア**:
```python
# settings.py
DEBUG = False
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
X_FRAME_OPTIONS = 'DENY'
```

### Flask

**脆弱**: debug=True、弱いsecret_key、CORSワイルドカード

**セキュア**:
```python
import os
from flask_talisman import Talisman

app.secret_key = os.environ.get('FLASK_SECRET_KEY')
Talisman(app, force_https=True)
CORS(app, origins=['https://example.com'])
```

### Express.js

**脆弱**: helmetなし、CORSワイルドカード、レート制限なし

**セキュア**:
```javascript
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

app.use(helmet());
app.use(cors({ origin: 'https://example.com' }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
```

## 多言語スキャナー実装

```python
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Any
from dataclasses import dataclass
from datetime import datetime

@dataclass
class SASTFinding:
    tool: str
    severity: str
    category: str
    title: str
    description: str
    file_path: str
    line_number: int
    cwe: str
    owasp: str
    confidence: str

class MultiLanguageSASTScanner:
    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.findings: List[SASTFinding] = []

    def detect_languages(self) -> List[str]:
        """言語自動検出"""
        languages = []
        indicators = {
            'python': ['*.py', 'requirements.txt'],
            'javascript': ['*.js', 'package.json'],
            'typescript': ['*.ts', 'tsconfig.json'],
            'java': ['*.java', 'pom.xml'],
            'ruby': ['*.rb', 'Gemfile'],
            'go': ['*.go', 'go.mod'],
            'rust': ['*.rs', 'Cargo.toml'],
        }
        for lang, patterns in indicators.items():
            for pattern in patterns:
                if list(self.project_path.glob(f'**/{pattern}')):
                    languages.append(lang)
                    break
        return languages

    def run_comprehensive_sast(self) -> Dict[str, Any]:
        """すべての適用可能なSASTツールを実行"""
        languages = self.detect_languages()

        scan_results = {
            'timestamp': datetime.now().isoformat(),
            'languages': languages,
            'tools_executed': [],
            'findings': []
        }

        self.run_semgrep_scan()
        scan_results['tools_executed'].append('semgrep')

        if 'python' in languages:
            self.run_bandit_scan()
            scan_results['tools_executed'].append('bandit')
        if 'javascript' in languages or 'typescript' in languages:
            self.run_eslint_security_scan()
            scan_results['tools_executed'].append('eslint-security')

        scan_results['findings'] = [vars(f) for f in self.findings]
        scan_results['summary'] = self.generate_summary()
        return scan_results

    def run_semgrep_scan(self):
        """Semgrepを実行"""
        for ruleset in ['auto', 'p/security-audit', 'p/owasp-top-ten']:
            try:
                result = subprocess.run([
                    'semgrep', '--config', ruleset, '--json', '--quiet',
                    str(self.project_path)
                ], capture_output=True, text=True, timeout=300)

                if result.stdout:
                    data = json.loads(result.stdout)
                    for f in data.get('results', []):
                        self.findings.append(SASTFinding(
                            tool='semgrep',
                            severity=f.get('extra', {}).get('severity', 'MEDIUM').upper(),
                            category='sast',
                            title=f.get('check_id', ''),
                            description=f.get('extra', {}).get('message', ''),
                            file_path=f.get('path', ''),
                            line_number=f.get('start', {}).get('line', 0),
                            cwe=f.get('extra', {}).get('metadata', {}).get('cwe', ''),
                            owasp=f.get('extra', {}).get('metadata', {}).get('owasp', ''),
                            confidence=f.get('extra', {}).get('metadata', {}).get('confidence', 'MEDIUM')
                        ))
            except Exception as e:
                print(f"Semgrep {ruleset} failed: {e}")

    def generate_summary(self) -> Dict[str, Any]:
        """統計を生成"""
        severity_counts = {'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
        for f in self.findings:
            severity_counts[f.severity] = severity_counts.get(f.severity, 0) + 1

        return {
            'total_findings': len(self.findings),
            'severity_breakdown': severity_counts,
            'risk_score': self.calculate_risk_score(severity_counts)
        }

    def calculate_risk_score(self, severity_counts: Dict[str, int]) -> int:
        """リスクスコア 0-100"""
        weights = {'CRITICAL': 10, 'HIGH': 7, 'MEDIUM': 4, 'LOW': 1}
        total = sum(weights[s] * c for s, c in severity_counts.items())
        return min(100, int((total / 50) * 100))
```

## CI/CD統合

### GitHub Actions

```yaml
name: SAST Scan
on:
  pull_request:
    branches: [main]

jobs:
  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install tools
        run: |
          pip install bandit semgrep
          npm install -g eslint @eslint/plugin-security

      - name: Run scans
        run: |
          bandit -r . -f json -o bandit.json || true
          semgrep --config=auto --json --output=semgrep.json || true

      - name: Upload reports
        uses: actions/upload-artifact@v3
        with:
          name: sast-reports
          path: |
            bandit.json
            semgrep.json
```

### GitLab CI

```yaml
sast:
  stage: test
  image: python:3.11
  script:
    - pip install bandit semgrep
    - bandit -r . -f json -o bandit.json || true
    - semgrep --config=auto --json --output=semgrep.json || true
  artifacts:
    reports:
      sast: bandit.json
```

## ベストプラクティス

1. **早期頻繁実行** - プレコミットフックとCI/CD
2. **複数ツール併用** - 異なるツールが異なる脆弱性を検出
3. **誤検知調整** - 除外としきい値を設定
4. **発見の優先順位付け** - まずCRITICAL/HIGHに焦点
5. **フレームワーク対応スキャン** - 特定のルールセットを使用
6. **カスタムルール** - 組織固有のパターン
7. **開発者トレーニング** - セキュアコーディング実践
8. **段階的修復** - 徐々に修正
9. **ベースライン管理** - 既知の問題を追跡
10. **定期更新** - ツールを最新に保つ

## 関連ツール

- **security-secrets.md** - 高度な認証情報検出
- **security-owasp.md** - OWASP Top 10評価
- **security-api.md** - APIセキュリティテスト
- **security-scan.md** - 包括的セキュリティスキャン
