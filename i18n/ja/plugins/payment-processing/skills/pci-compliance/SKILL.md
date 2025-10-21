---
name: pci-compliance
description: 決済カードデータおよび決済システムの安全な取り扱いのためのPCI DSS準拠要件を実装します。決済処理の保護、PCI準拠の達成、決済カードセキュリティ対策の実装時に使用します。
---

> **[English](../../../../../plugins/payment-processing/skills/pci-compliance/SKILL.md)** | **日本語**

# PCI準拠

安全な決済処理およびカード会員データの取り扱いのためのPCI DSS（Payment Card Industry Data Security Standard）準拠をマスターします。

## このスキルを使用する場面

- 決済処理システムの構築
- クレジットカード情報の取り扱い
- 安全な決済フローの実装
- PCI準拠監査の実施
- PCI準拠範囲の削減
- トークン化および暗号化の実装
- PCI DSS評価の準備

## PCI DSS要件（12の中核要件）

### 安全なネットワークの構築と維持
1. ファイアウォール設定のインストールと維持
2. パスワードにベンダー提供のデフォルトを使用しない

### カード会員データの保護
3. 保存されたカード会員データの保護
4. 公開ネットワーク経由でのカード会員データ送信の暗号化

### 脆弱性管理プログラムの維持
5. マルウェアからシステムを保護
6. 安全なシステムおよびアプリケーションの開発と維持

### 強力なアクセス制御対策の実装
7. ビジネス上の必要性に基づいてカード会員データへのアクセスを制限
8. システムコンポーネントへのアクセスの識別と認証
9. カード会員データへの物理的アクセスの制限

### ネットワークの監視とテスト
10. ネットワークリソースおよびカード会員データへのすべてのアクセスの追跡と監視
11. セキュリティシステムとプロセスの定期的なテスト

### 情報セキュリティポリシーの維持
12. 情報セキュリティに対処するポリシーの維持

## 準拠レベル

**レベル1**: 年間600万件以上の取引（年次ROCが必要）
**レベル2**: 年間100万～600万件の取引（年次SAQ）
**レベル3**: 年間2万～100万件のEコマース取引
**レベル4**: 年間2万件未満のEコマースまたは100万件未満の総取引

## データ最小化（決して保存しない）

```python
# NEVER STORE THESE
PROHIBITED_DATA = {
    'full_track_data': 'Magnetic stripe data',
    'cvv': 'Card verification code/value',
    'pin': 'PIN or PIN block'
}

# CAN STORE (if encrypted)
ALLOWED_DATA = {
    'pan': 'Primary Account Number (card number)',
    'cardholder_name': 'Name on card',
    'expiration_date': 'Card expiration',
    'service_code': 'Service code'
}

class PaymentData:
    """Safe payment data handling."""

    def __init__(self):
        self.prohibited_fields = ['cvv', 'cvv2', 'cvc', 'pin']

    def sanitize_log(self, data):
        """Remove sensitive data from logs."""
        sanitized = data.copy()

        # Mask PAN
        if 'card_number' in sanitized:
            card = sanitized['card_number']
            sanitized['card_number'] = f"{card[:6]}{'*' * (len(card) - 10)}{card[-4:]}"

        # Remove prohibited data
        for field in self.prohibited_fields:
            sanitized.pop(field, None)

        return sanitized

    def validate_no_prohibited_storage(self, data):
        """Ensure no prohibited data is being stored."""
        for field in self.prohibited_fields:
            if field in data:
                raise SecurityError(f"Attempting to store prohibited field: {field}")
```

## トークン化

### 決済プロセッサートークンの使用
```python
import stripe

class TokenizedPayment:
    """Handle payments using tokens (no card data on server)."""

    @staticmethod
    def create_payment_method_token(card_details):
        """Create token from card details (client-side only)."""
        # THIS SHOULD ONLY BE DONE CLIENT-SIDE WITH STRIPE.JS
        # NEVER send card details to your server

        """
        // Frontend JavaScript
        const stripe = Stripe('pk_...');

        const {token, error} = await stripe.createToken({
            card: {
                number: '4242424242424242',
                exp_month: 12,
                exp_year: 2024,
                cvc: '123'
            }
        });

        // Send token.id to server (NOT card details)
        """
        pass

    @staticmethod
    def charge_with_token(token_id, amount):
        """Charge using token (server-side)."""
        # Your server only sees the token, never the card number
        stripe.api_key = "sk_..."

        charge = stripe.Charge.create(
            amount=amount,
            currency="usd",
            source=token_id,  # Token instead of card details
            description="Payment"
        )

        return charge

    @staticmethod
    def store_payment_method(customer_id, payment_method_token):
        """Store payment method as token for future use."""
        stripe.Customer.modify(
            customer_id,
            source=payment_method_token
        )

        # Store only customer_id and payment_method_id in your database
        # NEVER store actual card details
        return {
            'customer_id': customer_id,
            'has_payment_method': True
            # DO NOT store: card number, CVV, etc.
        }
```

