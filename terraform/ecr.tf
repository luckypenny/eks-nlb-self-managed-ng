resource "aws_ecr_repository" "flask-app" {
  name = "flask-app"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "FLASK_APP_ECR_URL" {
  value = aws_ecr_repository.flask-app.repository_url
}