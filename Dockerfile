# Use Ray base image with Python 3.11
# Note: Ray 2.50.0 is specified in pyproject.toml
FROM rayproject/ray:2.50.0-py311

# Copy uv for fast Python package management
COPY --from=ghcr.io/astral-sh/uv:0.7.13 /uv /uvx /bin/

WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies using uv
# Ray is already installed in the base image, so we install additional deps
RUN uv sync --no-group dev

# Copy the application code
COPY . .

# Ray will manage the startup command via RayService/RayCluster manifests
# No CMD needed as Ray operator handles process management
