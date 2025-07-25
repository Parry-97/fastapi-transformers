# fastapi-transformers

A minimal FastAPI web API for text generation using Hugging Face Transformers models (via the `transformers` library). This project provides a `/text/simple-gen` endpoint that generates text completions using a default text generation pipeline.

## Features

- REST API for text generation (using Hugging Face `pipeline("text-generation")`)
- FastAPI-based, easily extendable and documented (provides OpenAPI/Swagger docs out of the box)
- Configured for easy Docker deployment using [uv](https://github.com/astral-sh/uv) for ultra-fast Python package management
- Works with PyTorch (CPU) by default
- Infrastructure-as-code for Azure provisioning using Terraform, with Kubernetes manifests for AKS-based app deployment

## Requirements

- Python 3.13+ (see `pyproject.toml`)
- Or Docker

## Installation

### Native

1. Install [uv](https://github.com/astral-sh/uv) (`pip install uv` or use pre-built binaries).
2. Sync the dependencies:

   ```bash
   uv sync
   ```

3. Run the app:

   ```bash
   uv run app.py
   ```

### With Docker

You can build and run the container as follows:

```bash
docker build -t fastapi-transformers .
docker run -p 80:80 fastapi-transformers
```

## Usage

The API exposes the following endpoint:

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
curl -X POST http://localhost/text/simple-gen -H 'Content-Type: application/json' -d '{"input":"Hello, world!"}'
```

## API Docs

- Once running (native or via Docker), see Swagger UI at [http://localhost/docs](http://localhost/docs)
- The OpenAPI schema is available at [http://localhost/openapi.json](http://localhost/openapi.json)

## Project Structure

```
.
├── app.py                        # FastAPI app and entrypoint
├── Dockerfile                    # Docker container configuration
├── pyproject.toml, uv.lock       # Project dependencies (managed by uv)
├── routers/
│   ├── models/
│   │   └── text_gen/
│   │       └── simple_input.py   # Data model for text generation input
│   └── text/
│       └── router.py             # API endpoints for text generation
```

## Extending

- To add new pipelines, add more routes in `routers/text/router.py` using FastAPI and the Hugging Face pipelines.
- To change the default model, override the `pipeline("text-generation")` call in the same file with your desired model, e.g. `pipeline("text-generation", model="gpt2")`.

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

### Deploying the Application on AKS

The Kubernetes manifest is located at `infra/k8s/k-deployment.yml`. Review and adjust the `image` field to match your ACR, then deploy:
```bash
kubectl apply -f infra/k8s/k-deployment.yml
kubectl rollout status deployment/myapp
kubectl get pods,svc
```

## License

This project is for educational/starter purposes. No explicit license.
