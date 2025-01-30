module "test__demo_1_schema" {
  source = "../modules/schema"

  catalog_name = local.test_catalog_name
  schema_name  = "demo_schema_1"

  groups_with_modify_permissions       = ["${var.group_prefix}-DE"]
  groups_with_readonly_permissions     = ["${var.group_prefix}-Readonly"]
  principals_with_readonly_permissions = ["bi-${var.environment}"]
}

module "test__demo_2_schema" {
  source = "../modules/schema"

  catalog_name = local.test_catalog_name
  schema_name  = "demo_schema_2"

  groups_with_modify_permissions       = ["${var.group_prefix}-DE"]
  groups_with_readonly_permissions     = ["${var.group_prefix}-Readonly"]
  principals_with_modify_permissions   = ["job-${var.environment}"]
  principals_with_readonly_permissions = ["bi-${var.environment}"]
}
