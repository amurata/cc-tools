> **[English](../../../plugins/security-compliance/commands/compliance-check.md)** | **日本語**

# 規制コンプライアンスチェック

GDPR、HIPAA、SOC2、PCI-DSS、その他の業界標準を含むソフトウェアシステムの規制要件を専門とするコンプライアンス専門家です。コンプライアンスの達成と維持のため、包括的なコンプライアンス監査を実施し、実装ガイダンスを提供します。

## コンテキスト
ユーザーは、アプリケーションが規制要件と業界標準を満たすことを確認する必要があります。コンプライアンス制御の実用的な実装、自動監視、監査証跡の生成に焦点を当てます。

## 要件
$ARGUMENTS

## 手順

### 1. コンプライアンスフレームワーク分析

適用可能な規制と標準を特定します：

**規制マッピング**
```python
class ComplianceAnalyzer:
    def __init__(self):
        self.regulations = {
            'GDPR': {
                'scope': 'EUデータ保護',
                'applies_if': [
                    'EU居住者のデータを処理',
                    'EUへ商品/サービスを提供',
                    'EU居住者の行動を監視'
                ],
                'key_requirements': [
                    'プライバシーバイデザイン',
                    'データ最小化',
                    '消去する権利',
                    'データポータビリティ',
                    '同意管理',
                    'DPO任命',
                    'プライバシー通知',
                    'データ侵害通知（72時間以内）'
                ]
            },
            'HIPAA': {
                'scope': 'ヘルスケアデータ保護（米国）',
                'applies_if': [
                    'ヘルスケアプロバイダー',
                    '健康保険プロバイダー',
                    'ヘルスケアクリアリングハウス',
                    'ビジネスアソシエイト'
                ],
                'key_requirements': [
                    'PHI暗号化',
                    'アクセス制御',
                    '監査ログ',
                    'ビジネスアソシエイト契約',
                    'リスク評価',
                    '従業員トレーニング',
                    'インシデント対応',
                    '物理的保護措置'
                ]
            },
            'SOC2': {
                'scope': 'サービス組織統制',
                'applies_if': [
                    'SaaSプロバイダー',
                    'データプロセッサ',
                    'クラウドサービス'
                ],
                'trust_principles': [
                    'セキュリティ',
                    '可用性',
                    '処理の完全性',
                    '機密性',
                    'プライバシー'
                ]
            },
            'PCI-DSS': {
                'scope': '決済カードデータセキュリティ',
                'applies_if': [
                    'クレジット/デビットカード受付',
                    'カード決済処理',
                    'カードデータ保存',
                    'カードデータ送信'
                ],
                'compliance_levels': {
                    'レベル1': '年間600万件超の取引',
                    'レベル2': '年間100万〜600万件の取引',
                    'レベル3': '年間2万〜100万件の取引',
                    'レベル4': '年間2万件未満の取引'
                }
            }
        }

    def determine_applicable_regulations(self, business_info):
        """
        ビジネスコンテキストに基づいて適用可能な規制を決定
        """
        applicable = []

        # 各規制をチェック
        for reg_name, reg_info in self.regulations.items():
            if self._check_applicability(business_info, reg_info):
                applicable.append({
                    'regulation': reg_name,
                    'reason': self._get_applicability_reason(business_info, reg_info),
                    'priority': self._calculate_priority(business_info, reg_name)
                })

        return sorted(applicable, key=lambda x: x['priority'], reverse=True)
```

### 2. データプライバシーコンプライアンス

プライバシー制御を実装：

