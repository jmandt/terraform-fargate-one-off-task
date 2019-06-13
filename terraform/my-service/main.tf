################################################################################
# Terraform base configs
################################################################################

provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  required_version = "= 0.11.14"
  backend          "s3"             {}
}

data "aws_caller_identity" "current" {}

################################################################################
# Remote VPC
################################################################################

data "terraform_remote_state" "base_vpc" {
  backend = "s3"

  config {
    bucket = "${var.generic_terraform_backend_bucket}"
    key    = "${var.path_to_state_file}.tfstate"
    region = "${var.aws_region}"
  }
}

################################################################################
# Fargate Cluster
################################################################################

resource "aws_ecs_cluster" "fargate_cluster" {
  name = "${var.environment}-${var.project}-${var.ecs_cluster_name}"

  tags {
    Environment = "${var.environment}"
    Project     = "${var.project}"
    Name        = "${var.ecs_cluster_name}"
  }

}



################################################################################
# Fargate services
################################################################################


data "template_file" "service_app_tpl" {
  template            = "${file("${path.module}/../templates/my_service.json.tpl")}"

  vars {
    container_name    = "${var.application_name}-container"

    container_image   = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-1.amazonaws.com/${var.application_name}:latest"
    container_cpu     = "${var.container_cpu}"
    container_memory  = "${var.container_memory}"
    aws_region        = "${var.aws_region}"
    container_port    = "5000"
    environment       = "${var.environment}"
    application_name  = "${var.application_name}"
  }
}

module "terraform-module-aws-fargate-one-off" {
  source                            = "git::ssh://git@github.com:jmandt/terraform-one-off-task-module.git"

  # meta
  environment                       = "${var.environment}"
  project                           = "${var.project}"
  team                              = "${var.team}"
  application_name                  = "${var.application_name}"

  ecs_cluster_id                    = "arn:aws:ecs:eu-west-1:${data.aws_caller_identity.current.account_id}:cluster/${aws_ecs_cluster.fargate_cluster.name}"
  ecs_cluster_name                  = "${aws_ecs_cluster.fargate_cluster.name}"
  account_id                        = "${data.aws_caller_identity.current.account_id}"


  # network
  task_subnet_ids                   = "${data.terraform_remote_state.base_vpc.private_subnet_ids}"
  vpc_id                            = "${data.terraform_remote_state.base_vpc.vpc_id}"

  # service
  task_revision                     = "${var.task_revision}"
  rendered_fargate_container_def    = "${data.template_file.service_app_tpl.rendered}"
  task_memory                       = "${var.container_memory}"
  task_cpu                          = "${var.container_cpu}"
  log_retention_period              = "${var.log_retention_period}"

}

resource "aws_cloudwatch_event_rule" "run-my-service-event-rule" {
  name                = "run-my-service"
  description         = "Starts a new task on AWS ECS FARGATE which runs my service"
  schedule_expression = "rate(3 minutes)"
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id               = "${var.application_name}-task-definition"
  arn                     = "${aws_ecs_cluster.fargate_cluster.arn}"
  rule                    = "${aws_cloudwatch_event_rule.run-my-service-event-rule.name}"
  role_arn                = "${aws_iam_role.ecs_events.arn}"

  ecs_target = {
    launch_type           = "FARGATE"
    task_count            = 1
    platform_version      = "LATEST"
    task_definition_arn   = "arn:aws:ecs:eu-west-1:${data.aws_caller_identity.current.account_id}:task-definition/${var.application_name}:${var.task_revision}"
    network_configuration = {
      subnets             = ["${split(",", data.terraform_remote_state.base_vpc.private_subnet_ids)}"]
      assign_public_ip    = true
      security_groups     = ["${module.terraform-module-aws-fargate-one-off.aws_security_group_task_sg_id}"]
    }
  }
}


resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name = "ecs_events_run_task_with_any_role"
  role = "${aws_iam_role.ecs_events.id}"
  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "*"
        }
    ]
}
DOC
}

resource "aws_iam_role" "ecs_events" {
  name = "ecs_events"
  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}