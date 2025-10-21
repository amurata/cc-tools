> **[English](../../../../../../plugins/cloud-infrastructure/skills/hybrid-cloud-networking/SKILL.md)** | **日本語**

---
name: hybrid-cloud-networking
description: VPNと専用接続を使用してオンプレミスインフラとクラウドプラットフォーム間のセキュアで高性能な接続を構成します。ハイブリッドクラウドアーキテクチャ構築、データセンターとクラウドの接続、セキュアなクロスプレミスネットワーキング実装時に使用します。
---

# ハイブリッドクラウドネットワーキング

VPN、Direct Connect、ExpressRouteを使用したオンプレミスとクラウド環境間のセキュアで高性能な接続の構成。

## 目的

オンプレミスデータセンターとクラウドプロバイダー（AWS、Azure、GCP）間のセキュアで信頼性の高いネットワーク接続を確立します。

## 使用タイミング

- オンプレミスとクラウドの接続
- データセンターのクラウドへの拡張
- ハイブリッドアクティブ-アクティブセットアップの実装
- コンプライアンス要件の達成
- クラウドへの段階的マイグレーション

## 接続オプション

### AWS接続

#### 1. サイト間VPN
- インターネット経由のIPSec VPN
- トンネルあたり最大1.25 Gbps
- 中程度の帯域幅に対してコスト効率的
- レイテンシが高く、インターネット依存

```hcl
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-vpn-gateway"
  }
}

resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "203.0.113.1"
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = false
}
```

#### 2. AWS Direct Connect
- 専用ネットワーク接続
- 1 Gbpsから100 Gbps
- 低レイテンシ、一貫した帯域幅
- より高価で、セットアップ時間が必要

**参照:** `references/direct-connect.md`参照

### Azure接続

#### 1. サイト間VPN
```hcl
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}
```

#### 2. Azure ExpressRoute
- 接続プロバイダー経由のプライベート接続
- 最大100 Gbps
- 低レイテンシ、高信頼性
- グローバル接続のためのプレミアム

### GCP接続

#### 1. Cloud VPN
- IPSec VPN（クラシックまたはHA VPN）
- HA VPN: 99.99% SLA
- トンネルあたり最大3 Gbps

#### 2. Cloud Interconnect
- 専用（10 Gbps、100 Gbps）
- パートナー（50 Mbpsから50 Gbps）
- VPNより低レイテンシ

## ハイブリッドネットワークパターン

### パターン1: ハブアンドスポーク
```
オンプレミスデータセンター
         ↓
    VPN/Direct Connect
         ↓
    Transit Gateway (AWS) / vWAN (Azure)
         ↓
    ├─ 本番VPC/VNet
    ├─ ステージングVPC/VNet
    └─ 開発VPC/VNet
```

### パターン2: マルチリージョンハイブリッド
```
オンプレミス
    ├─ Direct Connect → us-east-1
    └─ Direct Connect → us-west-2
            ↓
        クロスリージョンピアリング
```

### パターン3: マルチクラウドハイブリッド
```
オンプレミスデータセンター
    ├─ Direct Connect → AWS
    ├─ ExpressRoute → Azure
    └─ Interconnect → GCP
```

## ルーティング設定

### BGP設定
```
オンプレミスルーター:
- AS番号: 65000
- アドバタイズ: 10.0.0.0/8

クラウドルーター:
- AS番号: 64512 (AWS)、65515 (Azure)
- アドバタイズ: クラウドVPC/VNet CIDR
```

### ルート伝播
- ルートテーブルでルート伝播を有効化
- 動的ルーティングにBGPを使用
- ルートフィルタリングの実装
- ルートアドバタイズメントの監視

## セキュリティベストプラクティス

1. **プライベート接続の使用**（Direct Connect/ExpressRoute）
2. **VPNトンネルの暗号化実装**
3. **VPCエンドポイントの使用**でインターネットルーティング回避
4. **ネットワークACLとセキュリティグループの設定**
5. **VPCフローログの有効化**で監視
6. **DDoS保護の実装**
7. **PrivateLink/プライベートエンドポイントの使用**
8. **CloudWatch/Monitorで接続を監視**
9. **冗長性の実装**（デュアルトンネル）
10. **定期的なセキュリティ監査**

## 高可用性

### デュアルVPNトンネル
```hcl
resource "aws_vpn_connection" "primary" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.primary.id
  type                = "ipsec.1"
}

resource "aws_vpn_connection" "secondary" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.secondary.id
  type                = "ipsec.1"
}
```

### アクティブ-アクティブ設定
- 異なる場所からの複数接続
- 自動フェイルオーバー用BGP
- 等コストマルチパス（ECMP）ルーティング
- すべての接続のヘルス監視

## 監視とトラブルシューティング

### 主要メトリクス
- トンネルステータス（アップ/ダウン）
- 入出力バイト
- パケットロス
- レイテンシ
- BGPセッションステータス

### トラブルシューティング
```bash
# AWS VPN
aws ec2 describe-vpn-connections
aws ec2 get-vpn-connection-telemetry

# Azure VPN
az network vpn-connection show
az network vpn-connection show-device-config-script
```

## コスト最適化

1. **トラフィックに基づいて接続を適正サイズ化**
2. **低帯域幅ワークロードにVPNを使用**
3. **より少ない接続でトラフィックを統合**
4. **データ転送コストを最小化**
5. **高帯域幅にDirect Connectを使用**
6. **トラフィック削減のためキャッシングを実装**

## 参照ファイル

- `references/vpn-setup.md` - VPN設定ガイド
- `references/direct-connect.md` - Direct Connectセットアップ

## 関連スキル

- `multi-cloud-architecture` - アーキテクチャ決定用
- `terraform-module-library` - IaC実装用
