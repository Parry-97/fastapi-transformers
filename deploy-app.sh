#!/bin/bash
# Deploy Ray application to AKS
# Run this after Terraform infrastructure deployment completes

set -e

echo "==> Step 1: Triggering Docker image build (now that ACR is ready)..."
gh workflow run docker-image.yml
echo "Waiting for Docker build to complete (this takes ~4 minutes)..."
echo "You can monitor progress at: https://github.com/Parry-97/fastapi-transformers/actions"
echo "Press Enter once the Docker build succeeds..."
read -r

echo "==> Step 2: Getting AKS credentials..."
az aks get-credentials --resource-group rg-we-hft-d-01 --name aks-we-hft-d-01 --overwrite-existing

echo "==> Step 3: Deploying RayService..."
kubectl apply -f infra/k8s/rayservice.yml

echo "==> Step 4: Deploying LoadBalancer service..."
kubectl apply -f infra/k8s/rayservice-loadbalancer.yml

echo "==> Step 5: Waiting for pods to be ready (this may take a few minutes)..."
kubectl wait --for=condition=ready pod -l ray.io/node-type=head --timeout=600s

echo "==> Step 6: Getting LoadBalancer external IP..."
echo "Waiting for external IP assignment (press Ctrl+C once you see an IP)..."
kubectl get svc fastapi-transformer-lb -w
