terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.59.0"
    }
  }
}

locals {
  lowercase_service_principal_names = toset([for principal in toset(var.principals_with_use_catalog_permission) : lower(principal)])
}


data "databricks_catalog" "this" {
  name = var.catalog_name
}

data "databricks_service_principal" "spn" {
  for_each     = local.lowercase_service_principal_names
  display_name = each.key
}


resource "databricks_grants" "catalog_permissions" {
  catalog = data.databricks_catalog.this.name

  dynamic "grant" {
    for_each = var.groups_with_all_permissions
    content {
      principal  = grant.value
      privileges = ["ALL_PRIVILEGES"]
    }
  }

  dynamic "grant" {
    for_each = var.groups_with_use_catalog_permission
    content {
      principal  = grant.value
      privileges = ["USE_CATALOG"]
    }
  }

  dynamic "grant" {
    for_each = var.principals_with_use_catalog_permission
    content {
      principal  = data.databricks_service_principal.spn[lower(grant.value)].application_id
      privileges = ["USE_CATALOG"]
    }
  }
}
