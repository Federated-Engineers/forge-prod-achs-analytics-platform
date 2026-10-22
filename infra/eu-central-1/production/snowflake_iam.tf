# Fetches your current AWS account ID to use in the temporary trust policy
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "snowflake_role" {
  name = "snowflake-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Temporarily trust AWS account
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "0000"
          }
        }
      }
    ]
  })

  # Prevent Terraform from reverting the CLI override
  lifecycle {
    ignore_changes = [assume_role_policy]
  }
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

resource "null_resource" "update_snowflake_trust_policy" {
  # Explicit dependency ensures execution order
  depends_on = [snowflake_storage_integration_aws.achs_s3_integration]

  # Re-runs the script only if the integration object changes
  triggers = {
    integration_id = snowflake_storage_integration_aws.achs_s3_integration.id
  }

  provisioner "local-exec" {
    command = <<EOT
      aws iam update-assume-role-policy \
        --role-name ${aws_iam_role.snowflake_role.name} \
        --policy-document '${jsonencode({
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
})}'
    EOT
}
}

