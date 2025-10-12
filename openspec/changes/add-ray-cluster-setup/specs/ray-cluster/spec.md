## ADDED Requirements

### Requirement: Ray Cluster Deployment
The system SHALL deploy a Ray Cluster on the AKS cluster.

#### Scenario: Deploy Ray Cluster
- **WHEN** the infrastructure deployment pipeline is run
- **THEN** a Ray Cluster is running on the AKS cluster.

### Requirement: Ray Serve for Model Serving
The system SHALL use Ray Serve to serve the transformer models.

#### Scenario: Serve a model with Ray Serve
- **WHEN** a request is sent to the model serving endpoint
- **THEN** the model is served by a Ray Serve replica.
