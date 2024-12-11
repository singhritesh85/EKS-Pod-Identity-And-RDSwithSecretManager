############################################################################################################################
#                                                    Aws Lambda Function                                                   # 
############################################################################################################################

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 0        ###   Cloudwatch Log Group will never expire
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam-role-for-lambda-autorotate"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
       {
         "Action": "sts:AssumeRole",
         "Principal": {
            "Service": [
                         "lambda.amazonaws.com"
            ]
         },
         "Effect": "Allow"
       }
    ]
  })
}

### IAM inline policy for secret rotaton and logging from lambda
resource "aws_iam_role_policy" "lambda_logging_autorotate" {
  name        = "secret-rotation-policy"  
  role        = aws_iam_role.iam_for_lambda.id 

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
       {
         "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
         ],
         "Resource": "arn:aws:logs:*:*:*",
         "Effect": "Allow"
       },
       {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:PutSecretValue",
                "secretsmanager:UpdateSecretVersionStage"
            ],
            "Resource": "${aws_secretsmanager_secret.aws_secrets.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetRandomPassword"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DetachNetworkInterface"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]  
  }) 

   depends_on = [aws_secretsmanager_secret.aws_secrets]
}

resource "aws_lambda_function" "demo_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "lambda_function_payload.zip"
  handler       = "lambda_function_payload.lambda_handler"

  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = var.runtime

  tags = {
    Environment = "${var.env}"
  }

  depends_on = [
    aws_cloudwatch_log_group.cloudwatch_loggroup
  ]
}

############################################################################################################################
#                                                    Aws Secrets Manager                                                   #
############################################################################################################################

resource "random_password" "random_pass" {
  length  = 20
  special = true
  numeric = true
  upper   = true
  lower   = true
}

resource "aws_secretsmanager_secret" "aws_secrets" {
  name = "aws-secrets-${var.env}"
}

resource "aws_secretsmanager_secret_version" "secretversion" {
  secret_id = aws_secretsmanager_secret.aws_secrets.id
  secret_string = <<EOF
   {
    "username": "admin",
    "password": "${random_password.random_pass.result}"
   }
EOF
}

resource "aws_secretsmanager_secret_rotation" "rotate_secret" {
  secret_id           = aws_secretsmanager_secret.aws_secrets.id
  rotation_lambda_arn = aws_lambda_function.demo_lambda.arn

  rotation_rules {
    automatically_after_days = 10  ### Rotate Secret after 10 days
  }

  depends_on = [aws_lambda_function.demo_lambda]

}

resource "aws_lambda_permission" "secretmanager_invoke_lambda" {
  statement_id  = "AllowSecretsManagerToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
}