### カスタムトークン化（上級）
```python
import secrets
from cryptography.fernet import Fernet

class TokenVault:
    """Secure token vault for card data (if you must store it)."""

    def __init__(self, encryption_key):
        self.cipher = Fernet(encryption_key)
        self.vault = {}  # In production: use encrypted database

    def tokenize(self, card_data):
        """Convert card data to token."""
        # Generate secure random token
        token = secrets.token_urlsafe(32)

        # Encrypt card data
        encrypted = self.cipher.encrypt(json.dumps(card_data).encode())

        # Store token -> encrypted data mapping
        self.vault[token] = encrypted

        return token

    def detokenize(self, token):
        """Retrieve card data from token."""
        encrypted = self.vault.get(token)
        if not encrypted:
            raise ValueError("Token not found")

        # Decrypt
        decrypted = self.cipher.decrypt(encrypted)
        return json.loads(decrypted.decode())

    def delete_token(self, token):
        """Remove token from vault."""
        self.vault.pop(token, None)
```

## 暗号化

### 保存データ
```python
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os

class EncryptedStorage:
    """Encrypt data at rest using AES-256-GCM."""

    def __init__(self, encryption_key):
        """Initialize with 256-bit key."""
        self.key = encryption_key  # Must be 32 bytes

    def encrypt(self, plaintext):
        """Encrypt data."""
        # Generate random nonce
        nonce = os.urandom(12)

        # Encrypt
        aesgcm = AESGCM(self.key)
        ciphertext = aesgcm.encrypt(nonce, plaintext.encode(), None)

        # Return nonce + ciphertext
        return nonce + ciphertext

    def decrypt(self, encrypted_data):
        """Decrypt data."""
        # Extract nonce and ciphertext
        nonce = encrypted_data[:12]
        ciphertext = encrypted_data[12:]

        # Decrypt
        aesgcm = AESGCM(self.key)
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)

        return plaintext.decode()

# Usage
storage = EncryptedStorage(os.urandom(32))
encrypted_pan = storage.encrypt("4242424242424242")
# Store encrypted_pan in database
```

### 転送中のデータ
```python
# Always use TLS 1.2 or higher
# Flask/Django example
app.config['SESSION_COOKIE_SECURE'] = True  # HTTPS only
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Strict'

# Enforce HTTPS
from flask_talisman import Talisman
Talisman(app, force_https=True)
```

## アクセス制御

```python
from functools import wraps
from flask import session

def require_pci_access(f):
    """Decorator to restrict access to cardholder data."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        user = session.get('user')

        # Check if user has PCI access role
        if not user or 'pci_access' not in user.get('roles', []):
            return {'error': 'Unauthorized access to cardholder data'}, 403

        # Log access attempt
        audit_log(
            user=user['id'],
            action='access_cardholder_data',
            resource=f.__name__
        )

        return f(*args, **kwargs)

    return decorated_function

@app.route('/api/payment-methods')
@require_pci_access
def get_payment_methods():
    """Retrieve payment methods (restricted access)."""
    # Only accessible to users with pci_access role
    pass
```

## 監査ログ

```python
import logging
from datetime import datetime

class PCIAuditLogger:
    """PCI-compliant audit logging."""

    def __init__(self):
        self.logger = logging.getLogger('pci_audit')
        # Configure to write to secure, append-only log

    def log_access(self, user_id, resource, action, result):
        """Log access to cardholder data."""
        entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'user_id': user_id,
            'resource': resource,
            'action': action,
            'result': result,
            'ip_address': request.remote_addr
        }

        self.logger.info(json.dumps(entry))

    def log_authentication(self, user_id, success, method):
        """Log authentication attempt."""
        entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'user_id': user_id,
            'event': 'authentication',
            'success': success,
            'method': method,
            'ip_address': request.remote_addr
        }

        self.logger.info(json.dumps(entry))

# Usage
audit = PCIAuditLogger()
audit.log_access(user_id=123, resource='payment_methods', action='read', result='success')
```

