# Ray Cluster Setup Documentation

## Overview

This project uses **Ray Serve** running on a **Ray Cluster** deployed to **Azure Kubernetes Service (AKS)** for scalable model inference. The Ray Cluster is managed by the **KubeRay Operator**, which automates the lifecycle management of Ray clusters on Kubernetes.

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                   Azure Cloud (AKS)                     │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │         KubeRay Operator (Helm Chart)             │ │
│  │          Namespace: kuberay-system                │ │
│  └───────────────┬───────────────────────────────────┘ │
│                  │ Manages                             │
│                  ▼                                     │
│  ┌───────────────────────────────────────────────────┐ │
│  │              RayService Custom Resource           │ │
│  │       Name: fastapi-transformer-service           │ │
│  │                                                   │ │
│  │   ┌─────────────────────────────────────────┐     │ │
│  │   │        Ray Head Node (Pod)              │     │ │
│  │   │  - Ray GCS Server (port 6379)           │     │ │
│  │   │  - Ray Dashboard (port 8265)            │     │ │
│  │   │  - Ray Serve HTTP Proxy (port 8000)     │     │ │
│  │   │  - Resources: 1 CPU, 3Gi memory         │     │ │
│  │   └─────────────────────────────────────────┘     │ │
│  │                                                   │ │
│  │   ┌─────────────────────────────────────────┐     │ │
│  │   │      Ray Worker Nodes (1-2 Pods)        │     │ │
│  │   │  - Worker Group: small-group            │     │ │
│  │   │  - Resources: 1 CPU, 2Gi memory each    │     │ │
│  │   └─────────────────────────────────────────┘     │ │
│  └───────────────────────────────────────────────────┘ │
│                                                        │
│  ┌───────────────────────────────────────────────────┐ │
│  │        LoadBalancer Service                       │ │
│  │    Name: fastapi-transformer-lb                   │ │
│  │    External Port: 80 → Target Port: 8000          │ │
│  └───────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

### Key Technologies

- **Ray 2.50.0**: Distributed computing framework
- **Ray Serve**: Model serving layer built on Ray
- **KubeRay Operator 1.1.1**: Kubernetes operator for managing Ray clusters
- **FastAPI**: Web framework integrated with Ray Serve
- **Hugging Face Transformers**: NLP models (DistilGPT-2 pre-downloaded in image)
- **Azure Kubernetes Service (AKS)**: Managed Kubernetes platform
- **Azure Container Registry (ACR)**: Container image registry

## Detailed Component Explanation

### 1. KubeRay Operator

**Purpose**: Automates the deployment, scaling, and management of Ray clusters on Kubernetes.

**Installation Method**: Helm chart deployed via Terraform

**Configuration** (`infra/azure/terraform/main.tf`):

```hcl
resource "helm_release" "kuberay_operator" {
  name             = "kuberay-operator"
  repository       = "https://ray-project.github.io/kuberay-helm/"
  chart            = "kuberay-operator"
  version          = "1.1.1"
  namespace        = "kuberay-system"
  create_namespace = true
  depends_on       = [module.app_backend]
}
```

**Responsibilities**:

- Watches for `RayCluster` and `RayService` custom resources
- Creates and manages Ray head and worker pods
- Handles autoscaling of worker nodes
- Monitors cluster health and performs self-healing
- Manages service discovery between Ray components

### 2. RayService Custom Resource

**Purpose**: Declaratively defines a Ray Cluster with Ray Serve application deployment.

**Location**: `infra/k8s/rayservice.yml`

**Key Configuration Parameters**:

```yaml
apiVersion: ray.io/v1
kind: RayService
metadata:
  name: fastapi-transformer-service
spec:
  # Health check thresholds
  serviceUnhealthySecondThreshold: 900 # 15 minutes
  deploymentUnhealthySecondThreshold: 300 # 5 minutes

  # Ray Serve application configuration
  serveConfigV2: |
    applications:
      - name: transformer-app
        import_path: serve_app:deployment_graph
        route_prefix: /
        runtime_env: {}
```

**Why RayService vs RayCluster?**

- `RayService` = `RayCluster` + Ray Serve application management
- Automatically deploys and manages the Serve application
- Provides zero-downtime updates and health monitoring
- Better suited for serving workloads than raw `RayCluster`

### 3. Ray Head Node

**Purpose**: Central coordinator for the Ray cluster and hosts the Ray Serve HTTP proxy.

**Specifications**:

