# Blue-Green Deployment Automation on AWS using Jenkins, Terraform, ECS & CloudWatch

A production-grade DevOps project implementing a Blue-Green deployment strategy on AWS using ECS for container orchestration, fully automated with Jenkins CI/CD pipelines and Infrastructure as Code (Terraform), with monitoring powered by AWS CloudWatch.

This project simulates real-world enterprise deployment workflows used to achieve zero-downtime application releases in cloud environments.

---

# Project Highlights

- Blue-Green deployment strategy implementation
- AWS ECS (Elastic Container Service) for container orchestration
- Jenkins CI/CD automation pipeline
- Infrastructure as Code using Terraform
- AWS Application Load Balancer (ALB)
- Zero-downtime deployment strategy
- Automated traffic switching between environments
- Monitoring and logging using AWS CloudWatch
- Cloud-native scalable architecture

---

# Architecture Overview

## Deployment Workflow

```text
Developer Pushes Code
        ↓
GitHub Repository
        ↓
Jenkins CI/CD Pipeline
        ↓
Build Docker Image
        ↓
Push Image to AWS ECR
        ↓
Deploy to AWS ECS (Blue Environment)
        ↓
Deploy New Version to ECS (Green Environment)
        ↓
AWS ALB Traffic Switching (Blue → Green)
        ↓
CloudWatch Monitoring & Logs
        ↓
Rollback if Needed (Green → Blue)
```

---

# Tech Stack

## Cloud Infrastructure

- Amazon Web Services (AWS)
- AWS ECS (Fargate / EC2)
- AWS ECR (Elastic Container Registry)
- AWS Application Load Balancer (ALB)
- AWS CloudWatch

## DevOps Tools

- Jenkins
- Terraform
- Docker
- GitHub

## Deployment Strategy

- Blue-Green Deployment
- Zero Downtime Deployment
- Load Balancer Traffic Switching

## Monitoring

- AWS CloudWatch Logs
- AWS Metrics & Dashboards
- Alarm-based monitoring

---

# Project Structure

```bash
.
├── app/
├── terraform/
├── jenkins/
├── ecs/
│   ├── task-definition.json
│   ├── blue-service.json
│   ├── green-service.json
├── scripts/
├── monitoring/
├── Dockerfile
├── Jenkinsfile
└── README.md
```

---

# Features

- Automated Blue-Green deployments on AWS ECS
- Fully automated Jenkins CI/CD pipeline
- Infrastructure provisioning with Terraform
- Docker containerized application
- AWS ALB-based traffic switching
- CloudWatch monitoring & logging
- Zero-downtime deployment strategy
- Rollback capability
- Scalable cloud-native architecture

---

# Prerequisites

Install:

- AWS CLI
- Terraform
- Docker
- Jenkins
- Git

---

# Clone Repository

```bash
git clone https://github.com/Chrisblurp/Blue-Green-Deploy.git

cd blue-green-ecs-deployment
```

---

# AWS Configuration

```bash
aws configure
```

Set:

- AWS Access Key
- AWS Secret Key
- Region
- Output format

---

# Infrastructure as Code (Terraform)

Terraform provisions AWS infrastructure including:

- ECS cluster
- Task definitions
- IAM roles
- ALB (Application Load Balancer)
- Networking components

---

## Initialize Terraform

```bash
cd terraform
terraform init
```

---

## Plan Infrastructure

```bash
terraform plan
```

---

## Apply Infrastructure

```bash
terraform apply
```

---

# Dockerization

## Build Image

```bash
docker build -t my-app .
```

---

## Push to AWS ECR

```bash
aws ecr get-login-password --region <region> \
| docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com

docker tag my-app:latest <account-id>.dkr.ecr.<region>.amazonaws.com/my-app:latest

docker push <account-id>.dkr.ecr.<region>.amazonaws.com/my-app:latest
```

---

# AWS ECS Deployment

## ECS Concepts Used

- Task Definitions
- ECS Services
- Blue environment (stable version)
- Green environment (new version)
- Load Balancer target groups

---

## Deployment Flow

1. Deploy Blue environment (current stable version)
2. Deploy Green environment (new version)
3. Run health checks on Green
4. Switch ALB traffic to Green
5. Keep Blue for rollback

---

# Jenkins CI/CD Pipeline

Jenkins automates the full deployment lifecycle:

- Build Docker image
- Push image to ECR
- Trigger Terraform updates
- Deploy to ECS Blue/Green environments
- Execute traffic switching
- Validate deployment

---

# Jenkins Setup (Docker)

```bash
docker run -d \
--name jenkins \
-p 8080:8080 \
-p 50000:50000 \
-v jenkins_home:/var/jenkins_home \
-v /var/run/docker.sock:/var/run/docker.sock \
jenkins/jenkins:lts
```

---

# Access Jenkins

```text
http://localhost:8080
```

---

# AWS CloudWatch Monitoring

CloudWatch is used for:

- ECS service logs
- Container health monitoring
- CPU & memory metrics
- Application performance tracking
- Deployment validation

---

# CloudWatch Features Used

- Log groups for ECS tasks
- Metrics dashboards
- Alarms for failures
- Real-time monitoring of deployments

---

# CI/CD Pipeline Flow

```text
Code Commit
      ↓
Jenkins Trigger
      ↓
Docker Build
      ↓
Push to AWS ECR
      ↓
Terraform Infrastructure Update
      ↓
Deploy to ECS Green Environment
      ↓
Health Check
      ↓
Switch ALB Traffic (Blue → Green)
      ↓
CloudWatch Monitoring
```

---

# DevOps Skills Demonstrated

- AWS ECS (Elastic Container Service)
- AWS ECR container registry
- AWS ALB load balancing
- Blue-Green deployment strategy
- Jenkins CI/CD automation
- Terraform Infrastructure as Code
- Docker containerization
- AWS CloudWatch monitoring
- Zero-downtime deployment design
- Cloud-native DevOps workflows

---


