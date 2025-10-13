#!/bin/bash
set -e

# AWS ECR details
AWS_REGION="ap-south-1"
ACCOUNT_ID="775826428475"

# List of containers
containers=("auth-service" "product-service" "cart-service" "order-service" "payment-service" "email-service")
# Optional: create ECR repos if they don't exist
for c in "${containers[@]}"; do
    aws ecr describe-repositories --repository-names $c --region $AWS_REGION >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name $c --region $AWS_REGION
done

# Build, tag, and push only changed containers
for c in "${containers[@]}"; do
    # Check if there are any changes in the container folder
    if git diff --quiet HEAD~1 HEAD ./$c; then
        echo "No changes in $c, skipping build."
        continue
    fi

    echo "-----------------------------"
    echo "Changes detected in container: $c"
    echo "Building and pushing image..."
    echo "-----------------------------"

    # Build Docker image
    docker build -t $c ./$c

    # Tag Docker image for ECR
    docker tag $c:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$c:latest

    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

    # Push to ECR
    docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$c:latest
done