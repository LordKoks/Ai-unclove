#!/bin/bash
# Installation script for weak PC setup (Kali/Ubuntu)
# llama.cpp with TurboQuant + OpenVINO NPU support

set -e

echo "======================================"
echo "AI-unclove Weak PC Setup Installation"
echo "llama.cpp + TurboQuant + OpenVINO NPU"
echo "======================================"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo ""
echo "[1/7] Updating system packages..."
apt update && apt upgrade -y

echo ""
echo "[2/7] Installing base dependencies..."
apt install -y \
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
    docker.io \
    docker-compose

echo ""
echo "[3/7] Installing NVIDIA drivers and CUDA toolkit..."
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA drivers already installed"
else
    echo "Installing NVIDIA drivers..."
    apt install -y nvidia-driver-535 nvidia-utils-535
fi

# Install CUDA toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i cuda-keyring_1.0-1_all.deb
apt update
apt install -y cuda-toolkit-12-3

echo ""
echo "[4/7] Installing Intel NPU driver..."
if [ -f "/dev/accel/accel0" ]; then
    echo "NPU driver already installed"
else
    wget https://github.com/intel/linux-npu-driver/releases/latest/download/intel-npu-driver_1.0.0_amd64.deb
    dpkg -i intel-npu-driver_1.0.0_amd64.deb || apt install -f -y
fi

echo ""
echo "[5/7] Installing OpenVINO Runtime..."
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
echo "deb https://apt.repos.intel.com/openvino/2024 ubuntu22 main" | tee /etc/apt/sources.list.d/intel-openvino-2024.list
apt update
apt install -y openvino-2024.0.0

echo ""
echo "[6/7] Building llama.cpp with TurboQuant..."
cd /opt
if [ -d "llama-cpp-turboquant" ]; then
    echo "llama.cpp already cloned, updating..."
    cd llama-cpp-turboquant
    git pull
else
    git clone https://github.com/TheTom/llama-cpp-turboquant.git
    cd llama-cpp-turboquant
fi

# Try to checkout TurboQuant branch
git checkout feature/turboquant-kv-cache || echo "Using default branch"

# Build with OpenVINO and CUDA support
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_OPENVINO=ON \
    -DGGML_CUDA=ON \
    -DGGML_CURL=ON

cmake --build build --parallel $(nproc)

echo ""
echo "[7/7] Setting up Docker network..."
docker network create llm-network 2>/dev/null || echo "Network already exists"

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Download a GGUF model to the 'models' directory"
echo "2. Update MODEL_NAME in configs/weak-openvino-npu.env"
echo "3. Run: cd docker/weak-llamacpp-turboquant && docker-compose up -d"
echo "4. Access API at: http://localhost:8080"
echo ""
echo "For GUI, install Open WebUI:"
echo "cd docker/open-webui && docker-compose up -d"
echo "Access at: http://localhost:3000"
echo ""
