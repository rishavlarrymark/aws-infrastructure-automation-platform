#!/bin/bash
set -Eeuo pipefail

exec > >(tee -a /var/log/user-data.log) 2>&1

echo "Starting EC2 application bootstrap..."

# Configuration supplied by Terraform templatefile()
AWS_REGION="${aws_region}"
ECR_REGISTRY="${ecr_registry}"
IMAGE_NAME="${image_name}"
IMAGE_TAG="${image_tag}"
APP_PORT="${application_port}"

# Update packages and install Docker and AWS CLI
dnf update -y
dnf install -y docker awscli-2

# Enable Docker at startup
systemctl enable --now docker

# Authenticate with Amazon ECR
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login \
      --username AWS \
      --password-stdin "$ECR_REGISTRY"

# Pull the application image
docker pull "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# Remove the previous container if it exists
docker rm -f task-management-api || true

# Start the FastAPI application container
docker run -d \
  --name task-management-api \
  --restart unless-stopped \
  -p "${APP_PORT}:8000" \
  "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# Verify container startup
sleep 3

if ! docker ps --filter "name=^/task-management-api$" \
    --filter "status=running" --format '{{.Names}}' \
    | grep -qx 'task-management-api'; then
  docker logs task-management-api || true
  echo "ERROR: Task Management API container failed to start."
  exit 1
fi

echo "Task Management API container is running."
echo "Bootstrap completed. Verify /health and database connectivity."