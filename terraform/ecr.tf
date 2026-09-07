resource "aws_ecr_repository" "app" {
  name                 = "devops-bootcamp/final-project-${var.student_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Bootcamp convenience: lets `terraform destroy` delete the repo even when
  # images are still in it. Drop this in anything you'd run for real.
  force_delete = true

  tags = { Name = "devops-bootcamp-final-project" }
}
