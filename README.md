# fastapi-transformers

A minimal FastAPI web API for text generation using Hugging Face Transformers models, served with [Ray Serve](https://www.ray.io/ray-serve) for scalable model serving. This project provides a `/text/simple-gen` endpoint that generates text completions using a default text generation pipeline.

## Features

- REST API for text generation (using Hugging Face `pipeline("text-generation")`)
- Scalable model serving with [Ray Serve](https://www.ray.io/ray-serve) on a [Ray Cluster](https://www.ray.io/ray-core)
- Deployed on Kubernetes and managed by the [KubeRay](https://github.com/ray-project/kuberay) operator
- FastAPI-based, easily extendable and documented (provides OpenAPI/Swagger docs out of the box)
- Configured for easy Docker deployment using [uv](https://github.com/astral-sh/uv) for ultra-fast Python package management
- Works with PyTorch (CPU) by default
- Infrastructure-as-code for Azure provisioning using Terraform, with Kubernetes manifests for AKS-based app deployment

## Requirements

- Python 3.13+ (see `pyproject.toml`)
- Or Docker

**Note on Python and Ray versions:** There is a potential version conflict. `pyproject.toml` specifies Python 3.13+ and `ray>=2.50.0`, while a comment in `infra/k8s/rayservice.yml` suggests `ray==2.46.0` which is not compatible with Python 3.13. This README assumes the versions in `pyproject.toml` are correct.

## Installation

### Native

1. Install [uv](https://github.com/astral-sh/uv) (`pip install uv` or use pre-built binaries).
2. Sync the dependencies:

   ```bash
   uv sync
   ```

3. Run the app with Ray Serve:

   ```bash
   serve run serve_app:deployment_graph
   ```

### With Docker

You can build and run the container as follows:

```bash
docker build -t fastapi-transformers .
docker run -p 8000:8000 fastapi-transformers
```

## Usage

The API is served by Ray Serve and exposes the following endpoint:

### `POST /text/simple-gen`

Generates text from provided input text. Uses the default text-generation pipeline from Hugging Face transformers (e.g., `gpt2` or equivalent, depending on environment/model cache).

- **Request Body**:

  ```json
  {
    "input": "Once upon a time"
  }
  ```

- **Response**:

  ```json
  [
    {
      "generated_text": "Once upon a time..."
    }
  ]
  ```

  (output format depends on the underlying model)

#### Example with curl

```bash
curl -X POST http://localhost:8000/text/simple-gen -H 'Content-Type: application/json' -d '{"input":"Hello, world!"}'
```

## API Docs

- Once running, see Swagger UI at [http://localhost:8000/docs](http://localhost:8000/docs)
- The OpenAPI schema is available at [http://localhost:8000/openapi.json](http://localhost:8000/openapi.json)

## Project Structure

```
.
├── serve_app.py                  # Ray Serve application entrypoint
├── Dockerfile                    # Docker container configuration
├── pyproject.toml, uv.lock       # Project dependencies (managed by uv)
├── infra/
│   ├── azure/terraform/          # Terraform for Azure resources (AKS, ACR)
│   └── k8s/
│       └── rayservice.yml        # RayService manifest for deploying the app on K8s
└── routers/
    ├── models/
    │   └── text_gen/
    │       └── simple_input.py   # Data model for text generation input
    └── text/
        └── __init__.py
```

## Extending

- To add new models or pipelines, create new Ray Serve deployments in `serve_app.py`.
- To change the default model, override the `pipeline("text-generation")` call in the `TextGenService` class with your desired model, e.g. `pipeline("text-generation", model="gpt2")`.

## Infrastructure Deployment

### Azure Infrastructure via Terraform

The Terraform configurations are located at `infra/azure/terraform` and provision the following Azure resources:
- Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS) cluster

To deploy the infrastructure, ensure you have the Azure CLI installed and are logged in:
```bash
az login
```
Then, from the Terraform directory:
```bash
cd infra/azure/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

After deployment, view the outputs (e.g., resource group and AKS cluster names):
```bash
terraform output
```

### Accessing the AKS Cluster

Configure `kubectl` to connect to the new AKS cluster:
```bash
az aks get-credentials --resource-group $(terraform output -raw rg_name) --name $(terraform output -raw aks_name)
kubectl get nodes
```

### Deploying the Application on AKS with KubeRay

The application is deployed as a `RayService` on the AKS cluster. This requires the KubeRay operator to be installed on the cluster.

1.  **Install the KubeRay operator:**

    Follow the instructions in the [KubeRay documentation](https://ray-project.github.io/kuberay/deploy/helm-chart/) to install the operator using Helm.

2.  **Deploy the RayService:**

    The Kubernetes manifest is located at `infra/k8s/rayservice.yml`. Review and adjust the `image` field to match your ACR, then deploy:
    ```bash
    kubectl apply -f infra/k8s/rayservice.yml
    ```

3.  **Verify the deployment:**

    Check the status of the RayService and the pods:
    ```bash
    kubectl get rayservice
    kubectl get pods
    ```

    To access the application, you will need to port-forward the Ray Serve service:
    ```bash
    kubectl port-forward service/fastapi-transformer-service-head-svc 8000:8000
    ```

## License

This project is for educational/starter purposes. No explicit license.
