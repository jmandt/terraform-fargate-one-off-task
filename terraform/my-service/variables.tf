
variable "aws_region" {
  description = "Region to deploy the stack"
  default     = "eu-west-1"
}

variable "generic_terraform_backend_bucket" {
  description = "S3 bucket where terraform state files are saved"
  default = "your_remote_state_bucket"
}

variable "path_to_state_file" {
  default = "path/to/your/current/statefile"
}

variable "environment" {
  description = "Environment of the Stack, designates if resources are used in development/staging/production context. Available options: [dev, stg, prd]"
}

variable "project" {
  description = "Specify to which project this resource belongs. It should be the same terraform environment directory name"
  default = "your-project-name"
}

#Fargate Cluster
variable "ecs_cluster_name" {
  default="fargate-cluster"
}

################################################################################
# Fargate services
################################################################################

variable "container_memory" {
  default = "8192"
}

variable "container_cpu" {
  default = "4096"
}

variable "application_name" {
  default ="my-service"
}

variable "team" {
  default = "your-team-name"
}

variable "log_retention_period" {
  default = "5"
}

variable "task_revision" {
  default = "1"
}
