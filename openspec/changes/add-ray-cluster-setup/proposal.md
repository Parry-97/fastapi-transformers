## Why
To enable scalable and efficient serving of transformer models, we need to set up a Ray Cluster on the existing AKS infrastructure. This will allow us to use Ray Serve for robust model serving and management.

## What Changes
- **BREAKING**: The existing model serving endpoint will be replaced by a Ray Serve deployment.
- Add a new OpenSpec capability for the Ray Cluster (`ray-cluster`).
- Configure and add Kubernetes manifests for deploying the Ray Cluster and KubeRay operator on AKS.
- Refactor the application to use Ray Serve for model serving.
- Update the CI/CD pipeline to deploy the Ray Cluster and the Ray Serve application.

## Impact
- **Affected specs:** A new `ray-cluster` spec will be created. The existing application specs may need to be modified to reflect the use of Ray Serve.
- **Affected code:**
  - `infra/k8s/` (new manifests for Ray)
  - `infra/azure/terraform/` (to add the KubeRay operator)
  - `app.py` and `routers/` (refactoring to use Ray Serve)
  - `.github/workflows/infra_deployment.yml` (to deploy the new components)
