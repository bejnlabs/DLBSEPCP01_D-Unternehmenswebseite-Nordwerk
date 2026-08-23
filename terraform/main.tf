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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "azurerm" {
  features {}
}

# Zufaelliges Suffix: Speicherkonto- und Funktionsnamen muessen weltweit
# eindeutig sein. Ohne Suffix laeuft das Skript bei fremden Pruefenden
# nicht durch.
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

module "static_site" {
  source = "./modules/static-site"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = var.project_name
  suffix              = random_string.suffix.result
  replication_type    = var.replication_type
  website_source_path = "${path.module}/../website"
  tags                = local.common_tags
}

module "backend_api" {
  source = "./modules/backend-api"
  count  = var.deploy_backend ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name_prefix         = var.project_name
  suffix              = random_string.suffix.result
  function_source_dir = "${path.module}/../function"
  tags                = local.common_tags
}

module "edge" {
  source = "./modules/edge"
  count  = var.deploy_edge ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  name_prefix         = var.project_name
  suffix              = random_string.suffix.result
  origin_host_name    = module.static_site.primary_web_host
  api_host_name       = var.deploy_backend ? module.backend_api[0].default_hostname : null
  tags                = local.common_tags
}