```yaml
headGroupSpec:
  template:
    spec:
      containers:
        - name: ray-head
          image: crhftd01.azurecr.io/myapp:latest
          ports:
            - containerPort: 6379 # Ray GCS (Global Control Service)
              name: gcs-server
            - containerPort: 8265 # Ray Dashboard (UI)
              name: dashboard
            - containerPort: 10001 # Ray Client API
              name: client
          resources:
            limits:
              cpu: "1"
              memory: "3Gi"
            requests:
              cpu: "500m"
              memory: "1536Mi"
```

**Ray Head Node Responsibilities**:

- **GCS (Global Control Service)**: Maintains cluster metadata and actor directory
- **Ray Dashboard**: Web UI for monitoring cluster status, tasks, and resources
- **Scheduler**: Distributes tasks across worker nodes
- **Ray Serve HTTP Proxy**: Routes incoming HTTP requests to Serve deployments
- **Object Store**: In-memory distributed object storage

### 4. Ray Worker Nodes

**Purpose**: Execute Ray tasks and host Ray Serve deployment replicas.

**Specifications**:

```yaml
workerGroupSpecs:
  - replicas: 1 # Starting number of workers
    minReplicas: 1 # Minimum autoscaling bound
    maxReplicas: 2 # Maximum autoscaling bound
    groupName: small-group
    template:
      spec:
        containers:
          - name: ray-worker
            image: crhftd01.azurecr.io/myapp:latest
            resources:
              limits:
                cpu: "1"
                memory: "2Gi"
              requests:
                cpu: "500m"
                memory: "1Gi"
```

**Worker Node Responsibilities**:

- Execute Ray tasks scheduled by the head node
- Host Ray Serve deployment replicas (model inference instances)
- Participate in distributed object store
- Report metrics back to GCS

**Autoscaling Behavior**:

- KubeRay can scale workers between `minReplicas` and `maxReplicas`
- Based on resource utilization and pending tasks
- Currently configured for 1-2 workers

### 5. Ray Serve Application

**Purpose**: Serves the Hugging Face Transformers model via a FastAPI interface.

**Location**: `serve_app.py`

**Architecture**:

```python
@serve.deployment
@serve.ingress(app)
class TextGenService:
    def __init__(self):
        # Loaded once per replica
        self._pipeline = pipeline("text-generation", model="distilgpt2")

    @app.post("/text/simple-gen")
    def simple_gen(self, input: SimpleInput):
        return self._pipeline(input.input)

# Deployment graph entrypoint
deployment_graph = TextGenService.bind()
```

**Key Concepts**:

**Deployment**: A Ray Serve unit that can be replicated and scaled

- Each deployment runs in a separate Ray actor
- Can have multiple replicas for horizontal scaling
- Isolated resources and lifecycle

**Ingress**: FastAPI app that handles HTTP routing

- Ray Serve acts as a reverse proxy
- Routes requests to the appropriate deployment
- Integrates seamlessly with FastAPI

**Deployment Graph**: Defines how deployments are connected

- In this case, a single deployment exposed via ingress
- Can compose multiple deployments in DAG patterns

**Runtime Environment**: Dependencies and files needed by the deployment

- Empty `{}` because everything is baked into the Docker image
- Can dynamically load code/packages if needed

### 6. Docker Image

**Base Image**: `rayproject/ray:2.50.0-py311`

**Purpose**: Pre-packages all dependencies and code for the Ray cluster.

**Key Steps** (`Dockerfile`):

```dockerfile
# Ray base image with matching Python version
FROM rayproject/ray:2.50.0-py311

WORKDIR /app

# Install dependencies using pip (Ray's environment)
RUN pip install --no-cache-dir \
    fastapi[standard]>=0.115.13 \
    torch>=2.7.1 --extra-index-url https://download.pytorch.org/whl/cpu \
    transformers>=4.52.4 \
    uvicorn>=0.34.3

# Copy application code
COPY . .

# Pre-download model to avoid runtime downloads (~240MB)
RUN python -c "from transformers import pipeline; pipeline('text-generation', model='distilgpt2')"
```

**Why Pre-download the Model?**

- Faster pod startup times (no download wait on first request)
- Deterministic behavior (no network dependency at runtime)
- Better for autoscaling (new replicas are immediately ready)

### 7. LoadBalancer Service

**Purpose**: Exposes the Ray Serve application to external traffic.

**Location**: `infra/k8s/rayservice-loadbalancer.yml`

**Configuration**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: fastapi-transformer-lb
spec:
  type: LoadBalancer
  selector:
    ray.io/node-type: head # Routes to Ray head pod
  ports:
    - name: http
      port: 80 # External port
      targetPort: 8000 # Ray Serve HTTP proxy port
      protocol: TCP
