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

variable "groups_with_elevated_permissions" {
  description = "List of Databricks groups that will be given the ALL permission on the schema. Restricted to `-Admin` and `-Sec` groups."
  type        = set(string)
  default     = []

  // check that only groups with the -Admin or -Sec suffix can be given ALL_PRIVILEGES on a schema
  validation {
    condition     = length(regexall("-Admin|-Sec", join("", var.groups_with_elevated_permissions))) == length(var.groups_with_elevated_permissions)
    error_message = "Only groups with the '-Admin' or '-Sec' suffix can be given elevated permissions.\nCurrent values are: [${join(", ", var.groups_with_elevated_permissions)}]"
  }

  // check that schemas of which the name ends with `sec` can only get permissions from groups with `-Sec` suffix
  validation {
    condition     = length(regexall("sec$", var.schema_name)) == 0 || length(regexall("-Sec", join("", var.groups_with_elevated_permissions))) == length(var.groups_with_elevated_permissions)
    error_message = "On schemas with the 'sec' suffix, only groups with the '-Sec' suffix in the name can be given permissions .\nCurrent values are: [${join(", ", var.groups_with_elevated_permissions)}] for schema with name ${var.schema_name}"
  }

  // check that values for group names are not also present in other principal assignment groups
  validation {
    condition     = length(setunion(var.groups_with_elevated_permissions, var.groups_with_modify_permissions, var.groups_with_readonly_permissions)) == sum([length(var.groups_with_elevated_permissions), length(var.groups_with_modify_permissions), length(var.groups_with_readonly_permissions)])
    error_message = "Groups can only be present in a single permissions assignment group.\nGroup names in the elevated permissions assignment group are: [${join(", ", var.groups_with_elevated_permissions)}]\nGroup names in the Modify permissions assignment group are: [${join(", ", var.groups_with_modify_permissions)}]\nGroup names in the Read Only permissions assignment group are: [${join(", ", var.groups_with_readonly_permissions)}]"
  }
}

variable "groups_with_modify_permissions" {
  description = "List of Databricks groups that will be given the permission to read and modify the schema"
  type        = set(string)
  default     = []

  // check that schemas of which the name ends with `sec` can only get permissions from groups with `-Sec` suffix
  validation {
    condition     = length(regexall("sec$", var.schema_name)) == 0 || length(regexall("-Sec", join("", var.groups_with_modify_permissions))) == length(var.groups_with_modify_permissions)
    error_message = "On schemas with the 'sec' suffix, only groups with the '-Sec' suffix in the name can be given permissions .\nCurrent values are: [${join(", ", var.groups_with_modify_permissions)}] for schema with name ${var.schema_name}"
  }

  // check that groups with the Readonly suffix cannot be given MODIFY permissions on a schema
  validation {
    condition     = length(regexall("Readonly$", join("", var.groups_with_modify_permissions))) == 0
    error_message = "Groups with the 'Readonly' suffix cannot be given MODIFY permissions on a schema.\nCurrent values are: [${join(", ", var.groups_with_modify_permissions)}]"
  }
}

variable "groups_with_readonly_permissions" {
  description = "List of Databricks groups that will be given read only permission on the schema"
  type        = set(string)
  default     = []

  // check that schemas of which the name ends with `sec` can only get permissions from groups with `-Sec` or `-Sec_Readonly` suffix
  validation {
    condition     = length(regexall("sec$", var.schema_name)) == 0 || length(regexall("-Sec|-Sec_Readonly", join("", var.groups_with_readonly_permissions))) == length(var.groups_with_readonly_permissions)
    error_message = "On schemas with the 'sec' suffix, only groups with the '-Sec' or '-Sec_Readonly` suffix in the name can be given permissions.\nCurrent values are: [${join(", ", var.groups_with_readonly_permissions)}] for schema with name ${var.schema_name}"
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

variable "additional_permissions" {
  description = "Additional permissions to be given to specific groups on the schema"
  type        = map(list(string))
  default     = {}

  // check that the additional permissions in the list(string) belong to a predefined list of permissions
  validation {
    condition     = length(setsubtract(toset(flatten([for _, values in var.additional_permissions : [values]])), ["APPLY_TAG", "CREATE_FUNCTION", "CREATE_MATERIALIZED_VIEW", "CREATE_TABLE", "EXECUTE", "READ_VOLUME", "SELECT"])) == 0
    error_message = "Additional permissions can only be one of the following: APPLY_TAG, CREATE_FUNCTION, CREATE_MATERIALIZED_VIEW, CREATE_TABLE, EXECUTE, READ_VOLUME, SELECT.\nConflicting values are: [${join(", ", tolist(setsubtract(toset(flatten([for _, values in var.additional_permissions : [values]])), ["APPLY_TAG", "CREATE_FUNCTION", "CREATE_MATERIALIZED_VIEW", "CREATE_TABLE", "EXECUTE", "READ_VOLUME", "SELECT"])))}]"
  }

  // group names with a Readonly suffix cannot be given additional permissions
  validation {
    condition     = length(regexall("Readonly$", join("", keys(var.additional_permissions)))) == 0
    error_message = "Groups with a 'Readonly' suffix cannot be given additional permissions.\nCurrent values are: [${join(", ", keys(var.additional_permissions))}]"
  }
}
