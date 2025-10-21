---
name: stripe-integration
description: 堅牢でPCI準拠の決済フロー（チェックアウト、サブスクリプション、Webhook）を含むStripe決済処理を実装します。Stripe決済の統合、サブスクリプションシステムの構築、安全なチェックアウトフローの実装時に使用します。
---

> **[English](../../../../../plugins/payment-processing/skills/stripe-integration/SKILL.md)** | **日本語**

# Stripe統合

堅牢でPCI準拠の決済フロー（チェックアウト、サブスクリプション、Webhook、返金）を含むStripe決済処理統合をマスターします。

## このスキルを使用する場面

- Webおよびモバイルアプリケーションでの決済処理の実装
- サブスクリプション課金システムの構築
- 一回限りの支払いと定期課金の処理
- 返金および紛争処理
- 顧客の支払い方法の管理
- ヨーロッパでの決済向けSCA（強力な顧客認証）の実装
- Stripe Connectによるマーケットプレイス決済フローの構築

## コアコンセプト

### 1. 決済フロー
**チェックアウトセッション（ホスト型）**
- Stripeがホストする決済ページ
- PCI準拠の負担が最小限
- 最速の実装
- 一回限りおよび定期支払いをサポート

**ペイメントインテント（カスタムUI）**
- 決済UIの完全な制御
- PCI準拠のためにStripe.jsが必要
- より複雑な実装
- 優れたカスタマイズオプション

**セットアップインテント（支払い方法の保存）**
- 課金せずに支払い方法を収集
- サブスクリプションおよび将来の支払いに使用
- 顧客の確認が必要

### 2. Webhook
**重要なイベント：**
- `payment_intent.succeeded`: 支払い完了
- `payment_intent.payment_failed`: 支払い失敗
- `customer.subscription.updated`: サブスクリプション変更
- `customer.subscription.deleted`: サブスクリプションキャンセル
- `charge.refunded`: 返金処理済み
- `invoice.payment_succeeded`: サブスクリプション支払い成功

### 3. サブスクリプション
**コンポーネント：**
- **プロダクト**: 販売しているもの
- **価格**: 金額と頻度
- **サブスクリプション**: 顧客の定期支払い
- **インボイス**: 各請求サイクルごとに生成

### 4. 顧客管理
- 顧客レコードの作成および管理
- 複数の支払い方法の保存
- 顧客メタデータの追跡
- 請求詳細の管理

## クイックスタート

```python
import stripe

stripe.api_key = "sk_test_..."

# Create a checkout session
session = stripe.checkout.Session.create(
    payment_method_types=['card'],
    line_items=[{
        'price_data': {
            'currency': 'usd',
            'product_data': {
                'name': 'Premium Subscription',
            },
            'unit_amount': 2000,  # $20.00
            'recurring': {
                'interval': 'month',
            },
        },
        'quantity': 1,
    }],
    mode='subscription',
    success_url='https://yourdomain.com/success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url='https://yourdomain.com/cancel',
)

# Redirect user to session.url
print(session.url)
```

## 決済実装パターン

### パターン1: 一回限りの支払い（ホストチェックアウト）
```python
def create_checkout_session(amount, currency='usd'):
    """Create a one-time payment checkout session."""
    try:
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[{
                'price_data': {
                    'currency': currency,
                    'product_data': {
                        'name': 'Purchase',
                        'images': ['https://example.com/product.jpg'],
                    },
                    'unit_amount': amount,  # Amount in cents
                },
                'quantity': 1,
            }],
            mode='payment',
            success_url='https://yourdomain.com/success?session_id={CHECKOUT_SESSION_ID}',
            cancel_url='https://yourdomain.com/cancel',
            metadata={
                'order_id': 'order_123',
                'user_id': 'user_456'
            }
        )
        return session
    except stripe.error.StripeError as e:
        # Handle error
        print(f"Stripe error: {e.user_message}")
        raise
```

