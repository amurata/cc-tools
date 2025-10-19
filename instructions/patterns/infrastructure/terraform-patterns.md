# Terraform Infrastructure as Code Patterns

Best practices for managing infrastructure with Terraform.

## Module Structure

### Standard Module Layout
```
modules/
  vpc/
    main.tf
    variables.tf
    outputs.tf
    versions.tf
    README.md
  
  ec2/
    main.tf
    variables.tf
    outputs.tf
    locals.tf
    
environments/
  dev/
    main.tf
    terraform.tfvars
    backend.tf
  
  prod/
    main.tf
    terraform.tfvars
    backend.tf
```

### Module Example
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-subnet-${count.index + 1}"
      Type = "public"
    }
  )
}
```

## State Management

### Remote State Configuration
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "env/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# Remote state data source
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket"
    key    = "env/prod/network/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Variable Patterns

### Variable Definitions
```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_config" {
  description = "EC2 instance configuration"
  type = object({
    instance_type = string
    volume_size   = number
    monitoring    = bool
  })
  default = {
    instance_type = "t3.micro"
    volume_size   = 20
    monitoring    = false
  }
}

variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
```

### Local Values
```hcl
# locals.tf
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Timestamp   = timestamp()
    }
  )
  
  name_prefix = "${var.project}-${var.environment}"
  
  # Computed values
  az_count = min(length(data.aws_availability_zones.available.names), 3)
  
  # Conditional logic
  enable_monitoring = var.environment == "prod" ? true : false
}
```

## Resource Patterns

### Conditional Resources
```hcl
# Create resource conditionally
resource "aws_cloudwatch_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "${local.name_prefix}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = var.dashboard_metrics
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
}

# Reference conditional resource
output "dashboard_url" {
  value = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_arn : null
}
```

### Dynamic Blocks
```hcl
resource "aws_security_group" "main" {
  name_prefix = local.name_prefix
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.allow_all_egress ? [1] : []
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

## Data Sources

### Using Data Sources
```hcl
# Fetch existing resources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Use in resources
resource "aws_instance" "main" {
  ami               = data.aws_ami.amazon_linux.id
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Owner = data.aws_caller_identity.current.arn
  }
}
```

## Provisioners

### Local and Remote Exec
```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  # Local provisioner
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> inventory.txt"
  }

  # Remote provisioner
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  # File provisioner
  provisioner "file" {
    source      = "configs/nginx.conf"
    destination = "/tmp/nginx.conf"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

## Workspaces

### Environment Management
```hcl
# Use workspace in configuration
locals {
  environment = terraform.workspace
  
  instance_count = {
    default = 1
    dev     = 1
    staging = 2
    prod    = 3
  }
}

resource "aws_instance" "app" {
  count = lookup(local.instance_count, local.environment, 1)
  
  instance_type = local.environment == "prod" ? "t3.large" : "t3.micro"
  
  tags = {
    Environment = local.environment
    Workspace   = terraform.workspace
  }
}
```

## Functions and Expressions

### Built-in Functions
```hcl
locals {
  # String functions
  upper_name = upper(var.name)
  formatted  = format("%s-%s", var.project, var.environment)
  
  # List functions
  subnet_ids = concat(
    aws_subnet.public[*].id,
    aws_subnet.private[*].id
  )
  
  # Map functions
  merged_tags = merge(
    var.default_tags,
    var.custom_tags,
    {
      Timestamp = formatdate("YYYY-MM-DD", timestamp())
    }
  )
  
  # Conditional
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  
  # Loops
  instance_names = [for i in range(var.instance_count) : "${var.name}-${i}"]
  
  # Map transformation
  uppercase_tags = { for k, v in var.tags : k => upper(v) }
}
```

## Testing

### Validation
```hcl
# terraform.tfvars.example
environment = "dev"
cidr_block  = "10.0.0.0/16"

# Validate configuration
# terraform validate

# Plan with variable file
# terraform plan -var-file="terraform.tfvars"

# Format check
# terraform fmt -check=true -recursive

# Security scanning with tfsec
# tfsec .
```

## Best Practices

### Version Constraints
```hcl
# versions.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
```

## Checklist
- [ ] Use modules for reusability
- [ ] Configure remote state
- [ ] Implement state locking
- [ ] Use consistent naming
- [ ] Add validation rules
- [ ] Version pin providers
- [ ] Document module usage
- [ ] Implement proper tagging