#!/bin/bash
# Update RayService deployment with new Docker image
# Run this after Docker image build completes

set -e

echo "==> Step 1: Restarting RayService to pull new image..."
kubectl delete rayservice fastapi-transformer-service

echo "Waiting 10 seconds for cleanup..."
sleep 10

echo "==> Step 2: Redeploying RayService..."
kubectl apply -f infra/k8s/rayservice.yml

echo "==> Step 3: Waiting for Ray head pod to be ready..."
kubectl wait --for=condition=ready pod -l ray.io/node-type=head --timeout=600s

echo "==> Step 4: Checking RayService status..."
kubectl get rayservice

echo "==> Step 5: Getting LoadBalancer external IP..."
EXTERNAL_IP=$(kubectl get svc fastapi-transformer-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: $EXTERNAL_IP"

echo ""
echo "==> Test the application with:"
echo "curl -X POST http://$EXTERNAL_IP/text/simple-gen -H 'Content-Type: application/json' -d '{\"input\":\"Hello from Ray!\"}'"