### パターン2: カスタムペイメントインテントフロー
```python
def create_payment_intent(amount, currency='usd', customer_id=None):
    """Create a payment intent for custom checkout UI."""
    intent = stripe.PaymentIntent.create(
        amount=amount,
        currency=currency,
        customer=customer_id,
        automatic_payment_methods={
            'enabled': True,
        },
        metadata={
            'integration_check': 'accept_a_payment'
        }
    )
    return intent.client_secret  # Send to frontend

# Frontend (JavaScript)
"""
const stripe = Stripe('pk_test_...');
const elements = stripe.elements();
const cardElement = elements.create('card');
cardElement.mount('#card-element');

const {error, paymentIntent} = await stripe.confirmCardPayment(
    clientSecret,
    {
        payment_method: {
            card: cardElement,
            billing_details: {
                name: 'Customer Name'
            }
        }
    }
);

if (error) {
    // Handle error
} else if (paymentIntent.status === 'succeeded') {
    // Payment successful
}
"""
```

### パターン3: サブスクリプション作成
```python
def create_subscription(customer_id, price_id):
    """Create a subscription for a customer."""
    try:
        subscription = stripe.Subscription.create(
            customer=customer_id,
            items=[{'price': price_id}],
            payment_behavior='default_incomplete',
            payment_settings={'save_default_payment_method': 'on_subscription'},
            expand=['latest_invoice.payment_intent'],
        )

        return {
            'subscription_id': subscription.id,
            'client_secret': subscription.latest_invoice.payment_intent.client_secret
        }
    except stripe.error.StripeError as e:
        print(f"Subscription creation failed: {e}")
        raise
```

### パターン4: カスタマーポータル
```python
def create_customer_portal_session(customer_id):
    """Create a portal session for customers to manage subscriptions."""
    session = stripe.billing_portal.Session.create(
        customer=customer_id,
        return_url='https://yourdomain.com/account',
    )
    return session.url  # Redirect customer here
```

## Webhook処理

### 安全なWebhookエンドポイント
```python
from flask import Flask, request
import stripe

app = Flask(__name__)

endpoint_secret = 'whsec_...'

@app.route('/webhook', methods=['POST'])
def webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except ValueError:
        # Invalid payload
        return 'Invalid payload', 400
    except stripe.error.SignatureVerificationError:
        # Invalid signature
        return 'Invalid signature', 400

    # Handle the event
    if event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        handle_successful_payment(payment_intent)
    elif event['type'] == 'payment_intent.payment_failed':
        payment_intent = event['data']['object']
        handle_failed_payment(payment_intent)
    elif event['type'] == 'customer.subscription.deleted':
        subscription = event['data']['object']
        handle_subscription_canceled(subscription)

    return 'Success', 200

def handle_successful_payment(payment_intent):
    """Process successful payment."""
    customer_id = payment_intent.get('customer')
    amount = payment_intent['amount']
    metadata = payment_intent.get('metadata', {})

    # Update your database
    # Send confirmation email
    # Fulfill order
    print(f"Payment succeeded: {payment_intent['id']}")

def handle_failed_payment(payment_intent):
    """Handle failed payment."""
    error = payment_intent.get('last_payment_error', {})
    print(f"Payment failed: {error.get('message')}")
    # Notify customer
    # Update order status

def handle_subscription_canceled(subscription):
    """Handle subscription cancellation."""
    customer_id = subscription['customer']
    # Update user access
    # Send cancellation email
    print(f"Subscription canceled: {subscription['id']}")
```

### Webhookベストプラクティス
```python
import hashlib
import hmac

def verify_webhook_signature(payload, signature, secret):
    """Manually verify webhook signature."""
    expected_sig = hmac.new(
        secret.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(signature, expected_sig)

def handle_webhook_idempotently(event_id, handler):
    """Ensure webhook is processed exactly once."""
    # Check if event already processed
    if is_event_processed(event_id):
        return

    # Process event
    try:
        handler()
        mark_event_processed(event_id)
    except Exception as e:
        log_error(e)
        # Stripe will retry failed webhooks
        raise
```

## 顧客管理

