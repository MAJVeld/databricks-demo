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
  catalog_name_without_environment = join("_", slice(split("_", var.catalog_name), 0, 2))

  elevated_permissions_for_groups_by_catalog = {
    "default" = ["ALL_PRIVILEGES"]
  }

  modify_permissions_for_groups_by_catalog = {
    "default"         = ["SELECT", "USE_SCHEMA"]
    "westeurope_test" = ["APPLY_TAG", "CREATE_FUNCTION", "CREATE_MATERIALIZED_VIEW", "CREATE_TABLE", "EXECUTE", "MODIFY", "READ_VOLUME", "REFRESH", "SELECT", "USE_SCHEMA", "WRITE_VOLUME"]
  }

  readonly_permissions_for_groups_by_catalog = {
    "default"         = ["SELECT", "USE_SCHEMA"]
    "westeurope_test" = ["EXECUTE", "READ_VOLUME", "SELECT", "USE_SCHEMA"]
  }

  modify_permissions_for_principals_by_catalog = {
    "default"         = ["SELECT", "USE_SCHEMA"]
    "westeurope_test" = ["APPLY_TAG", "CREATE_FUNCTION", "CREATE_MATERIALIZED_VIEW", "CREATE_TABLE", "EXECUTE", "MODIFY", "READ_VOLUME", "REFRESH", "SELECT", "USE_SCHEMA", "WRITE_VOLUME"]
  }

  readonly_permissions_for_principals_by_catalog = {
    "default"         = ["SELECT", "USE_SCHEMA"]
    "westeurope_test" = ["USE_SCHEMA", "EXECUTE", "SELECT"]
  }
}

resource "databricks_grants" "schema_permissions" {
  schema = data.databricks_schema.this.id

  # Permissions for Groups
  dynamic "grant" {
    for_each = var.groups_with_elevated_permissions
    content {
      principal  = grant.value
      privileges = try(local.elevated_permissions_for_groups_by_catalog[local.catalog_name_without_environment], local.elevated_permissions_for_groups_by_catalog["default"])
    }
  }

  dynamic "grant" {
    for_each = var.groups_with_modify_permissions
    content {
      principal  = grant.value
      privileges = setunion(lookup(var.additional_permissions, grant.value, []), try(local.modify_permissions_for_groups_by_catalog[local.catalog_name_without_environment], local.modify_permissions_for_groups_by_catalog["default"]))
    }
  }

  dynamic "grant" {
    for_each = var.groups_with_readonly_permissions
    content {
      principal  = grant.value
      privileges = setunion(lookup(var.additional_permissions, grant.value, []), try(local.readonly_permissions_for_groups_by_catalog[local.catalog_name_without_environment], local.readonly_permissions_for_groups_by_catalog["default"]))
    }
  }

  # Permissions for Service Principals
  dynamic "grant" {
    for_each = var.principals_with_modify_permissions
    content {
      principal  = data.databricks_service_principal.spn[lower(grant.key)].application_id
      privileges = setunion(lookup(var.additional_permissions, grant.value, []), try(local.modify_permissions_for_principals_by_catalog[local.catalog_name_without_environment], local.modify_permissions_for_principals_by_catalog["default"]))
    }
  }

  dynamic "grant" {
    for_each = var.principals_with_readonly_permissions
    content {
      principal  = data.databricks_service_principal.spn[lower(grant.key)].application_id
      privileges = setunion(lookup(var.additional_permissions, grant.value, []), try(local.readonly_permissions_for_principals_by_catalog[local.catalog_name_without_environment], local.readonly_permissions_for_principals_by_catalog["default"]))
    }
  }
}
