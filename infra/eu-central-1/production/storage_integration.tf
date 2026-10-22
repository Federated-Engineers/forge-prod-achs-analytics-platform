resource "snowflake_storage_integration_aws" "achs_s3_integration" {
  name             = "ACHS_S3_INTEGRATION"
  comment          = "Storage integration for ACHS raw JSON dumps"
  enabled          = true
  storage_provider = "S3"
  storage_aws_role_arn      = local.snowflake_role_arn
  storage_allowed_locations = ["s3://angel-city-health-data/"]
}

resource "snowflake_file_format_json" "json_format" {
  name              = "ACHS_JSON_FORMAT"
  database          = snowflake_database.achs_analytics.name
  schema            = snowflake_schema.staging.name
  strip_outer_array = true
}

resource "snowflake_stage_external_s3" "achs_s3_stage" {
  name                = "ACHS_RAW_DATA_STAGE"
  database            = snowflake_database.achs_analytics.name
  schema              = snowflake_schema.staging.name
  storage_integration = snowflake_storage_integration_aws.achs_s3_integration.name
  url                 = "s3://angel-city-health-data/"
  comment             = "Fully configured S3 external stage"
}