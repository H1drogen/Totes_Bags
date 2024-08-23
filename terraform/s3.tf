resource "aws_s3_bucket" "data_ingestion" {
    bucket_prefix = "totes-data-"
    force_destroy = true

    tags = {
        Name ="DataIngestionBucket"
        Environment = "Extract"
    }
}

resource "aws_s3_bucket" "data_transform" {
    bucket_prefix = "totes-processed-data-"
    force_destroy = true

    tags = {
        Name ="DataTransformBucket"
        Environment = "Transform"
    }
}

resource "aws_s3_bucket" "code_bucket" {
    bucket_prefix = "totes-lambda-code-"
    force_destroy = true

    tags = {
        Name = "LambdaCodeBucket"
        Environment = "Production"
    }
}

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

resource "aws_s3_object" "lambda_layer" {
  bucket = aws_s3_bucket.code_bucket.bucket
  key    = "layer/layer.zip"
  source = data.archive_file.layer_code.output_path
  source_hash = data.archive_file.layer_code.output_base64sha256
  depends_on = [ data.archive_file.layer_code ]
}