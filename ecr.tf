#################################################################################################
# This file describes the ECR resources: ECR repo, ECR policy, resources to build and push image
#################################################################################################

#Creation of the ECR repo
resource "aws_ecr_repository" "ecr" {
    name                            = "${random_string.string.id}-repo"
}

#The ECR policy describes the management of images in the repo
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
    repository                      = aws_ecr_repository.ecr.name
    policy                          = local.ecr_policy
}

#This is the policy defining the rules for images in the repo
locals {
  ecr_policy = jsonencode({
        "rules":[
            {
                "rulePriority"      : 1,
                "description"       : "Expire images older than 14 days",
                "selection": {
                    "tagStatus"     : "any",
                    "countType"     : "sinceImagePushed",
                    "countUnit"     : "days",
                    "countNumber"   : 3
                },
                "action": {
                    "type"          : "expire"
                }
            }
        ]
    })
}

#The commands below are used to build and push a docker image of the application in the app folder
locals {
  docker_login_command              = "aws ecr get-login-password --region ${var.region} --profile ${var.credential_profile}| docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  docker_build_command              = "docker build -t ${aws_ecr_repository.ecr.name} ./app"
  docker_tag_command                = "docker tag ${aws_ecr_repository.ecr.name}:latest ${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.ecr.name}:latest"
  docker_push_command               = "docker push ${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.ecr.name}:latest"
  clean_up_ecr                      = "./batch_delete_image.sh ${var.region} ${aws_ecr_repository.ecr.name}"
}

#This resource authenticates you to the ECR service
resource "null_resource" "docker_login" {
    provisioner "local-exec" {
        command                     = local.docker_login_command
    }
    triggers = {
        "run_at"                    = timestamp()
    }
    depends_on                      = [ aws_ecr_repository.ecr ]
}

#This resource builds the docker image from the Dockerfile in the app folder
resource "null_resource" "docker_build" {
    provisioner "local-exec" {
        command                     = local.docker_build_command
    }
    triggers = {
        "run_at"                    = timestamp()
    }
    depends_on                      = [ null_resource.docker_login ]
}

#This resource tags the image 
resource "null_resource" "docker_tag" {
    provisioner "local-exec" {
        command                     = local.docker_tag_command
    }
    triggers = {
        "run_at"                    = timestamp()
    }
    depends_on                      = [ null_resource.docker_build ]
}

#This resource pushes the docker image to the ECR repo
resource "null_resource" "docker_push" {
    provisioner "local-exec" {
        command                     = local.docker_push_command
    }
    triggers = {
        "run_at"                    = timestamp()
    }
    depends_on                      = [ null_resource.docker_tag ]
}

#This resource flushes tasks for replacement
resource "terraform_data" "flush_task" {
      triggers_replace = [ null_resource.docker_tag ]

  provisioner "local-exec" {
    command = "./flush_tasks.sh"
    interpreter = ["/bin/bash", "-c"]
    on_failure  = continue
    environment = { region = var.region,
                    cluster = aws_ecs_cluster.ecs_cluster.name,
                    }
  }
}

resource "null_resource" "cleanup_ecr" {
  triggers = {
    command             = local.clean_up_ecr
  }

  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.command
    interpreter = ["/bin/bash", "-c"]

  }
}