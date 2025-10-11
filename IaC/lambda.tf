
# ---------------------------------------------------------
# --- IAM ROLE ---
# ---------------------------------------------------------

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ---------------------------------------------------------
# --- LAMBDA 1: RAW -> TRUSTED ---
# ---------------------------------------------------------

data "archive_file" "lambda_tratamento_zip" {
  type        = "zip"
  source_file = "02tratamento_lambda.py"
  output_path = "02tratamento_lambda.zip"
}

resource "aws_lambda_function" "tratamento_lambda" {
  function_name    = "LambdaTratamentoBeiraMar"
  handler          = "02tratamento_lambda.lambda_handler"
  role             = data.aws_iam_role.lab_role.arn
  filename         = data.archive_file.lambda_tratamento_zip.output_path
  source_code_hash = data.archive_file.lambda_tratamento_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 512
  layers           = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python312:19"]
  
  environment {
    variables = {
      BUCKET_RAW     = aws_s3_bucket.raw.id
      BUCKET_TRUSTED = aws_s3_bucket.trusted.id
    }
  }
}

# ---------------------------------------------------------
# --- LAMBDA 2: TRUSTED -> REFINED ---
# ---------------------------------------------------------

data "archive_file" "lambda_refined_zip" {
  type        = "zip"
  source_file = "03refined_lambda.py"
  output_path = "03refined_lambda.zip"
}

resource "aws_lambda_function" "refined_lambda" {
  function_name    = "LambdaRefinedBeiraMar"
  handler          = "03refined_lambda.lambda_handler"
  role             = data.aws_iam_role.lab_role.arn
  filename         = data.archive_file.lambda_refined_zip.output_path
  source_code_hash = data.archive_file.lambda_refined_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 600
  memory_size      = 1024
  layers           = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python312:19"]
  
  environment {
    variables = {
      BUCKET_TRUSTED = aws_s3_bucket.trusted.id
      BUCKET_REFINED = aws_s3_bucket.refined.id
    }
  }
}
