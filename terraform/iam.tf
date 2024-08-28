resource "aws_iam_role" "lambda_role" {
    name_prefix        = "role-totes-lambdas-"
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

data "aws_iam_policy_document" "s3_document" {
    statement {
    actions = ["s3:PutObject",]
    resources = ["${aws_s3_bucket.data_ingestion.arn}/*"]
    }
    statement {
    actions = ["s3:ListAllMyBuckets", "s3:ListBucket"]
	resources =  ["*"]
    }
}

data "aws_iam_policy_document" "cloudwatch_logs_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

data "aws_iam_policy_document" "secrets_manager_document" {
    statement {

    actions = ["secretsmanager:GetSecretValue",
				"secretsmanager:DescribeSecret"]

    resources = [
        "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:totesys_db-*",
    ]
  }
}

data "aws_iam_policy_document" "cw_document" {
  statement {

    actions = ["logs:CreateLogGroup"]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {

    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*:*"
    ]
  }
}




resource "aws_iam_policy" "s3_policy" {
    name_prefix = "s3-policy-totes-lambda-"
    policy      = data.aws_iam_policy_document.s3_document.json
}

resource "aws_iam_policy" "secrets_manager_policy" {
    name_prefix = "secrets-manager-policy-totes-lambda-"
    policy      = data.aws_iam_policy_document.secrets_manager_document.json
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name_prefix = "cloudwatch-logs-policy-totes-lambda-"
  policy      = data.aws_iam_policy_document.cloudwatch_logs_policy_document.json
}

resource "aws_iam_policy" "cw_policy" {
  name_prefix = "cw-policy-totes-lambda-"
  policy      = data.aws_iam_policy_document.cw_document.json
}





resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_policy_attachment" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cw_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cw_policy.arn
}


resource "aws_lambda_permission" "allow_s3_data_to_trigger_transform" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_transform.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_ingestion.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_uploaded_to_data_ingestion" {
  bucket = aws_s3_bucket.data_ingestion.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.task_transform.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_data_to_trigger_transform]
}



resource "aws_lambda_permission" "allow_s3_processed_to_trigger_load" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_load.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.processed_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_uploaded_to_data_processed" {
  bucket = aws_s3_bucket.processed_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.task_load.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_processed_to_trigger_load]
}
