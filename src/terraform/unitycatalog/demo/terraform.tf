# Configure required providers
terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.59.0"
    }
  }

  required_version = ">=1.8.5"
}

# Setup databricks provider using resolved workspace url
provider "databricks" {
  host = "https://adb-1620444042178903.3.azuredatabricks.net/"
}