**GDPR実装**
```python
class GDPRCompliance:
    def implement_privacy_controls(self):
        """
        GDPR要件のプライバシー制御を実装
        """
        controls = {}

        # 1. 同意管理
        controls['consent_management'] = '''
class ConsentManager:
    def __init__(self):
        self.consent_types = [
            'marketing_emails',
            'analytics_tracking',
            'third_party_sharing',
            'profiling'
        ]

    def record_consent(self, user_id, consent_type, granted):
        """
        完全な監査証跡でユーザーの同意を記録
        """
        consent_record = {
            'user_id': user_id,
            'consent_type': consent_type,
            'granted': granted,
            'timestamp': datetime.utcnow(),
            'ip_address': request.remote_addr,
            'user_agent': request.headers.get('User-Agent'),
            'version': self.get_current_privacy_policy_version(),
            'method': 'explicit_checkbox'  # 事前チェックなし
        }

        # 追加専用監査ログに保存
        self.consent_audit_log.append(consent_record)

        # 現在の同意ステータスを更新
        self.update_user_consents(user_id, consent_type, granted)

        return consent_record

    def verify_consent(self, user_id, consent_type):
        """
        ユーザーが特定の処理に同意したか確認
        """
        consent = self.get_user_consent(user_id, consent_type)
        return consent and consent['granted'] and not consent.get('withdrawn')
'''

        # 2. 消去する権利（忘れられる権利）
        controls['right_to_erasure'] = '''
class DataErasureService:
    def process_erasure_request(self, user_id, verification_token):
        """
        GDPR第17条の消去リクエストを処理
        """
        # リクエストの真正性を確認
        if not self.verify_erasure_token(user_id, verification_token):
            raise ValueError("Invalid erasure request")

        erasure_log = {
            'user_id': user_id,
            'requested_at': datetime.utcnow(),
            'data_categories': []
        }

        # 1. 個人データ
        self.erase_user_profile(user_id)
        erasure_log['data_categories'].append('profile')

        # 2. ユーザー生成コンテンツ（削除ではなく匿名化）
        self.anonymize_user_content(user_id)
        erasure_log['data_categories'].append('content_anonymized')

        # 3. 分析データ
        self.remove_from_analytics(user_id)
        erasure_log['data_categories'].append('analytics')

        # 4. バックアップデータ（削除をスケジュール）
        self.schedule_backup_deletion(user_id)
        erasure_log['data_categories'].append('backups_scheduled')

        # 5. 第三者に通知
        self.notify_processors_of_erasure(user_id)

        # 法的コンプライアンスのため最小限の記録を保持
        self.store_erasure_record(erasure_log)

        return {
            'status': 'completed',
            'erasure_id': erasure_log['id'],
            'categories_erased': erasure_log['data_categories']
        }
'''

        # 3. データポータビリティ
        controls['data_portability'] = '''
class DataPortabilityService:
    def export_user_data(self, user_id, format='json'):
        """
        GDPR第20条 - データポータビリティ
        """
        user_data = {
            'export_date': datetime.utcnow().isoformat(),
            'user_id': user_id,
            'format_version': '2.0',
            'data': {}
        }

        # すべてのユーザーデータを収集
        user_data['data']['profile'] = self.get_user_profile(user_id)
        user_data['data']['preferences'] = self.get_user_preferences(user_id)
        user_data['data']['content'] = self.get_user_content(user_id)
        user_data['data']['activity'] = self.get_user_activity(user_id)
        user_data['data']['consents'] = self.get_consent_history(user_id)

        # リクエストに基づいてフォーマット
        if format == 'json':
            return json.dumps(user_data, indent=2)
        elif format == 'csv':
            return self.convert_to_csv(user_data)
        elif format == 'xml':
            return self.convert_to_xml(user_data)
'''

        return controls

**プライバシーバイデザイン**
```python
# プライバシーバイデザイン原則を実装
class PrivacyByDesign:
    def implement_data_minimization(self):
        """
        必要なデータのみを収集
        """
        # 以前（収集しすぎ）
        bad_user_model = {
            'email': str,
            'password': str,
            'full_name': str,
            'date_of_birth': date,
            'ssn': str,  # 不要
            'address': str,  # 基本サービスには不要
            'phone': str,  # 不要
            'gender': str,  # 不要
            'income': int  # 不要
        }

        # 改善後（データ最小化）
        good_user_model = {
            'email': str,  # 認証に必要
            'password_hash': str,  # 平文を保存しない
            'display_name': str,  # オプション、ユーザー提供
            'created_at': datetime,
            'last_login': datetime
        }

        return good_user_model

    def implement_pseudonymization(self):
        """
        識別フィールドを仮名に置き換え
        """
        def pseudonymize_record(record):
            # 一貫した仮名を生成
            user_pseudonym = hashlib.sha256(
                f"{record['user_id']}{SECRET_SALT}".encode()
            ).hexdigest()[:16]

            return {
                'pseudonym': user_pseudonym,
                'data': {
                    # 直接識別子を削除
                    'age_group': self._get_age_group(record['age']),
                    'region': self._get_region(record['ip_address']),
                    'activity': record['activity_data']
                }
            }
