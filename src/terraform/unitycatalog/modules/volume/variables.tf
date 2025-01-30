variable "catalog_name" {
  description = "Catalog name"
  type        = string
  nullable    = false
}

variable "schema_name" {
  description = "Schema name"
  type        = string
  nullable    = false
}

variable "volume_name" {
  description = "Volume name"
  type        = string
  nullable    = false
}

variable "groups_with_modify_permissions" {
  description = "List of Databricks groups that will be given the permission to read and modify the volume"
  type        = set(string)
  default     = []

  // check that schemas of which the name ends with `sec` can only get permissions from groups with `-Sec` suffix
  validation {
    condition     = length(regexall("sec$", var.schema_name)) == 0 || length(regexall("-Sec", join("", var.groups_with_modify_permissions))) == length(var.groups_with_modify_permissions)
    error_message = "On schemas with the 'sec' suffix, only groups with the '-Sec' suffix in the name can be given permissions .\nCurrent values are: [${join(", ", var.groups_with_modify_permissions)}] for schema with name ${var.schema_name}"
  }

  // check that groups with the -Readonly suffix cannot be given MODIFY permissions on a schema
  validation {
    condition     = length(regexall("-Readonly", join("", var.groups_with_modify_permissions))) == 0
    error_message = "Groups with the '-Readonly' suffix cannot be given MODIFY permissions on a schema.\nCurrent values are: [${join(", ", var.groups_with_modify_permissions)}]"
  }
}

variable "groups_with_readonly_permissions" {
  description = "List of Databricks groups that will be given read only permission on the schema"
  type        = set(string)
  default     = []

  // check that schemas of which the name ends with `sec` can only get permissions from groups with `-Sec`or `-Sec_Readonly` suffix
  validation {
    condition     = length(regexall("sec$", var.schema_name)) == 0 || length(regexall("-Sec$|-Sec_Readonly$", join("", var.groups_with_readonly_permissions))) == length(var.groups_with_readonly_permissions)
    error_message = "On schemas with the 'sec' suffix, only groups with the'-Sec' or '-Sec_Readonly' suffix in the name can be given permissions.\nCurrent values are: [${join(", ", var.groups_with_readonly_permissions)}] for schema with name ${var.schema_name}"
  }
}

variable "principals_with_modify_permissions" {
  description = "List of Databricks Service Principals that will be given permission to read and modify the schema"
  type        = set(string)
  default     = []

  // check that values for principals in this group are not also present in other permission assignment groups
  validation {
    condition     = length(setunion(var.principals_with_modify_permissions, var.principals_with_readonly_permissions)) == sum([length(var.principals_with_modify_permissions), length(var.principals_with_readonly_permissions)])
    error_message = "A service principal can only be present in a single group. \nService principal names in the Modify permissions assignment group are: [${join(", ", var.principals_with_modify_permissions)}]\nService principal namess in the Read Only permissions assignment group are: [${join(", ", var.principals_with_readonly_permissions)}]"
  }

  // check that schemas of which the name ends with `sec` can only get permissions from service principals with `_sec_` in the name
  validation {
    condition     = length(regexall("sec$", var.schema_name)) == 0 || length(regexall("_sec_", join("", var.principals_with_modify_permissions))) == length(var.principals_with_modify_permissions)
    error_message = "On schemas with the 'sec' suffix, only principals with `_sec_` in the name can be given permissions.\nCurrent values are: [${join(", ", var.principals_with_modify_permissions)}] for schema with name ${var.schema_name}"
  }
}

variable "principals_with_readonly_permissions" {
  description = "List of Databricks Service Principals that will be given read only permission on the schema"
  type        = set(string)
  default     = []

  // check that schemas of which the name ends with `sec` can only get permissions from service principals with `_sec_` in the name
  validation {
    condition     = length(regexall("sec$", var.schema_name)) == 0 || length(regexall("_sec_", join("", var.principals_with_readonly_permissions))) == length(var.principals_with_readonly_permissions)
    error_message = "On schemas with the 'sec' suffix, only principals with `_sec_` in the name can be given permissions.\nCurrent values are: [${join(", ", var.principals_with_readonly_permissions)}] for schema with name ${var.schema_name}"
  }
}
