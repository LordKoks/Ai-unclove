# AI-unclove: Local LLM Setup with TurboQuant & RPC

![Build Status](https://github.com/LordKoks/Ai-unclove/actions/workflows/docker-build.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-lightgrey.svg)

**[English](#english)** | **[Русский](#russian)**

---

<a name="english"></a>
## English

### Overview

A complete, production-ready setup for running local Large Language Models (LLMs) with:
- **TurboQuant** (Google Research, 2026) - 3-bit KV-cache compression for 4.9-6x memory savings
- **OpenVINO NPU** support for Intel Core Ultra processors
- **vLLM** - highest performance OpenAI-compatible inference server
- **Open WebUI** - unified GUI for both chat and AI agent workflows
- **RPC-style networking** - weak PC can call strong PC over network

Perfect for running powerful LLMs on resource-constrained hardware or building distributed AI agent systems.

### Features

- **Two Operation Modes:**
  - **Weak PC**: Intel Core Ultra 7 + NPU + GTX 1660 8GB (llama.cpp + TurboQuant + OpenVINO)
  - **Strong PC**: High-end GPU workstation (vLLM with maximum performance)

- **OpenAI-Compatible API**: `/v1/chat/completions` with tool calling support
  - Use as simple chat assistant
  - Build AI agents with LangChain, CrewAI, AutoGen

- **Unified Interface**: Open WebUI connects to any setup, supports plugins/tools

- **Production Ready**: Docker-based, automated installation, CI/CD included

### Quick Start

#### Prerequisites

**Weak PC:**
- Intel Core Ultra 5/7/9 (with NPU)
- NVIDIA GPU 6GB+ (GTX 1660 or better)
- 16GB RAM
- Ubuntu 22.04 / Kali Linux / Windows 11

**Strong PC:**
- NVIDIA GPU 24GB+ (RTX 4090, A6000, etc.)
- 32GB+ RAM
- Ubuntu 22.04 / Windows 11

**Both:**
- Docker & Docker Compose
- 50GB+ free disk space

#### Installation

**1. Clone Repository:**
```bash
git clone https://github.com/LordKoks/Ai-unclove.git
cd Ai-unclove
```

**2. Run Installation Script:**

**Linux (Weak PC):**
```bash
sudo bash scripts/linux-install-weak.sh
```

**Linux (Strong PC):**
```bash
sudo bash scripts/linux-install-strong.sh
```

**Windows (Weak PC):**
```powershell
# Run PowerShell as Administrator
.\scripts\windows-install-weak.ps1
```

**Windows (Strong PC):**
```powershell
# Run PowerShell as Administrator
.\scripts\windows-install-strong.ps1
```

**3. Download a Model:**

**For Weak PC (GGUF format):**
```bash
cd models
wget https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf
```

**For Strong PC (HuggingFace format):**
```bash
pip install huggingface-hub
cd models
huggingface-cli download Qwen/Qwen2.5-14B-Instruct --local-dir ./Qwen2.5-14B-Instruct
```

**4. Configure:**

Edit the appropriate config file:
- Weak PC: `configs/weak-openvino-npu.env`
- Strong PC: `configs/strong-vllm.env`

Update `MODEL_NAME` to your downloaded model.

**5. Start Services:**

**Weak PC:**
```bash
cd docker/weak-llamacpp-turboquant
docker-compose up -d
```

**Strong PC:**
```bash
cd docker/strong-vllm
docker-compose up -d
```

**Open WebUI (both):**
```bash
cd docker/open-webui
docker-compose up -d
```

**6. Access:**

- **API**: http://localhost:8080
- **Open WebUI**: http://localhost:3000

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Weak PC Setup                       │
├─────────────────────────────────────────────────────────┤
│  llama.cpp + TurboQuant (3-bit KV-cache)                │
│  ├─ OpenVINO NPU Backend (Intel Core Ultra)            │
│  ├─ CUDA Backend (GTX 1660, fallback)                  │
│  └─ OpenAI API on :8080                                 │
│                                                          │
│  Open WebUI :3000 ──► connects to ──► :8080            │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Strong PC Setup                      │
├─────────────────────────────────────────────────────────┤
│  vLLM (Maximum Performance)                             │
│  ├─ Tensor Parallelism                                  │
│  ├─ Prefix Caching                                      │
│  └─ OpenAI API on :8080                                 │
│                                                          │
│  Open WebUI :3000 ──► connects to ──► :8080            │
└─────────────────────────────────────────────────────────┘

        RPC-Style Network Access (Optional)
┌──────────────┐          Network          ┌──────────────┐
│   Weak PC    │ ─────► :8080/v1 ─────►   │  Strong PC   │
│ (orchestrator)│      API calls           │ (heavy compute)│
└──────────────┘                           └──────────────┘
```

### Usage Examples

#### Simple Chat

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model",
    "messages": [
      {"role": "user", "content": "What is TurboQuant?"}
    ]
  }'
```

#### With Python OpenAI Client

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="your-model",
    messages=[
        {"role": "user", "content": "Explain quantum computing"}
    ]
)

print(response.choices[0].message.content)
```

#### AI Agent with Tools

```python
tools = [{
    "type": "function",
    "function": {
        "name": "calculate",
        "description": "Perform calculation",
        "parameters": {
            "type": "object",
            "properties": {
                "expression": {"type": "string"}
            }
        }
    }
}]

response = client.chat.completions.create(
    model="your-model",
    messages=[
        {"role": "user", "content": "What is 123 * 456?"}
    ],
    tools=tools
)
```

See [Agent Tools Guide](docs/agent-tools-guide.md) for complete examples.

### RPC Setup (Weak → Strong)

Configure weak PC to offload heavy tasks to strong PC:

**1. On Strong PC**, note the IP address:
```bash
ip addr show  # Linux
ipconfig      # Windows
```

**2. On Weak PC**, update Open WebUI config:
```bash
# Edit docker/open-webui/docker-compose.yml
environment:
  - OPENAI_API_BASE_URL=http://192.168.1.200:8080/v1  # Strong PC IP
```

**3. Restart Open WebUI:**
```bash
cd docker/open-webui
docker-compose restart
```

Now weak PC's GUI uses strong PC's compute power!

### Performance Expectations

#### Weak PC (Intel Core Ultra 7 + NPU + GTX 1660 8GB)

**Model: Qwen2.5-7B Q4_K_M + TurboQuant**

| Metric | Value |
|--------|-------|
| Prompt Processing | 150-200 tokens/sec |
| Generation Speed | 25-35 tokens/sec |
| Context Length | 32K (up to 64K) |
| CPU Usage | <20% (thanks to NPU) |
| GPU VRAM | 5-6 GB |
| Power Draw | 8-12W (NPU mode) |

#### Strong PC (RTX 4090)

**Model: Qwen2.5-14B BF16 + vLLM**

| Metric | Value |
|--------|-------|
| Prompt Processing | 800-1200 tokens/sec |
| Generation Speed | 80-120 tokens/sec |
| Context Length | 64K+ |
| GPU VRAM | 18-20 GB |
| Batch Throughput | 500+ req/min |

### Documentation

- **[TurboQuant Technical Details](docs/turboquant-paper.md)** - KV-cache compression explained
- **[OpenVINO NPU Setup](docs/openvino-npu-guide.md)** - Intel NPU configuration
- **[AI Agent Tools](docs/agent-tools-guide.md)** - Building agents with LangChain/CrewAI

### Recommended Models

**Weak PC (GGUF Q4_K_M):**
- [Qwen2.5-7B-Instruct](https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF) - Best overall
- [Llama-3.1-8B-Instruct](https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF) - General purpose
- [Gemma-2-9B-IT](https://huggingface.co/bartowski/gemma-2-9b-it-GGUF) - Google model

**Strong PC (Full precision):**
- [Qwen2.5-14B/32B](https://huggingface.co/Qwen/Qwen2.5-14B-Instruct) - Powerful reasoning
- [Llama-3.1-70B](https://huggingface.co/meta-llama/Meta-Llama-3.1-70B-Instruct) - Enterprise grade
- [DeepSeek-Coder-V2](https://huggingface.co/deepseek-ai/DeepSeek-Coder-V2-Instruct) - Best for code

### Troubleshooting

**NPU Not Detected:**
```bash
# Check NPU driver
ls -la /dev/accel/accel*

# If missing, reinstall driver
wget https://github.com/intel/linux-npu-driver/releases/latest/download/intel-npu-driver_1.0.0_amd64.deb
sudo dpkg -i intel-npu-driver_1.0.0_amd64.deb
```

**High CPU Usage on Weak PC:**
- Verify NPU is active: `GGML_OPENVINO_DEBUG=1` in environment
- Check OpenVINO installation: `ls /opt/intel/openvino_2024`

**Docker Container Won't Start:**
```bash
# Check logs
docker-compose logs

# Rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**Out of Memory:**
- Reduce context size: `CONTEXT_SIZE=16384` in config
- Use smaller quantization: Q4_K_S instead of Q4_K_M
- Enable mmap: remove `--no-mmap` from command

### Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

### References

- **TurboQuant Paper**: https://arxiv.org/abs/2504.19874
- **Google Research Blog**: https://research.google/blog/turboquant-redefining-ai-efficiency-with-extreme-compression/
- **llama.cpp TurboQuant**: https://github.com/TheTom/llama-cpp-turboquant
- **llama.cpp OpenVINO**: https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/OPENVINO.md
- **Intel NPU Driver**: https://github.com/intel/linux-npu-driver
- **vLLM Docs**: https://docs.vllm.ai/
- **Open WebUI**: https://docs.openwebui.com/

### License

MIT License - see [LICENSE](LICENSE) for details

---

<a name="russian"></a>
## Русский

### Обзор

Полностью готовая к использованию система для запуска локальных больших языковых моделей (LLM) с:
- **TurboQuant** (Google Research, 2026) - сжатие KV-cache в 3 бита для экономии памяти в 4.9-6 раз
- Поддержка **OpenVINO NPU** для процессоров Intel Core Ultra
- **vLLM** - самый производительный сервер inference с OpenAI-совместимым API
- **Open WebUI** - единый GUI для чата и AI-агентов
- **RPC-подобная сеть** - слабый ПК может вызывать API сильного ПК

Идеально для запуска мощных LLM на слабом железе или построения распределённых систем AI-агентов.

### Возможности

- **Два режима работы:**
  - **Слабый ПК**: Intel Core Ultra 7 + NPU + GTX 1660 8GB (llama.cpp + TurboQuant + OpenVINO)
  - **Сильный ПК**: Мощная рабочая станция (vLLM с максимальной производительностью)

- **OpenAI-совместимое API**: `/v1/chat/completions` с поддержкой tool calling
  - Простой чат-ассистент
  - AI-агенты с LangChain, CrewAI, AutoGen

- **Единый интерфейс**: Open WebUI подключается к любой конфигурации, поддерживает плагины

- **Production-ready**: Docker, автоматическая установка, CI/CD

### Быстрый старт

#### Требования

**Слабый ПК:**
- Intel Core Ultra 5/7/9 (с NPU)
- NVIDIA GPU 6GB+ (GTX 1660 или лучше)
- 16GB RAM
- Ubuntu 22.04 / Kali Linux / Windows 11

**Сильный ПК:**
- NVIDIA GPU 24GB+ (RTX 4090, A6000 и т.д.)
- 32GB+ RAM
- Ubuntu 22.04 / Windows 11

**Для обоих:**
- Docker и Docker Compose
- 50GB+ свободного места

#### Установка

**1. Клонировать репозиторий:**
```bash
git clone https://github.com/LordKoks/Ai-unclove.git
cd Ai-unclove
```

**2. Запустить скрипт установки:**

**Linux (слабый ПК):**
```bash
sudo bash scripts/linux-install-weak.sh
```

**Linux (сильный ПК):**
```bash
sudo bash scripts/linux-install-strong.sh
```

**Windows (слабый ПК):**
```powershell
# Запустить PowerShell от имени Администратора
.\scripts\windows-install-weak.ps1
```

**Windows (сильный ПК):**
```powershell
# Запустить PowerShell от имени Администратора
.\scripts\windows-install-strong.ps1
```

**3. Скачать модель:**

**Для слабого ПК (формат GGUF):**
```bash
cd models
wget https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf
```

**Для сильного ПК (формат HuggingFace):**
```bash
pip install huggingface-hub
cd models
huggingface-cli download Qwen/Qwen2.5-14B-Instruct --local-dir ./Qwen2.5-14B-Instruct
```

**4. Настроить:**

Отредактируйте соответствующий файл конфигурации:
- Слабый ПК: `configs/weak-openvino-npu.env`
- Сильный ПК: `configs/strong-vllm.env`

Обновите `MODEL_NAME` на имя скачанной модели.

**5. Запустить сервисы:**

**Слабый ПК:**
```bash
cd docker/weak-llamacpp-turboquant
docker-compose up -d
```

**Сильный ПК:**
```bash
cd docker/strong-vllm
docker-compose up -d
```

**Open WebUI (для обоих):**
```bash
cd docker/open-webui
docker-compose up -d
```

**6. Доступ:**

- **API**: http://localhost:8080
- **Open WebUI**: http://localhost:3000

### Архитектура

См. раздел на английском для визуальной схемы.

### Примеры использования

#### Простой чат

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model",
    "messages": [
      {"role": "user", "content": "Что такое TurboQuant?"}
    ]
  }'
