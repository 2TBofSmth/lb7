provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3     = "http://localhost:4566"
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "start" {
  bucket = "s3-start"
}

resource "aws_s3_bucket" "finish" {
  bucket = "s3-finish"
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.start.id

  rule {
    id     = "expire-objects"
    status = "Enabled"
    expiration {
      days = 7
    }
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "copy_lambda" {
  function_name = "copy_lambda"
  filename      = data.archive_file.lambda_zip.output_path
  handler       = "handler.handler"
  runtime       = "python3.9"
  role          = "arn:aws:iam::000000000000:role/lambda-role"
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.copy_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.start.arn
}

resource "aws_s3_bucket_notification" "trigger_lambda" {
  bucket = aws_s3_bucket.start.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.copy_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
