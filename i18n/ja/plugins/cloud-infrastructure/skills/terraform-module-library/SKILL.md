> **[English](../../../../../../plugins/cloud-infrastructure/skills/terraform-module-library/SKILL.md)** | **日本語**

---
name: terraform-module-library
description: Infrastructure as Codeベストプラクティスに従って、AWS、Azure、GCPインフラ用の再利用可能なTerraformモジュールを構築します。インフラモジュール作成、クラウドプロビジョニング標準化、再利用可能なIaCコンポーネント実装時に使用します。
---

# Terraformモジュールライブラリ

AWS、Azure、GCPインフラ用の本番環境対応Terraformモジュールパターン。

## 目的

複数のクラウドプロバイダーにまたがる一般的なクラウドインフラパターン用の再利用可能で、十分にテストされたTerraformモジュールを作成します。

## 使用タイミング

- 再利用可能なインフラコンポーネントの構築
- クラウドリソースプロビジョニングの標準化
- Infrastructure as Codeベストプラクティスの実装
- マルチクラウド互換モジュールの作成
- 組織のTerraform標準の確立

## モジュール構造

```
terraform-modules/
├── aws/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   └── s3/
├── azure/
│   ├── vnet/
│   ├── aks/
│   └── storage/
└── gcp/
    ├── vpc/
    ├── gke/
    └── cloud-sql/
```

## 標準モジュールパターン

```
module-name/
├── main.tf          # メインリソース
├── variables.tf     # 入力変数
├── outputs.tf       # 出力値
├── versions.tf      # プロバイダーバージョン
├── README.md        # ドキュメント
├── examples/        # 使用例
│   └── complete/
│       ├── main.tf
│       └── variables.tf
└── tests/           # Terratestファイル
    └── module_test.go
```

## AWS VPCモジュール例

**main.tf:**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name = "${var.name}-private-${count.index + 1}"
      Tier = "private"
    },
    var.tags
  )
}

resource "aws_internet_gateway" "main" {
  count  = var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.name}-igw"
    },
    var.tags
  )
}
```

**variables.tf:**
```hcl
variable "name" {
  description = "VPCの名前"
  type        = string
}

variable "cidr_block" {
  description = "VPC用CIDRブロック"
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.cidr_block))
    error_message = "CIDRブロックは有効なIPv4 CIDR表記でなければなりません。"
  }
}

variable "availability_zones" {
  description = "アベイラビリティゾーンのリスト"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネット用CIDRブロック"
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "VPCでDNSホスト名を有効化"
  type        = bool
  default     = true
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}
```

**outputs.tf:**
```hcl
output "vpc_id" {
  description = "VPCのID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "プライベートサブネットのID"
  value       = aws_subnet.private[*].id
}

output "vpc_cidr_block" {
  description = "VPCのCIDRブロック"
  value       = aws_vpc.main.cidr_block
}
```

## ベストプラクティス

1. **モジュールにセマンティックバージョニングを使用**
2. **説明付きですべての変数を文書化**
3. **examples/ディレクトリに例を提供**
4. **入力検証に検証ブロックを使用**
5. **モジュール構成のために重要な属性を出力**
6. **versions.tfでプロバイダーバージョンをピン**
7. **計算値にlocalsを使用**
8. **count/for_eachで条件付きリソースを実装**
9. **Terratestでモジュールをテスト**
10. **すべてのリソースに一貫してタグ付け**

## モジュール構成

```hcl
module "vpc" {
  source = "../../modules/aws/vpc"

  name               = "production"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  private_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

module "rds" {
  source = "../../modules/aws/rds"

  identifier     = "production-db"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.large"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Environment = "production"
  }
}
```

## 参照ファイル

- `assets/vpc-module/` - 完全なVPCモジュール例
- `assets/rds-module/` - RDSモジュール例
- `references/aws-modules.md` - AWSモジュールパターン
- `references/azure-modules.md` - Azureモジュールパターン
- `references/gcp-modules.md` - GCPモジュールパターン

## テスト

```go
// tests/vpc_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/complete",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcID := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcID)
}
```

## 関連スキル

- `multi-cloud-architecture` - アーキテクチャ決定用
- `cost-optimization` - コスト効率的な設計用