```

**Why Target the Head Node?**

- Ray Serve HTTP proxy runs on the head node
- The proxy intelligently routes requests to worker replicas
- Provides built-in load balancing across replicas

## Request Flow

```
1. External Client
   ↓ HTTP Request (port 80)
2. Azure LoadBalancer
   ↓ Routes to fastapi-transformer-lb Service
3. Kubernetes Service (fastapi-transformer-lb)
   ↓ Forwards to Ray Head Pod (port 8000)
4. Ray Serve HTTP Proxy (on Head Node)
   ↓ Routes based on path (/) to deployment
5. TextGenService Deployment Replica
   ↓ Runs inference with Transformers pipeline
6. Response
   ↑ Back through the same path
```

## Deployment Workflow

### Step 1: Provision Azure Infrastructure

```bash
cd infra/azure/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**What This Creates**:

- Azure Resource Group
- Azure Container Registry (ACR) - `crhftd01.azurecr.io`
- Azure Kubernetes Service (AKS) cluster
- **KubeRay Operator** (via Helm) in `kuberay-system` namespace

### Step 2: Configure kubectl

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw rg_name) \
  --name $(terraform output -raw aks_name)
```

### Step 3: Build and Push Docker Image

```bash
# Build the image
docker build -t fastapi-transformers .

# Tag for ACR
docker tag fastapi-transformers crhftd01.azurecr.io/myapp:latest

# Login and push
az acr login --name crhftd01
docker push crhftd01.azurecr.io/myapp:latest
```

### Step 4: Deploy RayService

```bash
# Deploy the Ray cluster with Serve application
kubectl apply -f infra/k8s/rayservice.yml

# Verify deployment
kubectl get rayservice
kubectl get pods

# Expected pods:
# - fastapi-transformer-service-head-xxxxx (Ray head)
# - fastapi-transformer-service-worker-small-group-xxxxx (Worker)
```

### Step 5: Expose via LoadBalancer

```bash
kubectl apply -f infra/k8s/rayservice-loadbalancer.yml

# Get external IP
kubectl get svc fastapi-transformer-lb

