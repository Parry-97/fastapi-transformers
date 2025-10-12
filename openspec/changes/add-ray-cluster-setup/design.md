## Context
The project currently uses FastAPI on AKS for model serving. To improve scalability and management, we will introduce Ray and Ray Serve.

## Decisions
- **Ray on Kubernetes Operator:** We will use the [KubeRay](https://github.com/ray-project/kuberay) operator to manage the lifecycle of the Ray Cluster on Kubernetes.
- **RayCluster Custom Resource:** The Ray Cluster will be defined and configured using a `RayCluster` custom resource, which will be stored in `infra/k8s/`.
- **Model Serving:** The existing FastAPI application will be refactored into a Ray Serve application. This will involve defining serve deployments that wrap the transformer models.

## Alternatives Considered
- **Seldon Core / KServe:** These are powerful model serving platforms, but Ray Serve is chosen for its simpler Python-native API and tight integration with the Ray ecosystem, which will be beneficial for future distributed computing needs.
- **Manual Management:** Manually managing Ray pods is complex and error-prone. The KubeRay operator provides robust automation for deployment, scaling, and fault tolerance.
