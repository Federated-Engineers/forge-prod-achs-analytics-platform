resource "snowflake_table" "raw_tables" {
  for_each = local.raw_tables

  database = snowflake_database.achs_analytics.name
  schema   = snowflake_schema.staging.name
  name     = "${each.key}_RAW"
  comment  = "Raw ${lower(each.key)} JSON landing table"

  column {
    name = "RAW_JSON"
    type = "VARIANT"
  }

  column {
    name = "SOURCE_FILE_NAME"
    type = "VARCHAR"
  }

  column {
    name = "LOADED_AT"
    type = "TIMESTAMP_LTZ"

    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}
