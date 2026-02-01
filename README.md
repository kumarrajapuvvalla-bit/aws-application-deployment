# AWS Application Deployment Demo

This repository contains a sample Node.js web application and
infrastructure definitions that demonstrate how to deploy a container
application to Amazon Web Services (AWS).  The project uses
Infrastructure as Code to provision resources and includes a Jenkins
pipeline for continuous integration and delivery.

## Overview

The solution comprises the following components:

- **Application** – a simple Express web app that returns a welcome
  message and exposes a health‑check endpoint.
- **Containerisation** – a `Dockerfile` builds a lightweight Node
  image suitable for deployment to AWS.
- **Infrastructure as Code** – Terraform scripts create an Amazon ECR
  repository for storing container images, a security group, and an EC2
  instance that pulls and runs the image.  You can adjust these
  resources to target other services like ECS or Elastic Beanstalk.
- **CI/CD pipeline** – a Jenkinsfile defines steps to build the app,
  push the Docker image to ECR, and trigger a deployment.  You can
  integrate with AWS CodeDeploy or use SSH to restart the container on
  the EC2 instance.

## Architecture

1. **Build Phase:** The Jenkins pipeline checks out the repository,
   installs dependencies, builds a Docker image, and pushes it to
   Amazon ECR.
2. **Deployment Phase:** An EC2 instance is provisioned by Terraform
   with user data to install Docker, log in to ECR, pull the image
   tagged `latest`, and run it as a container.  The instance resides
   in the default VPC and is accessible over HTTP on port 80.
3. **Optional Automation:** You can extend the pipeline to
   automatically redeploy the updated container on the instance (for
   example via AWS CodeDeploy, SSM Run Command, or remote SSH).

## Getting Started

### Prerequisites

* **AWS Account** with permission to create ECR repositories, EC2
  instances, and security groups.
* **Terraform** installed locally.
* **Docker** and **Node.js** if you want to build and run the
  application outside AWS.
* **A Key Pair** – specify the key name via `var.key_name` when
  running Terraform to enable SSH access to the EC2 instance.

### Running Locally

```bash
cd app
npm install
npm start
```

Visit `http://localhost:3000` to confirm the service is running.

### Building the Docker image

```bash
docker build -t aws-app-demo:latest .
docker run -p 3000:3000 aws-app-demo:latest
```

### Provisioning AWS Infrastructure

The `iac/terraform` directory contains Terraform configuration for
creating:

* An ECR repository (`aws_ecr_repository.app`)
* A security group that allows HTTP and SSH access
* An EC2 instance configured via user data to run the container

Before applying the configuration, set the `key_name` variable to the
name of an existing EC2 Key Pair.  Optionally override the region.

```bash
cd iac/terraform
terraform init
terraform plan -var="key_name=my-key" -out plan.tfplan
terraform apply plan.tfplan
```

Terraform outputs the ECR repository URL and the public IP of the EC2
instance.  After pushing your image (see below) the instance will
automatically pull and run it.

### Pushing the Image to ECR

To push the container image to the ECR repository created by
Terraform, authenticate to ECR and tag the image appropriately:

```bash
AWS_REGION=us-east-1
ECR_URL=$(aws ecr describe-repositories --repository-names aws-app-deployment-demo --query 'repositories[0].repositoryUri' --output text)
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"
docker tag aws-app-demo:latest "$ECR_URL:latest"
docker push "$ECR_URL:latest"
```

The EC2 instance’s user data script logs in to ECR and runs the image
on port 80.  If you prefer to use ECS, Fargate, or EKS, replace the
EC2 resources in the Terraform configuration with the appropriate
modules.

### Jenkins Pipeline

The `ci-cd/Jenkinsfile` provides a declarative pipeline that can be
imported into Jenkins.  It performs the following steps:

1. **Checkout** the repository.
2. **Install dependencies** using `npm install`.
3. **Build** the Docker image and push it to ECR (using the
   `aws-ecr-credentials` credentials ID configured in Jenkins).
4. **Deploy** – this stage is left as an exercise for you to implement
   remote deployment (for example via AWS CodeDeploy or a simple SSH
   command).

You can adapt the pipeline to run on GitHub Actions by creating a
`.github/workflows` YAML file that mirrors the same steps.

## Extending This Project

To showcase more advanced DevOps skills you could:

* Use the AWS Copilot CLI to deploy the application as an ECS service
  on Fargate, including load balancing and auto‑scaling.
* Integrate AWS CodePipeline and CodeBuild to build and deploy the
  image entirely within AWS.
* Add unit and integration tests and enforce quality gates using
  SonarQube.
* Parameterise the Terraform code to create isolated environments
  (development, staging, production) with separate ECR repositories and
  EC2 instances or containers.
* Use Ansible to configure EC2 instances beyond the basic user data
  script.

These enhancements will better demonstrate experience with AWS,
Infrastructure as Code, and CI/CD automation.