```

### 3. セキュリティコンプライアンス

様々な標準のセキュリティ制御を実装：

**SOC2セキュリティ制御**
```python
class SOC2SecurityControls:
    def implement_access_controls(self):
        """
        SOC2 CC6.1 - 論理的および物理的アクセス制御
        """
        controls = {
            'authentication': '''
# 多要素認証
class MFAEnforcement:
    def enforce_mfa(self, user, resource_sensitivity):
        if resource_sensitivity == 'high':
            return self.require_mfa(user)
        elif resource_sensitivity == 'medium' and user.is_admin:
            return self.require_mfa(user)
        return self.standard_auth(user)

    def require_mfa(self, user):
        factors = []

        # 要素1：パスワード（知っているもの）
        factors.append(self.verify_password(user))

        # 要素2：TOTP/SMS（持っているもの）
        if user.mfa_method == 'totp':
            factors.append(self.verify_totp(user))
        elif user.mfa_method == 'sms':
            factors.append(self.verify_sms_code(user))

        # 要素3：生体認証（本人であること） - オプション
        if user.biometric_enabled:
            factors.append(self.verify_biometric(user))

        return all(factors)
''',
            'authorization': '''
# ロールベースアクセス制御
class RBACAuthorization:
    def __init__(self):
        self.roles = {
            'admin': ['read', 'write', 'delete', 'admin'],
            'user': ['read', 'write:own'],
            'viewer': ['read']
        }

    def check_permission(self, user, resource, action):
        user_permissions = self.get_user_permissions(user)

        # 明示的な権限をチェック
        if action in user_permissions:
            return True

        # 所有権ベースの権限をチェック
        if f"{action}:own" in user_permissions:
            return self.user_owns_resource(user, resource)

        # 拒否されたアクセス試行をログ
        self.log_access_denied(user, resource, action)
        return False
''',
            'encryption': '''
# 保存時および転送時の暗号化
class EncryptionControls:
    def __init__(self):
        self.kms = KeyManagementService()

    def encrypt_at_rest(self, data, classification):
        if classification == 'sensitive':
            # エンベロープ暗号化を使用
            dek = self.kms.generate_data_encryption_key()
            encrypted_data = self.encrypt_with_key(data, dek)
            encrypted_dek = self.kms.encrypt_key(dek)

            return {
                'data': encrypted_data,
                'encrypted_key': encrypted_dek,
                'algorithm': 'AES-256-GCM',
                'key_id': self.kms.get_current_key_id()
            }

    def configure_tls(self):
        return {
            'min_version': 'TLS1.2',
            'ciphers': [
                'ECDHE-RSA-AES256-GCM-SHA384',
                'ECDHE-RSA-AES128-GCM-SHA256'
            ],
            'hsts': 'max-age=31536000; includeSubDomains',
            'certificate_pinning': True
        }
'''
        }

        return controls
```

### 4. 監査ログと監視

包括的な監査証跡を実装：

**監査ログシステム**
```python
class ComplianceAuditLogger:
    def __init__(self):
        self.required_events = {
            'authentication': [
                'login_success',
                'login_failure',
                'logout',
                'password_change',
                'mfa_enabled',
                'mfa_disabled'
            ],
            'authorization': [
                'access_granted',
                'access_denied',
                'permission_changed',
                'role_assigned',
                'role_revoked'
            ],
            'data_access': [
                'data_viewed',
                'data_exported',
                'data_modified',
                'data_deleted',
                'bulk_operation'
            ],
            'compliance': [
                'consent_given',
                'consent_withdrawn',
                'data_request',
                'data_erasure',
                'privacy_settings_changed'
            ]
        }

    def log_event(self, event_type, details):
        """
        改ざん防止監査ログエントリを作成
        """
        log_entry = {
            'id': str(uuid.uuid4()),
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event_type,
            'user_id': details.get('user_id'),
            'ip_address': self._get_ip_address(),
            'user_agent': request.headers.get('User-Agent'),
            'session_id': session.get('id'),
            'details': details,
            'compliance_flags': self._get_compliance_flags(event_type)
        }

        # 整合性チェックを追加
        log_entry['checksum'] = self._calculate_checksum(log_entry)

        # 不変ログに保存
        self._store_audit_log(log_entry)

        # 重要イベントのリアルタイムアラート
        if self._is_critical_event(event_type):
            self._send_security_alert(log_entry)

        return log_entry

    def _calculate_checksum(self, entry):
        """
        改ざん防止チェックサムを作成
        """
        # ブロックチェーン様の整合性のため前のエントリハッシュを含む
        previous_hash = self._get_previous_entry_hash()

        content = json.dumps(entry, sort_keys=True)
        return hashlib.sha256(
            f"{previous_hash}{content}{SECRET_KEY}".encode()
        ).hexdigest()
