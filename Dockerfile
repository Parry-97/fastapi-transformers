# Use Ray base image with Python 3.11
# Note: Ray 2.50.0 is specified in pyproject.toml
FROM rayproject/ray:2.50.0-py311

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies using pip (Ray's Python environment)
# We use pip instead of uv to ensure packages are installed in Ray's environment
RUN pip install --no-cache-dir \
    fastapi[standard]>=0.115.13 \
    torch>=2.7.1 --extra-index-url https://download.pytorch.org/whl/cpu \
    transformers>=4.52.4 \
    uvicorn>=0.34.3

# Copy the application code
COPY . .

# Ray will manage the startup command via RayService/RayCluster manifests
# No CMD needed as Ray operator handles process management
