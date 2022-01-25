provider "aws" {
  region = "eu-central-1"
}


#Cretae ECR Repository
module "ecr-repo" {
  source        = "modules/ecr"
  ecr_repo_name = "finlex_api_repo"
}


#Create ECS Cluster
module "ecs-cluster" {
  source                 = "modules/ecs_cluster"
  ecs_cluster_name       = "finlex-cluster"
  vpc_id                 = "finlex-vpc-id-xxxxxx"
  dns_record_name        = "finlex-sample-record-name"
  dns_zone_name          = "finlex-sample-zone-name"
  autoscaling_group_name = "finlex-asg"
  cpu                    = "1024"
  memory                 = "2048"
  container_name         = "finlex-app-container"
  container_port         = "5000"
  srvc_name              = "finlex-srvc"
  imageName              = "finlex-app-name"
  imageNameUrl           = "Image URL from the AWS ECR"
}

