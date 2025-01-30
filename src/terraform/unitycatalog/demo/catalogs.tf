locals {
  test_catalog_name = lower("westeurope_test_${var.environment}")
}

module "test_catalog" {
  source = "../modules/catalog"

  catalog_name                           = local.test_catalog_name
  environment                            = var.environment
  groups_with_use_catalog_permission     = ["${var.group_prefix}-DE", "${var.group_prefix}-Readonly"]
  principals_with_use_catalog_permission = ["bi-${var.environment}", "job-${var.environment}"]
}
