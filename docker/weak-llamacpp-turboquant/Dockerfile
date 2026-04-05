# Dockerfile for llama.cpp with TurboQuant + OpenVINO support
# Optimized for weak PC: Intel Core Ultra 7 + NPU + GTX 1660 8GB
FROM ubuntu:22.04

LABEL maintainer="AI-unclove"
LABEL description="llama.cpp with TurboQuant KV-cache compression and OpenVINO NPU support"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    build-essential \
    libcurl4-openssl-dev \
    libtbb12 \
    python3 \
    python3-pip \
    curl \
    wget \
    tar \
    clang \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install CUDA toolkit for GTX 1660 (fallback)
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt-get update && \
    apt-get install -y cuda-toolkit-12-3 && \
    rm -rf /var/lib/apt/lists/*

# Install OpenVINO Runtime (for NPU support)
RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB && \
    echo "deb https://apt.repos.intel.com/openvino/2024 ubuntu22 main" | tee /etc/apt/sources.list.d/intel-openvino-2024.list && \
    apt-get update && \
    apt-get install -y openvino-2024.0.0 && \
    rm -rf /var/lib/apt/lists/*

# Set OpenVINO environment variables
ENV INTEL_OPENVINO_DIR=/opt/intel/openvino_2024
ENV LD_LIBRARY_PATH=${INTEL_OPENVINO_DIR}/runtime/lib/intel64:${LD_LIBRARY_PATH}

# Clone and build llama.cpp with TurboQuant support
WORKDIR /app
RUN git clone https://github.com/TheTom/llama-cpp-turboquant.git llama.cpp && \
    cd llama.cpp && \
    git checkout feature/turboquant-kv-cache || echo "Using default branch"

WORKDIR /app/llama.cpp
RUN cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_OPENVINO=ON \
    -DGGML_CUDA=ON \
    -DGGML_CURL=ON \
    && cmake --build build --parallel $(nproc)

# Create models directory
RUN mkdir -p /models

# Expose OpenAI-compatible API port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Default entrypoint with TurboQuant 3-bit KV-cache
ENTRYPOINT ["/app/llama.cpp/build/bin/llama-server"]

# Default arguments - can be overridden in docker-compose
CMD ["-m", "/models/model.gguf", \
     "--cache-type-k", "turbo3", \
     "--cache-type-v", "turbo3", \
     "-ngl", "99", \
     "--host", "0.0.0.0", \
     "--port", "8080", \
     "-c", "32768", \
     "--jinja", \
     "--no-mmap"]
