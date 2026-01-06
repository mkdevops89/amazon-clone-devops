provider "azurerm" {
  features {}
}

# ==========================================
# Resource Group
# ==========================================
# Logical container for all Azure resources
resource "azurerm_resource_group" "rg" {
  name     = "amazon-resources"
  location = "East US"
}

# ==========================================
# AKS Cluster (Compute Layer)
# ==========================================
# Azure Kubernetes Service
module "aks" {
  source  = "Azure/aks/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  prefix              = "amazon"
}

# ==========================================
# Azure Database for MySQL
# ==========================================
resource "azurerm_mysql_server" "mysql" {
  name                = "amazon-mysql-server"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  administrator_login          = "adminuser"
  administrator_login_password = "password123!"
  
  sku_name   = "B_Gen5_1" # Basic tier
  storage_mb = 5120
  version    = "8.0"
}

# ==========================================
# Azure Cache for Redis
# ==========================================
resource "azurerm_redis_cache" "redis" {
  name                = "amazon-redis"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = true # Use SSL in production!
}
