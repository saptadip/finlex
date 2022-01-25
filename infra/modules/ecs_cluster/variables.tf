variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC id"
}


variable "dns_record_name" {
  type        = string
  description = "DNS record name"
}


variable "dns_zone_name" {
  type        = string
  description = "DNS zone name"
}


variable "autoscaling_group_name" {
  type        = string
  description = "Autoscaling group name"
}


variable "cpu" {
  type        = string
  description = "CPU limit in task difinition"
}


variable "memory" {
  type        = string
  description = "Memory limit in task difinition"
}


variable "tag" {
  type        = string
  description = "Tags"
}


variable "container_name" {
  type        = string
  description = "ECS Container Name"
}


variable "container_port" {
  type        = string
  description = "ECS Container Port"
}


variable "dns_record_name" {
  type        = string
  description = "DNS record name"
}


variable "fargate_platform_version" {
  type        = string
  description = "Fargate Platform version"
}

variable "srvc_name" {
  type        = string
  description = "ECS Service Name"
}
