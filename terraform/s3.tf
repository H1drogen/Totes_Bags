resource "aws_s3_bucket" "data_ingestion" {
    bucket_prefix = "totes-data-"

    tags = {
        Name ="DataIngestionBucket"
        Environment = "Extract"
    }
}

resource "aws_s3_bucket" "code_bucket" {
    bucket_prefix = "totes-lambda-code-"

    tags = {
        Name = "LambdaCodeBucket"
        Environment = "Extract"
    }
}

# resource "aws_s3_bucket" "state_bucket" {
#     bucket = "terraform-state-bucket-for-sidley"

#     tags = {
#       Environment = "Production"
#     }
# }

# resource "aws_s3_object" "upload_state" {
#   bucket       = "${aws_s3_bucket.state_bucket.id}"
#   acl          = "private"
#   key          = "terraform.tfstate"
#   source       = "terraform.tfstate"
#   content_type = "application/json"
#   depends_on = [
#     aws_s3_bucket.state_bucket,
#   ]
# }

terraform {
    backend "s3" {
        bucket = "terraform-state-bucket-for-sidley"
        key = "terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_ingestion_lifecycle" {
    bucket = aws_s3_bucket.data_ingestion.id

    rule {
        id ="TransitionToInfrequentAccess"
    filter {
        prefix = ""
    }
    transition {
        days = 30
        storage_class = "STANDARD_IA"
    }

    expiration {
        days = 90
    }

    status = "Enabled"
    }
}



resource "aws_s3_bucket_policy" "data_ingestion_policy" {
    bucket = aws_s3_bucket.data_ingestion.id

    policy = <<EOF
{
"Version": "2012-10-17",
    "Statement": [
    {
        "Sid": "AllowPublicRead",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::${aws_s3_bucket.data_ingestion.id}/*",
        "Condition": {
        "IpAddress": {
            "aws:SourceIp": "192.168.0.0/16"
        }
    }
    }
  ]
}
EOF
}
