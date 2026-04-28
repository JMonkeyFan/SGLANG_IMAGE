FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# 1. System dependencies
RUN apt-get update && apt-get install -y \
    git \
    libnuma-dev \
    gcc \
    g++ \
    --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Upgrade core python tools
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 3. Install FlashInfer separately (This is the most likely failure point)
# Note: I've updated the link to the 2026-standard index format
RUN pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/

# 4. Install SGLang and Transformers
# We use 'transformers>=5.0.0' for native Qwen3.6 support
RUN pip install --no-cache-dir "sglang[all]>=0.6.0" "transformers>=5.2.0" hf-transfer

# 5. Copy your handler/app code
COPY . .