## セキュリティベストプラクティス

### 入力検証
```python
import re

def validate_card_number(card_number):
    """Validate card number format (Luhn algorithm)."""
    # Remove spaces and dashes
    card_number = re.sub(r'[\s-]', '', card_number)

    # Check if all digits
    if not card_number.isdigit():
        return False

    # Luhn algorithm
    def luhn_checksum(card_num):
        def digits_of(n):
            return [int(d) for d in str(n)]

        digits = digits_of(card_num)
        odd_digits = digits[-1::-2]
        even_digits = digits[-2::-2]
        checksum = sum(odd_digits)
        for d in even_digits:
            checksum += sum(digits_of(d * 2))
        return checksum % 10

    return luhn_checksum(card_number) == 0

def sanitize_input(user_input):
    """Sanitize user input to prevent injection."""
    # Remove special characters
    # Validate against expected format
    # Escape for database queries
    pass
```

## PCI DSS SAQ（自己評価質問票）

### SAQ A（最小要件）
- ホスト型決済ページを使用するEコマース
- システム上にカードデータなし
- 約20問

### SAQ A-EP
- 埋め込み決済フォームを使用するEコマース
- JavaScriptを使用してカードデータを処理
- 約180問

### SAQ D（最大要件）
- カードデータの保存、処理、または送信
- 完全なPCI DSS要件
- 約300問

## 準拠チェックリスト

```python
PCI_COMPLIANCE_CHECKLIST = {
    'network_security': [
        'Firewall configured and maintained',
        'No vendor default passwords',
        'Network segmentation implemented'
    ],
    'data_protection': [
        'No storage of CVV, track data, or PIN',
        'PAN encrypted when stored',
        'PAN masked when displayed',
        'Encryption keys properly managed'
    ],
    'vulnerability_management': [
        'Anti-virus installed and updated',
        'Secure development practices',
        'Regular security patches',
        'Vulnerability scanning performed'
    ],
    'access_control': [
        'Access restricted by role',
        'Unique IDs for all users',
        'Multi-factor authentication',
        'Physical security measures'
    ],
    'monitoring': [
        'Audit logs enabled',
        'Log review process',
        'File integrity monitoring',
        'Regular security testing'
    ],
    'policy': [
        'Security policy documented',
        'Risk assessment performed',
        'Security awareness training',
        'Incident response plan'
    ]
}
```

## リソース

- **references/data-minimization.md**: 禁止データの非保存
- **references/tokenization.md**: トークン化戦略
- **references/encryption.md**: 暗号化要件
- **references/access-control.md**: ロールベースアクセス
- **references/audit-logging.md**: 包括的なログ記録
- **assets/pci-compliance-checklist.md**: 完全なチェックリスト
- **assets/encrypted-storage.py**: 暗号化ユーティリティ
- **scripts/audit-payment-system.sh**: 準拠監査スクリプト

## よくある違反

1. **CVVの保存**: カード検証コードを決して保存しない
2. **暗号化されていないPAN**: カード番号は保存時に暗号化する必要がある
3. **弱い暗号化**: AES-256または同等のものを使用
4. **アクセス制御なし**: カード会員データにアクセスできる人を制限
5. **監査ログの欠落**: 決済データへのすべてのアクセスをログ記録する必要がある
6. **安全でない送信**: 常にTLS 1.2以上を使用
7. **デフォルトパスワード**: すべてのデフォルト認証情報を変更
8. **セキュリティテストなし**: 定期的な侵入テストが必要

## PCI範囲の削減

1. **ホスト型決済の使用**: Stripeチェックアウト、PayPalなど
2. **トークン化**: カードデータをトークンに置き換え
3. **ネットワークセグメント化**: カード会員データ環境を分離
4. **アウトソーシング**: PCI準拠の決済プロセッサーを使用
5. **保存なし**: 完全なカード詳細を決して保存しない

カードデータに接触するシステムを最小化することで、準拠負担を大幅に削減できます。
