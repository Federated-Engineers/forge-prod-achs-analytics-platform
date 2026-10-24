terraform {
  backend "s3" {
    bucket = "federated-production-achs-project-dubem-achs-prod-tfstate"
    key    = "production/forge/terraform.tfstate"
    region = "eu-central-1"
  }
}
