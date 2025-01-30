variable "catalog_name" {
  description = "Catalog name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}


variable "groups_with_all_permissions" {
  description = "List of Databricks groups that will be given the ALL_PRIVILIGES permission on the catalog. Restricted to `-Admin` groups."
  type        = list(string)
  default     = []

  validation {
    condition     = length(regexall("-Admin", join("", var.groups_with_all_permissions))) == length(var.groups_with_all_permissions)
    error_message = "Only groups with the suffix '-Admin' can be given ALL_PRIVILEGES.\nCurrent values are: [${join(", ", var.groups_with_all_permissions)}]"
  }

  // check that catalogs of which the name contains `_sec_` can only get permissions from groups with `-Sec` suffix
  validation {
    condition     = length(regexall("_sec_", var.catalog_name)) == 0 || length(regexall("-Sec-Admin$", join("", var.groups_with_all_permissions))) == length(var.groups_with_all_permissions)
    error_message = "On catalogs with the '_sec_' name fragment, only groups with the '-Sec-Admin' suffix in the name can be given permissions.\nCurrent values are: [${join(", ", var.groups_with_all_permissions)}] for catalog with name ${var.catalog_name}"
  }
}

variable "groups_with_use_catalog_permission" {
  description = "List of Databricks groups that will be given the CAN_USE permission on the catalog"
  type        = list(string)
  default     = []

  // check that values in the group are not in the list of groups with all privileges
  validation {
    condition     = length(setunion(var.groups_with_use_catalog_permission, var.groups_with_all_permissions)) == sum([length(var.groups_with_use_catalog_permission), length(var.groups_with_all_permissions)])
    error_message = "Groups with USE_CATALOG permission cannot also have the ALL_PRIVILEGES permission assigned.\n Overlapping values are: [${join(", ", setintersection(var.groups_with_use_catalog_permission, var.groups_with_all_permissions))}]"
  }

  // check that catalogs of which the name contains `_sec_` can only get permissions from groups with `-Sec` or `-Sec_Readonly` suffix
  validation {
    condition     = length(regexall("_sec_", var.catalog_name)) == 0 || length(regexall("-Sec|-Sec_Readonly", join("", var.groups_with_use_catalog_permission))) == length(var.groups_with_use_catalog_permission)
    error_message = "On catalogs with the '_sec_' name fragment, only groups with the '-Sec' or '-Sec_Readonly' suffix in the name can be given permissions.\nCurrent values are: [${join(", ", var.groups_with_use_catalog_permission)}] for catalog with name ${var.catalog_name}"
  }
}

variable "principals_with_use_catalog_permission" {
  description = "List of Databricks principals that will be given the CAN_USE permission on the catalog"
  type        = list(string)
  default     = []

  // check that catalogs of which the name contains `_sec_` can only get permissions from principals with the `_sec_ ${environment}` suffix 
  validation {
    condition     = length(regexall("_sec_", var.catalog_name)) == 0 || length(regexall("_sec_${var.environment}", join("", var.principals_with_use_catalog_permission))) == length(var.principals_with_use_catalog_permission)
    error_message = "On catalogs with the '_sec_' name fragment, only principals with the '_sec_${lower(var.environment)}' suffix in the name can be given permissions .\nCurrent values are: [${join(", ", var.principals_with_use_catalog_permission)}] for catalog with name ${var.catalog_name}"
  }
}

