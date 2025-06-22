FROM python:3.11-bullseye AS build

COPY --from=ghcr.io/astral-sh/uv:0.7.13 /uv /uvx /bin/

WORKDIR /app
COPY pyproject.toml uv.lock* ./
# Install dependencies using UV based on your lock file
RUN uv sync --no-group dev
# Copy the remainder of the application code
COPY . .

CMD ["uv","run","app.py"]