```

**コンプライアンスレポート**
```python
def generate_compliance_report(self, regulation, period):
    """
    監査人向けコンプライアンスレポートを生成
    """
    report = {
        'regulation': regulation,
        'period': period,
        'generated_at': datetime.utcnow(),
        'sections': {}
    }

    if regulation == 'GDPR':
        report['sections'] = {
            'data_processing_activities': self._get_processing_activities(period),
            'consent_metrics': self._get_consent_metrics(period),
            'data_requests': {
                'access_requests': self._count_access_requests(period),
                'erasure_requests': self._count_erasure_requests(period),
                'portability_requests': self._count_portability_requests(period),
                'response_times': self._calculate_response_times(period)
            },
            'data_breaches': self._get_breach_reports(period),
            'third_party_processors': self._list_processors(),
            'privacy_impact_assessments': self._get_dpias(period)
        }

    elif regulation == 'HIPAA':
        report['sections'] = {
            'access_controls': self._audit_access_controls(period),
            'phi_access_log': self._get_phi_access_log(period),
            'risk_assessments': self._get_risk_assessments(period),
            'training_records': self._get_training_compliance(period),
            'business_associates': self._list_bas_with_agreements(),
            'incident_response': self._get_incident_reports(period)
        }

    return report
```

### 5. ヘルスケアコンプライアンス（HIPAA）

HIPAA固有の制御を実装：

**PHI保護**
```python
class HIPAACompliance:
    def protect_phi(self):
        """
        保護対象健康情報のHIPAA保護措置を実装
        """
        # 技術的保護措置
        technical_controls = {
            'access_control': '''
class PHIAccessControl:
    def __init__(self):
        self.minimum_necessary_rule = True

    def grant_phi_access(self, user, patient_id, purpose):
        """
        最小必要基準を実装
        """
        # 正当な目的を確認
        if not self._verify_treatment_relationship(user, patient_id, purpose):
            self._log_denied_access(user, patient_id, purpose)
            raise PermissionError("No treatment relationship")

        # ロールと目的に基づいて制限付きアクセスを付与
        access_scope = self._determine_access_scope(user.role, purpose)

        # 時間制限付きアクセス
        access_token = {
            'user_id': user.id,
            'patient_id': patient_id,
            'scope': access_scope,
            'purpose': purpose,
            'expires_at': datetime.utcnow() + timedelta(hours=24),
            'audit_id': str(uuid.uuid4())
        }

        # すべてのアクセスをログ
        self._log_phi_access(access_token)

        return access_token
''',
            'encryption': '''
class PHIEncryption:
    def encrypt_phi_at_rest(self, phi_data):
        """
        PHIのHIPAA準拠暗号化
        """
        # FIPS 140-2検証済み暗号化を使用
        encryption_config = {
            'algorithm': 'AES-256-CBC',
            'key_derivation': 'PBKDF2',
            'iterations': 100000,
            'validation': 'FIPS-140-2-Level-2'
        }

        # PHIフィールドを暗号化
        encrypted_phi = {}
        for field, value in phi_data.items():
            if self._is_phi_field(field):
                encrypted_phi[field] = self._encrypt_field(value, encryption_config)
            else:
                encrypted_phi[field] = value

        return encrypted_phi

    def secure_phi_transmission(self):
        """
        転送中のPHIを保護
        """
        return {
            'protocols': ['TLS 1.2+'],
            'vpn_required': True,
            'email_encryption': 'S/MIMEまたはPGPが必要',
            'fax_alternative': 'セキュアメッセージングポータル'
        }
'''
        }

        # 管理的保護措置
        admin_controls = {
            'workforce_training': '''
class HIPAATraining:
    def track_training_compliance(self, employee):
        """
        従業員のHIPAAトレーニングコンプライアンスを確保
        """
        required_modules = [
            'HITPAAプライバシールール',
            'HIPAAセキュリティルール',
            'PHI取扱手順',
            '侵害通知',
            '患者の権利',
            '最小必要基準'
        ]

        training_status = {
            'employee_id': employee.id,
            'completed_modules': [],
            'pending_modules': [],
            'last_training_date': None,
            'next_due_date': None
        }

        for module in required_modules:
            completion = self._check_module_completion(employee.id, module)
            if completion and completion['date'] > datetime.now() - timedelta(days=365):
                training_status['completed_modules'].append(module)
            else:
                training_status['pending_modules'].append(module)

        return training_status
'''
        }

        return {
            'technical': technical_controls,
            'administrative': admin_controls
        }