```

#### С Python OpenAI клиентом

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="your-model",
    messages=[
        {"role": "user", "content": "Объясни квантовые вычисления"}
    ]
)

print(response.choices[0].message.content)
```

Подробные примеры см. в [Руководстве по AI-агентам](docs/agent-tools-guide.md).

### Настройка RPC (Слабый → Сильный)

**1. На сильном ПК** узнайте IP-адрес:
```bash
ip addr show  # Linux
ipconfig      # Windows
```

**2. На слабом ПК** обновите конфиг Open WebUI:
```bash
# Редактировать docker/open-webui/docker-compose.yml
environment:
  - OPENAI_API_BASE_URL=http://192.168.1.200:8080/v1  # IP сильного ПК
```

**3. Перезапустить Open WebUI:**
```bash
cd docker/open-webui
docker-compose restart
```

### Ожидаемая производительность

#### Слабый ПК (Intel Core Ultra 7 + NPU + GTX 1660 8GB)

**Модель: Qwen2.5-7B Q4_K_M + TurboQuant**

| Метрика | Значение |
|---------|----------|
| Обработка промпта | 150-200 токенов/сек |
| Генерация | 25-35 токенов/сек |
| Длина контекста | 32K (до 64K) |
| Нагрузка CPU | <20% (благодаря NPU) |
| GPU VRAM | 5-6 GB |
| Энергопотребление | 8-12W (режим NPU) |

