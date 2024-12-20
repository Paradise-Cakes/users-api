locals {
  lambda_image = "${data.aws_ecr_repository.users_api_lambdas.repository_url}:${var.docker_image_tag}"
}

resource "aws_lambda_function" "app" {
  image_uri     = local.lambda_image
  package_type  = "Image"
  function_name = "users-api-us-east-1"
  role          = aws_iam_role.users_api_role.arn

  timeout     = 30
  memory_size = 1024

  image_config {
    command = ["src.api.lambda_handler"]
  }

  environment {
    variables = {
      REGION                = "us-east-1"
      COGNITO_APP_CLIENT_ID = aws_cognito_user_pool_client.paradise_cakes_client.id
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.paradise_cakes_user_pool.id
    }
  }
}

resource "aws_lambda_function" "customize_emails_trigger" {
  image_uri     = local.lambda_image
  package_type  = "Image"
  function_name = "customize-emails-trigger"
  role          = aws_iam_role.users_api_role.arn

  image_config {
    command = ["src.customize_emails_trigger.handler.lambda_handler"]
  }

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      REGION = "us-east-1"
    }
  }
}

resource "aws_lambda_permission" "allow_cognito_invocation" {
  statement_id  = "AllowCognitoInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.customize_emails_trigger.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.paradise_cakes_user_pool.arn
}


