# Models Directory

This directory should contain your LLM models.

## For Weak PC (llama.cpp + TurboQuant)

Download GGUF quantized models. Recommended models:

### Recommended Models

1. **Qwen2.5 7B** (Best for code and reasoning)
   ```bash
   wget https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf
   ```

2. **Llama 3.1 8B** (General purpose)
   ```bash
   wget https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf
   ```

3. **Gemma 2 9B** (Google model)
   ```bash
   wget https://huggingface.co/bartowski/gemma-2-9b-it-GGUF/resolve/main/gemma-2-9b-it-Q4_K_M.gguf
   ```

### Using HuggingFace CLI

```bash
pip install huggingface-hub

# Download with HF CLI
huggingface-cli download Qwen/Qwen2.5-7B-Instruct-GGUF qwen2.5-7b-instruct-q4_k_m.gguf --local-dir .
```

## For Strong PC (vLLM)

Download full HuggingFace models:

### Recommended Models

1. **Qwen2.5 14B/32B** (Powerful reasoning)
   ```bash
   huggingface-cli download Qwen/Qwen2.5-14B-Instruct --local-dir ./Qwen2.5-14B-Instruct
   ```

2. **Llama 3.1 70B** (High performance)
   ```bash
   huggingface-cli download meta-llama/Meta-Llama-3.1-70B-Instruct --local-dir ./Meta-Llama-3.1-70B-Instruct
   ```

3. **DeepSeek Coder V2** (Best for coding)
   ```bash
   huggingface-cli download deepseek-ai/DeepSeek-Coder-V2-Instruct --local-dir ./DeepSeek-Coder-V2-Instruct
   ```

## Quantization Recommendations

- **Weak PC**: Use Q4_K_M or Q5_K_M quantization for best balance of quality/performance
- **TurboQuant**: The 3-bit KV-cache compression is applied automatically, giving 4.9-6x memory savings
- **Strong PC**: Use FP16 or BF16 for maximum quality

## After Downloading

1. Update the model name in the corresponding config file:
   - Weak PC: `configs/weak-openvino-npu.env`
   - Strong PC: `configs/strong-vllm.env`

2. Restart your Docker containers:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Storage Requirements

- GGUF Q4_K_M 7B model: ~4-5 GB
- GGUF Q4_K_M 13B model: ~7-8 GB
- Full FP16 7B model: ~14 GB
- Full FP16 70B model: ~140 GB

## Notes

- This directory is mounted as read-only in Docker containers
- Models are shared between different setups
- Keep models organized in subdirectories if you have multiple
