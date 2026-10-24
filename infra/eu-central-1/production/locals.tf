locals {
  common_tags = {
    environment = var.environment
    team        = var.team
    terraform   = true
  }

  snowflake_tags = {
    organization = "fncwxve"
    account      = "uu56570"
  }

  raw_tables = toset(["PATIENTS", "PROVIDERS", "CLAIMS", "ENCOUNTERS", "DIAGNOSES"])
}