```python
def create_customer(email, name, payment_method_id=None):
    """Create a Stripe customer."""
    customer = stripe.Customer.create(
        email=email,
        name=name,
        payment_method=payment_method_id,
        invoice_settings={
            'default_payment_method': payment_method_id
        } if payment_method_id else None,
        metadata={
            'user_id': '12345'
        }
    )
    return customer

def attach_payment_method(customer_id, payment_method_id):
    """Attach a payment method to a customer."""
    stripe.PaymentMethod.attach(
        payment_method_id,
        customer=customer_id
    )

    # Set as default
    stripe.Customer.modify(
        customer_id,
        invoice_settings={
            'default_payment_method': payment_method_id
        }
    )

def list_customer_payment_methods(customer_id):
    """List all payment methods for a customer."""
    payment_methods = stripe.PaymentMethod.list(
        customer=customer_id,
        type='card'
    )
    return payment_methods.data
```

## 返金処理

```python
def create_refund(payment_intent_id, amount=None, reason=None):
    """Create a refund."""
    refund_params = {
        'payment_intent': payment_intent_id
    }

    if amount:
        refund_params['amount'] = amount  # Partial refund

    if reason:
        refund_params['reason'] = reason  # 'duplicate', 'fraudulent', 'requested_by_customer'

    refund = stripe.Refund.create(**refund_params)
    return refund

def handle_dispute(charge_id, evidence):
    """Update dispute with evidence."""
    stripe.Dispute.modify(
        charge_id,
        evidence={
            'customer_name': evidence.get('customer_name'),
            'customer_email_address': evidence.get('customer_email'),
            'shipping_documentation': evidence.get('shipping_proof'),
            'customer_communication': evidence.get('communication'),
        }
    )
```

## テスト

```python
# Use test mode keys
stripe.api_key = "sk_test_..."

# Test card numbers
TEST_CARDS = {
    'success': '4242424242424242',
    'declined': '4000000000000002',
    '3d_secure': '4000002500003155',
    'insufficient_funds': '4000000000009995'
}

def test_payment_flow():
    """Test complete payment flow."""
    # Create test customer
    customer = stripe.Customer.create(
        email="test@example.com"
    )

    # Create payment intent
    intent = stripe.PaymentIntent.create(
        amount=1000,
        currency='usd',
        customer=customer.id,
        payment_method_types=['card']
    )

    # Confirm with test card
    confirmed = stripe.PaymentIntent.confirm(
        intent.id,
        payment_method='pm_card_visa'  # Test payment method
    )

    assert confirmed.status == 'succeeded'
```

## リソース

- **references/checkout-flows.md**: 詳細なチェックアウト実装
- **references/webhook-handling.md**: Webhookセキュリティと処理
- **references/subscription-management.md**: サブスクリプションライフサイクル
- **references/customer-management.md**: 顧客および支払い方法の処理
- **references/invoice-generation.md**: インボイス発行および請求
- **assets/stripe-client.py**: 本番環境対応のStripeクライアントラッパー
- **assets/webhook-handler.py**: 完全なWebhookプロセッサー
- **assets/checkout-config.json**: チェックアウト設定テンプレート

## ベストプラクティス

1. **常にWebhookを使用**: クライアント側の確認のみに依存しない
2. **冪等性**: Webhookイベントを冪等的に処理
3. **エラー処理**: すべてのStripeエラーを適切に処理
4. **テストモード**: 本番環境前にテストキーで徹底的にテスト
5. **メタデータ**: メタデータを使用してStripeオブジェクトをデータベースにリンク
6. **モニタリング**: 支払い成功率とエラーを追跡
7. **PCI準拠**: サーバー上で生のカードデータを処理しない
8. **SCA対応**: ヨーロッパでの決済向けに3Dセキュアを実装

## よくある落とし穴

- **Webhookの検証なし**: 常にWebhook署名を検証
- **Webhookイベントの欠落**: すべての関連するWebhookイベントを処理
- **金額のハードコーディング**: セント/最小通貨単位を使用
- **リトライロジックなし**: APIコールのリトライを実装
- **テストモードの無視**: テストカードですべてのエッジケースをテスト