```

### 6. 決済カードコンプライアンス（PCI-DSS）

PCI-DSS要件を実装：

**PCI-DSS制御**
```python
class PCIDSSCompliance:
    def implement_pci_controls(self):
        """
        PCI-DSS v4.0要件を実装
        """
        controls = {
            'cardholder_data_protection': '''
class CardDataProtection:
    def __init__(self):
        # これらを保存しない
        self.prohibited_data = ['cvv', 'cvv2', 'cvc2', 'cid', 'pin', 'pin_block']

    def handle_card_data(self, card_info):
        """
        PCI-DSS準拠カードデータ処理
        """
        # 即座にトークン化
        token = self.tokenize_card(card_info)

        # 保存する必要がある場合、許可されたフィールドのみ保存
        stored_data = {
            'token': token,
            'last_four': card_info['number'][-4:],
            'exp_month': card_info['exp_month'],
            'exp_year': card_info['exp_year'],
            'cardholder_name': self._encrypt(card_info['name'])
        }

        # 完全なカード番号をログに記録しない
        self._log_transaction(token, 'XXXX-XXXX-XXXX-' + stored_data['last_four'])

        return stored_data

    def tokenize_card(self, card_info):
        """
        PANをトークンに置き換え
        """
        # 決済プロセッサのトークン化を使用
        response = payment_processor.tokenize({
            'number': card_info['number'],
            'exp_month': card_info['exp_month'],
            'exp_year': card_info['exp_year']
        })

        return response['token']
''',
            'network_segmentation': '''
# PCIコンプライアンスのためのネットワークセグメンテーション
class PCINetworkSegmentation:
    def configure_network_zones(self):
        """
        ネットワークセグメンテーションを実装
        """
        zones = {
            'cde': {  # カード会員データ環境
                'description': 'CHDを処理、保存、または送信するシステム',
                'controls': [
                    'ファイアウォール必須',
                    'IDS/IPS監視',
                    '直接インターネットアクセスなし',
                    '四半期ごとの脆弱性スキャン',
                    '年次ペネトレーションテスト'
                ]
            },
            'dmz': {
                'description': '公開システム',
                'controls': [
                    'Webアプリケーションファイアウォール',
                    'CHD保存不可',
                    '定期的なセキュリティスキャン'
                ]
            },
            'internal': {
                'description': '内部企業ネットワーク',
                'controls': [
                    'CDEからセグメント化',
                    '制限付きCDEアクセス',
                    '標準セキュリティ制御'
                ]
            }
        }

        return zones
''',
            'vulnerability_management': '''
class PCIVulnerabilityManagement:
    def quarterly_scan_requirements(self):
        """
        PCI-DSS四半期スキャン要件
        """
        scan_config = {
            'internal_scans': {
                'frequency': '四半期ごと',
                'scope': 'すべてのCDEシステム',
                'tool': 'PCI承認スキャンベンダー',
                'passing_criteria': '高リスク脆弱性なし'
            },
            'external_scans': {
                'frequency': '四半期ごと',
                'performed_by': 'ASV（承認スキャンベンダー）',
                'scope': 'すべての外部向けIPアドレス',
                'passing_criteria': '失敗なしのクリーンスキャン'
            },
            'remediation_timeline': {
                'critical': '24時間',
                'high': '7日',
                'medium': '30日',
                'low': '90日'
            }
        }

        return scan_config
'''
        }

        return controls
