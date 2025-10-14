#!/bin/bash
echo "=== Deploying Kubernetes Manifests ==="

# Apply in order
echo "1. Creating namespace..."
kubectl apply -f namespace.yaml

echo "2. Deploying services..."
kubectl apply -f deployment/
kubectl apply -f service/

echo "3. Setting up auto-scaling..."
kubectl apply -f autoscaling/

echo "4. Configuring ALB controller..."
kubectl apply -f alb-controller/

echo "=== Deployment Complete ==="
kubectl get pods -n backend