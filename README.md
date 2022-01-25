# finlex
Please find the documentation below

## The Application
The application name is `aap.py` and located under `application` directory. It is a docker based web application developed with Python Flask framework. The application listen on port 5000 and reponds to any `/version` http endpoint by displying the current API version.

Command to build the docker image:
```
sudo docker build -t finlex:latest .
```

Command to run the docker container:
```
sudo docker run -d -p 5000:5000 finlex
```

Command to check the docker container:
```
[ec2-user@ip-172-31-35-251 finlex]$ sudo docker ps
CONTAINER ID   IMAGE     COMMAND            CREATED      STATUS      PORTS                                       NAMES
967cea226cef   finlex    "python3 app.py"   1 days ago   Up 1 days   0.0.0.0:5000->5000/tcp, :::5000->5000/tcp   happy_swanson
```

Command to test the `/version` http endpoint:
```
[ec2-user@ip-172-31-35-251 finlex]$ curl http://localhost:5000/version
API version: 1.0.1
```


## The Deployment
The infrastructure is build using terraform. All the terraform code is located under `infra` directory. A tree structure of the terraform code directory is shown below:
```
infra/
├── modules
│   ├── ecr
│   │   ├── outputs.tf
│   │   ├── resources.tf
│   │   └── variables.tf
│   └── ecs_cluster
│       ├── outputs.tf
│       ├── resources.tf
│       └── variables.tf
├── providers.tf
└── resources.tf
```

The `module` directory contains re-usuable terraform codes. To set up up the infrastructure, we have used TWO modules: 
- `ecr` - To provision a AWS ECR repository to store the application docker image.
- `ecs_cluster` - To setup AWS ECS cluster. This module creates:

```
Application Load Balancer
Application Load Balancer Listner
Application Load Balancer Target Group
Security Group
Route53 Record
ECS Cluster
ECS Task Definition
ECS Service
```

To reduce downtime during new deployment, terraform lifecycle policy has been used with flag `create_before_destroy = true`.


## The Decumentation

- What a real life deployment would need extra?
  - The image building and pushing to AWS ECR repo should be automated using CI-CD pipeline. For example using Github Actions or Jenkins.
  - The newly build application image should be automatically scanned for vulnerabilities by using AWS ECR in-built scanning feature.
  - Proper test cases should be defined as part of the CI-CD pipeline to test the newly deployed feature of the application.  
- What can be improved upon?
  - Sometimes changing/modifying the ECS task definition outside of terraform may be required(e.g. through AWS console or Jenkins etc). In such cases, `ignore_changes` flag can be used through terraform lifecycle policy block.
  -  Code analysis tool like Sonarqube can be integrated with the CI-CD pipeline to provide continuous inspection of the code to highlight existing and newly introduced issues.
  -  Terraform satte file should be stored remotely(e.g. in S3 bucket) by configuring `backend`.
