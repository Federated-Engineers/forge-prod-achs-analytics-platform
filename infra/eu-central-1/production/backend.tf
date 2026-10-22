terraform {
  backend "s3" {
    bucket = "dubem-achs-prod-tfstate"
    key    = "production/forge/terraform.tfstate"
    region = "eu-central-1"
  }
}