```

### 7. 継続的コンプライアンス監視

自動コンプライアンス監視を設定：

**コンプライアンスダッシュボード**
```python
class ComplianceDashboard:
    def generate_realtime_dashboard(self):
        """
        リアルタイムコンプライアンスステータスダッシュボード
        """
        dashboard = {
            'timestamp': datetime.utcnow(),
            'overall_compliance_score': 0,
            'regulations': {}
        }

        # GDPRコンプライアンスメトリクス
        dashboard['regulations']['GDPR'] = {
            'score': self.calculate_gdpr_score(),
            'status': 'COMPLIANT',
            'metrics': {
                'consent_rate': '87%',
                'data_requests_sla': '30日以内に98%',
                'privacy_policy_version': '2.1',
                'last_dpia': '2025-06-15',
                'encryption_coverage': '100%',
                'third_party_agreements': '12/12署名済み'
            },
            'issues': [
                {
                    'severity': 'medium',
                    'issue': 'Cookieコンセントバナー更新が必要',
                    'due_date': '2025-08-01'
                }
            ]
        }

        # HIPAAコンプライアンスメトリクス
        dashboard['regulations']['HIPAA'] = {
            'score': self.calculate_hipaa_score(),
            'status': 'NEEDS_ATTENTION',
            'metrics': {
                'risk_assessment_current': True,
                'workforce_training_compliance': '94%',
                'baa_agreements': '8/8最新',
                'encryption_status': 'すべてのPHI暗号化',
                'access_reviews': '2025-06-30完了',
                'incident_response_tested': '2025-05-15'
            },
            'issues': [
                {
                    'severity': 'high',
                    'issue': 'トレーニング期限切れの従業員3名',
                    'due_date': '2025-07-25'
                }
            ]
        }

        return dashboard
```

**自動コンプライアンスチェック**
```yaml
# .github/workflows/compliance-check.yml
name: Compliance Checks

on:
  push:
    branches: [main, develop]
  pull_request:
  schedule:
    - cron: '0 0 * * *'  # 毎日のコンプライアンスチェック

jobs:
  compliance-scan:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: GDPR Compliance Check
      run: |
        python scripts/compliance/gdpr_checker.py

    - name: Security Headers Check
      run: |
        python scripts/compliance/security_headers.py

    - name: Dependency License Check
      run: |
        license-checker --onlyAllow 'MIT;Apache-2.0;BSD-3-Clause;ISC'

    - name: PII Detection Scan
      run: |
        # ハードコードされたPIIをスキャン
        python scripts/compliance/pii_scanner.py

    - name: Encryption Verification
      run: |
        # すべての機密データが暗号化されていることを確認
        python scripts/compliance/encryption_checker.py

    - name: Generate Compliance Report
      if: always()
      run: |
        python scripts/compliance/generate_report.py > compliance-report.json

    - name: Upload Compliance Report
      uses: actions/upload-artifact@v3
      with:
        name: compliance-report
        path: compliance-report.json
```

### 8. コンプライアンスドキュメント

必要なドキュメントを生成：

**プライバシーポリシージェネレーター**
```python
def generate_privacy_policy(company_info, data_practices):
    """
    GDPR準拠プライバシーポリシーを生成
    """
    policy = f"""
# プライバシーポリシー

**最終更新**: {datetime.now().strftime('%Y年%m月%d日')}

## 1. データ管理者
{company_info['name']}
{company_info['address']}
メール: {company_info['privacy_email']}
DPO: {company_info.get('dpo_contact', 'privacy@company.com')}

## 2. 収集するデータ
{generate_data_collection_section(data_practices['data_types'])}

## 3. 処理の法的根拠
{generate_legal_basis_section(data_practices['purposes'])}

## 4. あなたの権利
GDPRの下で、以下の権利があります：
- 個人データにアクセスする権利
- 訂正する権利
- 消去する権利（「忘れられる権利」）
- 処理を制限する権利
- データポータビリティの権利
- 異議を唱える権利
- 自動意思決定に関する権利

## 5. データ保持
{generate_retention_policy(data_practices['retention_periods'])}

## 6. 国際転送
{generate_transfer_section(data_practices['international_transfers'])}

## 7. お問い合わせ
権利を行使するには、{company_info['privacy_email']}までご連絡ください
"""

    return policy
```

## 出力形式

1. **コンプライアンス評価**: すべての適用可能な規制にわたる現在のコンプライアンスステータス
2. **ギャップ分析**: 重大度評価を伴う注意が必要な特定の領域
3. **実装計画**: コンプライアンス達成のための優先順位付けロードマップ
4. **技術的制御**: 必要な制御のコード実装
5. **ポリシーテンプレート**: プライバシーポリシー、同意フォーム、通知
6. **監査手順**: 継続的コンプライアンス監視のためのスクリプト
7. **ドキュメント**: 監査人のための必要な記録と証拠
8. **トレーニング資料**: 従業員コンプライアンストレーニングリソース

ビジネス運営とユーザーエクスペリエンスとコンプライアンス要件のバランスをとる実用的な実装に焦点を当てます。
