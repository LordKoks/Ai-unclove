# Dockerfile for vLLM - High-Performance LLM Inference
# Optimized for strong PC: Windows 11 with powerful GPU
FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04

LABEL maintainer="AI-unclove"
LABEL description="vLLM with OpenAI-compatible API for maximum performance"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install vLLM
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel
RUN pip3 install --no-cache-dir \
    vllm \
    openai \
    fastapi \
    uvicorn[standard] \
    pydantic \
    ray

# Create models directory
RUN mkdir -p /models

# Expose OpenAI-compatible API port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Set working directory
WORKDIR /app

# Default entrypoint
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]

# Default arguments - can be overridden in docker-compose
CMD ["--model", "/models/model", \
     "--host", "0.0.0.0", \
     "--port", "8080", \
     "--tensor-parallel-size", "1", \
     "--dtype", "auto", \
     "--max-model-len", "32768"]