# Wait for EXTERNAL-IP (may take 2-3 minutes)
```

### Step 6: Test the Deployment

```bash
# Get the LoadBalancer IP
LB_IP=$(kubectl get svc fastapi-transformer-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Send test request
curl -X POST http://$LB_IP/text/simple-gen \
  -H 'Content-Type: application/json' \
  -d '{"input":"Once upon a time"}'
```

## Monitoring and Debugging

### Access Ray Dashboard

```bash
# Port-forward the dashboard
kubectl port-forward service/fastapi-transformer-service-head-svc 8265:8265

# Open in browser
open http://localhost:8265
```

**Dashboard Features**:

- Cluster overview (nodes, resources, utilization)
- Job history and task timeline
- Actor state and resource usage
- Serve deployment metrics and latency
- Logs and error tracking

### View Logs

```bash
# Head node logs
kubectl logs -l ray.io/node-type=head

# Worker node logs
kubectl logs -l ray.io/group-name=small-group

# Follow logs in real-time
kubectl logs -f -l ray.io/node-type=head
```

### Check RayService Status

```bash
# Get RayService details
kubectl describe rayservice fastapi-transformer-service

# Check for events and status conditions
kubectl get rayservice fastapi-transformer-service -o yaml
```

### Common Issues and Troubleshooting

**Issue**: Pods stuck in `Pending` state

- **Cause**: Insufficient cluster resources
- **Solution**: Check node resources with `kubectl describe nodes`, scale AKS node pool

**Issue**: Serve application fails to start

- **Cause**: Import path error or missing dependencies
- **Solution**: Check head pod logs for Python tracebacks, verify `serve_app:deployment_graph` is correct

**Issue**: Model download timeouts

- **Cause**: Network issues pulling from Hugging Face Hub
- **Solution**: Pre-download model in Dockerfile (already implemented)

**Issue**: LoadBalancer external IP stays `<pending>`

- **Cause**: Azure provisioning delay or quota limits
- **Solution**: Wait 2-3 minutes, check Azure portal for LoadBalancer resource

## Scaling Considerations

### Vertical Scaling (More Resources per Pod)

Edit `rayservice.yml` resource limits:

```yaml
resources:
  limits:
    cpu: "2" # Increase CPU
    memory: "4Gi" # Increase memory
```

### Horizontal Scaling (More Replicas)

**Option 1: Increase Worker Replicas**

```yaml
workerGroupSpecs:
  - replicas: 3 # More workers = more inference capacity
    maxReplicas: 5
```

**Option 2: Increase Serve Deployment Replicas**

```python
@serve.deployment(num_replicas=2)  # Multiple inference replicas
class TextGenService:
    ...
```

**Option 3: Autoscaling**
Ray Serve supports autoscaling based on request queue depth:

```python
@serve.deployment(
    autoscaling_config={
        "min_replicas": 1,
        "max_replicas": 5,
        "target_num_ongoing_requests_per_replica": 10
    }
)
```

### AKS Node Pool Scaling

Scale the underlying Kubernetes nodes:

```bash
az aks scale \
  --resource-group $(terraform output -raw rg_name) \
  --name $(terraform output -raw aks_name) \
  --node-count 3
```

## Cost Optimization

### Development Setup (Minimal Cost)

- Head: 1 CPU, 1.5Gi memory
- Workers: 1 replica, 1 CPU, 1Gi memory
- AKS: 1 node pool with 2 Standard_B2s nodes

### Production Setup (Higher Performance)

- Head: 2 CPU, 4Gi memory
- Workers: 3-5 replicas, 2 CPU, 4Gi memory each
- AKS: 2 node pools (system + user), autoscaling enabled
- Enable GPU nodes for faster inference

## Performance Tuning

### Model Selection

- **DistilGPT-2** (current): 82M parameters, ~240MB, fast inference
- **GPT-2**: 124M parameters, ~550MB, better quality
- **GPT-2 Large**: 774M parameters, ~3GB, production quality

Update in `serve_app.py`:

```python
self._pipeline = pipeline("text-generation", model="gpt2-large")
```

### Batching

Ray Serve supports request batching for throughput:

```python
@serve.deployment
class TextGenService:
    @serve.batch(max_batch_size=10, batch_wait_timeout_s=0.1)
    async def handle_batch(self, inputs):
        return [self._pipeline(input) for input in inputs]
```

### GPU Acceleration

1. Use GPU-enabled AKS node pools
2. Update Dockerfile to use GPU-enabled base image:

   ```dockerfile
   FROM rayproject/ray:2.50.0-py311-gpu
   ```

3. Add GPU resources to pod specs:

   ```yaml
   resources:
     limits:
       nvidia.com/gpu: 1
   ```

## Security Considerations

### Image Security

- Use ACR with Azure AD authentication
- Scan images for vulnerabilities (Azure Defender for container registries)
- Implement image signing and verification

### Network Security

- Place AKS in private VNet (already configured via Terraform modules)
- Use Network Policies to restrict pod-to-pod traffic
- Enable Azure Firewall for egress filtering

### RBAC

- Use Azure AD integration for AKS authentication
- Implement Kubernetes RBAC for fine-grained access control
- Separate service accounts for different workloads

### Secrets Management

- Use Azure Key Vault for secrets
- Integrate with KubeRay via CSI Secret Store driver
- Avoid hardcoding credentials in manifests

## Advanced Features

### Multi-Application Serving

Ray Serve supports multiple applications in one cluster:

```yaml
serveConfigV2: |
  applications:
    - name: transformer-app
      import_path: serve_app:deployment_graph
      route_prefix: /text
    - name: image-app
      import_path: image_serve:deployment
      route_prefix: /image
```

### Traffic Splitting (A/B Testing)

Deploy multiple versions and split traffic:

```python
# Version A
@serve.deployment(name="model_v1")
class ModelV1:
    ...

# Version B
@serve.deployment(name="model_v2")
class ModelV2:
    ...

# Traffic split
from ray.serve.handle import DeploymentHandle
serve.run(
    serve.router([
        (ModelV1.bind(), 0.9),  # 90% traffic
        (ModelV2.bind(), 0.1),  # 10% traffic
    ])
)
```

### Model Composition

Chain multiple models in a deployment graph:

```python
@serve.deployment
class Preprocessor:
    def __call__(self, text):
        return clean_text(text)

@serve.deployment
class Generator:
    def __init__(self, preprocessor: DeploymentHandle):
        self.preprocessor = preprocessor
        self.pipeline = pipeline("text-generation")

    async def __call__(self, input):
        cleaned = await self.preprocessor.remote(input)
        return self.pipeline(cleaned)

# Compose
deployment_graph = Generator.bind(Preprocessor.bind())
```

## References

- [Ray Documentation](https://docs.ray.io/)
- [Ray Serve Documentation](https://docs.ray.io/en/latest/serve/index.html)
- [KubeRay Documentation](https://ray-project.github.io/kuberay/)
- [KubeRay Operator Helm Chart](https://github.com/ray-project/kuberay-helm)
- [Azure Kubernetes Service Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Hugging Face Transformers](https://huggingface.co/docs/transformers/)