#### Сильный ПК (RTX 4090)

**Модель: Qwen2.5-14B BF16 + vLLM**

| Метрика | Значение |
|---------|----------|
| Обработка промпта | 800-1200 токенов/сек |
| Генерация | 80-120 токенов/сек |
| Длина контекста | 64K+ |
| GPU VRAM | 18-20 GB |
| Пропускная способность | 500+ запросов/мин |

### Документация

- **[Технические детали TurboQuant](docs/turboquant-paper.md)** - Объяснение сжатия KV-cache
- **[Настройка OpenVINO NPU](docs/openvino-npu-guide.md)** - Конфигурация Intel NPU
- **[AI-агенты и инструменты](docs/agent-tools-guide.md)** - Создание агентов с LangChain/CrewAI

### Рекомендуемые модели

**Слабый ПК (GGUF Q4_K_M):**
- [Qwen2.5-7B-Instruct](https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF) - Лучшая в целом
- [Llama-3.1-8B-Instruct](https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF) - Универсальная
- [Gemma-2-9B-IT](https://huggingface.co/bartowski/gemma-2-9b-it-GGUF) - Модель Google

**Сильный ПК (полная точность):**
- [Qwen2.5-14B/32B](https://huggingface.co/Qwen/Qwen2.5-14B-Instruct) - Мощное рассуждение
- [Llama-3.1-70B](https://huggingface.co/meta-llama/Meta-Llama-3.1-70B-Instruct) - Enterprise-уровень
- [DeepSeek-Coder-V2](https://huggingface.co/deepseek-ai/DeepSeek-Coder-V2-Instruct) - Лучшая для кода

### Решение проблем

См. раздел на английском для подробных инструкций.

### Ссылки

- **Статья TurboQuant**: https://arxiv.org/abs/2504.19874
- **Блог Google Research**: https://research.google/blog/turboquant-redefining-ai-efficiency-with-extreme-compression/
- **llama.cpp TurboQuant**: https://github.com/TheTom/llama-cpp-turboquant
- **llama.cpp OpenVINO**: https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/OPENVINO.md
- **Драйвер Intel NPU**: https://github.com/intel/linux-npu-driver
- **Документация vLLM**: https://docs.vllm.ai/
- **Open WebUI**: https://docs.openwebui.com/

### Лицензия

Лицензия MIT - см. [LICENSE](LICENSE) для деталей

---

## Support

For issues and questions:
- GitHub Issues: https://github.com/LordKoks/Ai-unclove/issues
- Discussions: https://github.com/LordKoks/Ai-unclove/discussions

## Acknowledgments

- Google Research for TurboQuant
- Intel for OpenVINO and NPU drivers
- llama.cpp team
- vLLM team
- Open WebUI team