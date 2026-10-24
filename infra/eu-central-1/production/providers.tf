terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    snowflake = {
      source = "snowflakedb/snowflake"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "snowflake" {
  organization_name        = local.snowflake_tags.organization
  account_name             = local.snowflake_tags.account
  user                     = "TERRAFORM_SVC"
  role                     = "SYSADMIN"
  preview_features_enabled = ["snowflake_table_resource"]
}

# will be used to manage Snowflake users and roles via the USERADMIN role
provider "snowflake" {
  organization_name = local.snowflake_tags.organization
  account_name      = local.snowflake_tags.account
  user              = "TERRAFORM_SVC"
  role              = "USERADMIN"
  alias             = "useradmin"
}