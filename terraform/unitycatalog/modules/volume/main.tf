terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.59.0"
    }
  }
}

locals {
  lowercase_service_principal_names = toset([for principal in toset(setunion(var.principals_with_readonly_permissions, var.principals_with_modify_permissions)) : lower(principal)])
}

data "databricks_catalog" "this" {
  name = var.catalog_name
}

data "databricks_schema" "this" {
  name = "${data.databricks_catalog.this.name}.${var.schema_name}"
}

data "databricks_service_principal" "spn" {
  for_each     = local.lowercase_service_principal_names
  display_name = each.key
}

locals {
  modify_permissions = {
    "default" = ["READ_VOLUME", "WRITE_VOLUME"]
  }

  readonly_permissions = {
    "default" = ["READ_VOLUME"]
  }
}

resource "databricks_grants" "volume_permissions" {
  volume = "${data.databricks_schema.this.name}.${var.volume_name}"

  # Permissions for Groups
  dynamic "grant" {
    for_each = var.groups_with_modify_permissions
    content {
      principal  = grant.value
      privileges = local.modify_permissions["default"]
    }
  }

  dynamic "grant" {
    for_each = var.groups_with_readonly_permissions
    content {
      principal  = grant.value
      privileges = local.readonly_permissions["default"]
    }
  }

  # Permissions for Service Principals
  dynamic "grant" {
    for_each = var.principals_with_modify_permissions
    content {
      principal  = data.databricks_service_principal.spn[lower(grant.key)].application_id
      privileges = local.modify_permissions["default"]
    }
  }

  dynamic "grant" {
    for_each = var.principals_with_readonly_permissions
    content {
      principal  = data.databricks_service_principal.spn[lower(grant.key)].application_id
      privileges = local.readonly_permissions["default"]
    }
  }
}
