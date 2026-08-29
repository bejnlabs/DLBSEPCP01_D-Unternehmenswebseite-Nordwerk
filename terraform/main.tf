terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Speicherkontonamen muessen weltweit eindeutig sein. Ohne Zufallssuffix
# laeuft das Skript bei fremden Pruefenden nicht durch.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    course      = var.course_id
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

# ---------- Ebene 1: Auslieferung ----------
module "static_site" {
  source = "./modules/static-site"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = var.project_name
  suffix              = random_string.suffix.result
  replication_type    = var.replication_type
  website_source_path = "${path.module}/../website"

  versioning_enabled      = var.versioning_enabled
  retention_days          = var.retention_days
  old_version_expiry_days = var.old_version_expiry_days

  tags = local.common_tags
}

# ---------- Ebene 2: Betriebsueberwachung ----------
module "observability" {
  source = "./modules/observability"
  count  = var.deploy_observability ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = var.project_name
  suffix              = random_string.suffix.result
  storage_account_id  = module.static_site.storage_account_id
  retention_days      = var.log_retention_days

  tags = local.common_tags
}
