## 1. Infrastructure Setup
- [x] 1.1. Create Kubernetes manifests for the Ray Cluster (`RayCluster` custom resource).
- [x] 1.2. Create Kubernetes manifests for the KubeRay operator.
- [x] 1.3. Update Terraform configuration in `infra/azure/terraform` to install the KubeRay operator on the AKS cluster (e.g., using the Helm provider).

## 2. Application Integration
- [x] 2.1. Refactor the model serving logic in `app.py` or routers to use Ray Serve.
- [x] 2.2. Create a Ray Serve deployment configuration.

## 3. Deployment
- [x] 3.1. Update the `.github/workflows/infra_deployment.yml` to apply the Ray Cluster manifests.

## 4. Testing
- [x] 4.1. Add tests for the Ray Serve deployment.

## 5. Documentation
- [x] 5.1. Update `openspec/project.md` to include Ray in the tech stack.