# TurboQuant: Extreme LLM KV-Cache Compression

## Overview

TurboQuant is a groundbreaking quantization technique developed by Google Research (ICLR 2026) that enables **extreme compression of KV-cache** in Large Language Models, achieving **4.9-6x memory reduction** with minimal quality degradation.

## Key Features

- **3-bit KV-cache quantization** (vs standard 16-bit)
- **Minimal perplexity increase** (<0.1 on most benchmarks)
- **Compatible with existing GGUF models**
- **Works with llama.cpp** through specialized fork
- **Enables longer context** on resource-constrained hardware

## How It Works

### Traditional KV-Cache

In standard transformer inference:
- Each token's Key and Value vectors are cached
- Stored in FP16 or BF16 (16 bits per value)
- Memory usage: `2 × n_layers × n_ctx × d_model × 2 bytes`

For a 7B model with 32K context:
```
Memory = 2 × 32 × 32768 × 4096 × 2 bytes ≈ 16 GB
```

### TurboQuant Approach

TurboQuant quantizes KV-cache to 3-bit:
```
Memory = 2 × 32 × 32768 × 4096 × 0.375 bytes ≈ 3 GB
```

**Memory savings: ~5.3x reduction**

### Technical Details

1. **Per-Channel Quantization**
   - Separate scaling factors for each attention head
   - Preserves fine-grained information

2. **Asymmetric Quantization**
   - Different quantization ranges for Keys vs Values
   - Optimized for attention computation patterns

3. **Group-wise Scaling**
   - Dynamic scaling per token group
   - Adapts to content distribution

## Implementation

### Using with llama.cpp

```bash
# Clone TurboQuant fork
git clone https://github.com/TheTom/llama-cpp-turboquant.git
cd llama-cpp-turboquant
git checkout feature/turboquant-kv-cache

# Build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Run with TurboQuant
./build/bin/llama-server \
    -m model.gguf \
    --cache-type-k turbo3 \
    --cache-type-v turbo3 \
    -c 32768
```

### Cache Type Options

- `turbo3`: 3-bit (maximum compression, recommended)
- `turbo4`: 4-bit (slightly better quality)
- `q8_0`: 8-bit (fallback, less compression)
- `f16`: 16-bit (no compression, baseline)

## Performance Benchmarks

### Memory Usage (7B model, 32K context)

| Cache Type | Memory | Compression Ratio |
|------------|--------|-------------------|
| f16        | 16 GB  | 1.0x (baseline)   |
| q8_0       | 8 GB   | 2.0x              |
| turbo4     | 4 GB   | 4.0x              |
| turbo3     | 3 GB   | 5.3x              |

### Quality Impact (Perplexity)

| Model | Baseline | TurboQuant | Δ PPL |
|-------|----------|------------|-------|
| Llama-3.1-8B | 6.42 | 6.48 | +0.06 |
| Qwen2.5-7B   | 5.89 | 5.94 | +0.05 |
| Gemma-2-9B   | 6.15 | 6.22 | +0.07 |

### Speed Impact

- **Encoding**: ~5% slower (quantization overhead)
- **Decoding**: ~2% faster (smaller cache access)
- **Overall**: Negligible impact on throughput

## Benefits for Weak PC Setup

### With Intel Core Ultra 7 + NPU + GTX 1660 8GB

**Scenario: Running Qwen2.5-7B with 32K context**

#### Without TurboQuant
- Model weights: 4 GB (Q4_K_M)
- KV-cache: 16 GB
- **Total: 20 GB → Impossible on 8GB GPU**

#### With TurboQuant
- Model weights: 4 GB (Q4_K_M)
- KV-cache: 3 GB
- **Total: 7 GB → Fits comfortably!**

### Additional Benefits

1. **NPU Offloading**: With reduced KV-cache, NPU can handle more work
2. **Lower CPU Load**: Less memory bandwidth pressure
3. **Longer Contexts**: Can extend to 64K+ context on same hardware
4. **Better Batching**: Can process multiple requests simultaneously

## Limitations

- **Experimental**: TurboQuant is cutting-edge research (2026)
- **Fork Dependency**: Requires specific llama.cpp fork
- **Model Support**: Best tested on Llama, Qwen, Gemma families
- **Quality**: Slight degradation on very long contexts (>64K)

## References

- **Paper**: [TurboQuant: Redefining AI Efficiency](https://arxiv.org/abs/2504.19874) (arXiv:2504.19874)
- **Google Research Blog**: [TurboQuant Announcement](https://research.google/blog/turboquant-redefining-ai-efficiency-with-extreme-compression/)
- **Implementation**: [llama-cpp-turboquant fork](https://github.com/TheTom/llama-cpp-turboquant)
- **Extended Version**: [TurboQuant Plus](https://github.com/TheTom/turboquant_plus)

## See Also

- [OpenVINO NPU Guide](./openvino-npu-guide.md)
- [Agent Tools Guide](./agent-tools-guide.md)
