#!/bin/bash
# Installation script for strong PC setup (Ubuntu/Debian)
# vLLM with maximum performance

set -e

echo "======================================"
echo "AI-unclove Strong PC Setup Installation"
echo "vLLM with OpenAI-compatible API"
echo "======================================"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo ""
echo "[1/5] Updating system packages..."
apt update && apt upgrade -y

echo ""
echo "[2/5] Installing base dependencies..."
apt install -y \
    git \
    curl \
    wget \
    python3.10 \
    python3-pip \
    python3-dev \
    build-essential \
    docker.io \
    docker-compose

echo ""
echo "[3/5] Installing NVIDIA drivers and CUDA toolkit..."
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA drivers already installed"
    nvidia-smi
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
echo "[4/5] Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt update
apt install -y nvidia-container-toolkit
systemctl restart docker

echo ""
echo "[5/5] Setting up Docker network..."
docker network create llm-network 2>/dev/null || echo "Network already exists"

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Download a HuggingFace model to the 'models' directory"
echo "2. Update MODEL_NAME in configs/strong-vllm.env"
echo "3. Run: cd docker/strong-vllm && docker-compose up -d"
echo "4. Access API at: http://localhost:8080"
echo ""
echo "For GUI, install Open WebUI:"
echo "cd docker/open-webui && docker-compose up -d"
echo "Access at: http://localhost:3000"
echo ""
