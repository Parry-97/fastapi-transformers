# Project Context

## Purpose
This project provides a high-performance API for serving Hugging Face transformer models using the FastAPI framework. It is designed for easy deployment and scaling, with infrastructure managed by Terraform and Kubernetes.

## Tech Stack
- **Programming Language:** Python 3.11
- **API Framework:** FastAPI
- **ML Library:** Hugging Face Transformers
- **ML Serving:** Ray Serve
- **Package Management:** uv
- **Containerization:** Docker
- **Infrastructure as Code:** Terraform for Azure
- **Orchestration:** Kubernetes
- **CI/CD:** GitHub Actions
- **Testing:** Pytest

## Project Conventions

### Code Style
- **Formatting:** Code is formatted using `black` for consistency.
- **Linting:** `ruff` is used for linting to enforce PEP 8 and other best practices.
- **Naming:** Standard Python naming conventions (e.g., `snake_case` for variables and functions, `PascalCase` for classes).

### Architecture Patterns
- **Application:** The application follows standard FastAPI patterns, with a main `app.py` and modular routers located in the `routers/` directory.
- **Infrastructure:** Infrastructure is defined as code in the `infra/` directory. Terraform is used for provisioning Azure resources, and Kubernetes manifests are used for application deployment.

### Testing Strategy
- Unit and integration tests are located in the `tests/` directory.
- Tests are written using the `pytest` framework.
- All new features and bug fixes should be accompanied by corresponding tests.

### Git Workflow
- **Branching:** Development is done on feature branches, which are then merged into the `main` branch via pull requests.
- **Commits:** Commit messages should follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Domain Context
The core domain is providing machine learning model inference as a service, specifically for text generation tasks. The API abstracts the complexity of the underlying transformer models.

## Important Constraints
- The application is designed to be deployed on Azure.
- All infrastructure changes should be managed through Terraform.

## External Dependencies
- **Cloud Provider:** Microsoft Azure
- **Model Hub:** Hugging Face Hub for downloading transformer models.