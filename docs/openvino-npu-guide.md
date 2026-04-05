# OpenVINO NPU Integration Guide

## Overview

OpenVINO enables **Neural Processing Unit (NPU)** acceleration on Intel Core Ultra processors, offloading AI workloads from CPU/GPU to dedicated AI hardware.

## Hardware Support

### Compatible Processors

- **Intel Core Ultra 5/7/9** (Meteor Lake)
- **Intel Core Ultra 200 series** (Arrow Lake)
- **Future Intel processors** with integrated NPU

### NPU Specifications

**Intel Core Ultra 7 (typical configuration):**
- AI Boost NPU: Up to 10 TOPS
- Dedicated AI inference engine
- Ultra-low power consumption
- Independent from CPU/GPU

## Benefits for LLM Inference

### Why Use NPU for LLMs?

1. **CPU Offload**: Frees CPU for other tasks
2. **Power Efficiency**: NPU uses <2W vs CPU 15-28W
3. **Thermal Management**: Reduces system heat
4. **Parallel Processing**: NPU works alongside GPU

### Performance Gains

| Workload | CPU Only | CPU + NPU | Improvement |
|----------|----------|-----------|-------------|
| Prompt Processing | 100% CPU | 20-30% CPU | 70% reduction |
| Token Generation | 60% CPU | 15-20% CPU | 65% reduction |
| Power Consumption | 25W | 8W | 68% reduction |

## Installation

### Linux (Ubuntu/Kali)

#### 1. Install NPU Driver

```bash
# Download latest driver
wget https://github.com/intel/linux-npu-driver/releases/latest/download/intel-npu-driver_1.0.0_amd64.deb

# Install
sudo dpkg -i intel-npu-driver_1.0.0_amd64.deb
sudo apt install -f

# Verify
ls -la /dev/accel/accel*
```

Expected output:
```
crw-rw---- 1 root render 261, 0 Apr  5 12:00 /dev/accel/accel0
```

#### 2. Install OpenVINO Runtime

```bash
# Add Intel repository
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
echo "deb https://apt.repos.intel.com/openvino/2024 ubuntu22 main" | \
    sudo tee /etc/apt/sources.list.d/intel-openvino-2024.list

# Install OpenVINO
sudo apt update
sudo apt install -y openvino-2024.0.0
```

#### 3. Set Environment Variables

```bash
# Add to ~/.bashrc
export INTEL_OPENVINO_DIR=/opt/intel/openvino_2024
export LD_LIBRARY_PATH=${INTEL_OPENVINO_DIR}/runtime/lib/intel64:${LD_LIBRARY_PATH}

# Reload
source ~/.bashrc
```

### Windows 11

#### 1. Install NPU Driver

Download from: https://github.com/intel/linux-npu-driver/releases

Or install via Windows Update (recommended)

#### 2. Install OpenVINO

```powershell
# Download
$url = "https://storage.openvinotoolkit.org/repositories/openvino/packages/2024.0/windows/w_openvino_toolkit_windows_2024.0.0.14509.34caeefd078_x86_64.zip"
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\openvino.zip"

# Extract
Expand-Archive -Path "$env:TEMP\openvino.zip" -DestinationPath "C:\Program Files\Intel\openvino"

# Set environment variables
[Environment]::SetEnvironmentVariable("INTEL_OPENVINO_DIR", "C:\Program Files\Intel\openvino", "Machine")
```

## Usage with llama.cpp

### Build with OpenVINO Backend

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_OPENVINO=ON

cmake --build build --parallel
```

### Run with NPU

```bash
./build/bin/llama-server \
    -m model.gguf \
    --cache-type-k turbo3 \
    --cache-type-v turbo3 \
    -ngl 99
```

### Environment Variables

Control NPU behavior:

```bash
# Force NPU usage
export GGML_OPENVINO_DEVICE=NPU

# Or specify explicitly in command
GGML_OPENVINO_DEVICE=NPU ./llama-server -m model.gguf
```

## Optimization Tips

### 1. Layer Distribution

Optimal distribution for Intel Core Ultra 7 + GTX 1660:

```bash
# Most layers on GPU, overflow to NPU
-ngl 99  # Auto-distribute

# Manual control (if needed)
--n-gpu-layers 32   # GPU handles 32 layers
--n-npu-layers 8    # NPU handles 8 layers
```

### 2. Batch Size

NPU performs best with small batch sizes:

```bash
--batch-size 8      # NPU optimal
--ubatch-size 8     # Micro-batch size
```

### 3. Memory Management

```bash
# Disable mmap for better NPU access
--no-mmap

# Lock memory
--mlock
```

### 4. Threading

NPU is async, so adjust CPU threads:

```bash
--threads 4         # Reduce CPU threads when using NPU
```

## Monitoring

### Check NPU Usage

```bash
# Linux
cat /sys/class/accel/accel0/device/npu_busy_time_us

# Watch in real-time
watch -n 1 'cat /sys/class/accel/accel0/device/npu_busy_time_us'
```

### Performance Metrics

```bash
# Enable verbose logging
GGML_OPENVINO_DEBUG=1 ./llama-server -m model.gguf
```

Look for:
```
[OpenVINO] Device: NPU
[OpenVINO] Loaded layers: 8
[OpenVINO] Inference time: 45ms
```

## Troubleshooting

### NPU Not Detected

```bash
# Check driver
lsmod | grep intel_vpu

# Expected output:
intel_vpu_mmu          16384  1 intel_vpu
intel_vpu             114688  0

# If missing, reload driver
sudo modprobe intel_vpu
```

### Permission Issues

```bash
# Add user to render group
sudo usermod -a -G render $USER

# Logout and login again
```

### Performance Issues

1. **Check NPU is actually being used:**
   ```bash
   GGML_OPENVINO_DEBUG=1 ./llama-server -m model.gguf 2>&1 | grep NPU
   ```

2. **Verify driver version:**
   ```bash
   dpkg -l | grep intel-npu-driver
   ```

3. **Try different layer distributions**

### Compatibility

Not all models work optimally with NPU. Best results with:
- Llama family (1, 2, 3, 3.1)
- Qwen family (1.5, 2, 2.5)
- Gemma (1, 2)

## Advanced Configuration

### Custom OpenVINO Config

Create `openvino_config.json`:

```json
{
    "NPU": {
        "NUM_STREAMS": 1,
        "PERFORMANCE_HINT": "LATENCY",
        "CACHE_DIR": "/tmp/openvino_cache"
    }
}
```

Use with:
```bash
OPENVINO_CONFIG=openvino_config.json ./llama-server -m model.gguf
```

## Resources

- **Official Docs**: https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/OPENVINO.md
- **NPU Driver**: https://github.com/intel/linux-npu-driver
- **OpenVINO**: https://docs.openvino.ai/

## See Also

- [TurboQuant Paper](./turboquant-paper.md)
- [Agent Tools Guide](./agent-tools-guide.md)
