# Fetches your current AWS account ID to build the Snowflake role ARN.
data "aws_caller_identity" "current" {}

locals {
  snowflake_role_name = "ahcs-snowflake-role"
  snowflake_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.snowflake_role_name}"
}

resource "aws_iam_role" "snowflake_role" {
  name = local.snowflake_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = snowflake_storage_integration_aws.achs_s3_integration.describe_output[0].iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = snowflake_storage_integration_aws.achs_s3_integration.describe_output[0].external_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "snowflake_role_policy" {
  name = "snowflake-access-policy"
  role = aws_iam_role.snowflake_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ],
        "Resource" : "arn:aws:s3:::angel-city-health-data/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : "arn:aws:s3:::angel-city-health-data",
        "Condition" : {
          "StringLike" : {
            "s3:prefix" : ["*"]
          }
        }
      }
    ]
  })
}
