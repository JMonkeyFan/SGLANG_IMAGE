FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# 1. System dependencies (libnuma is the big one we need)
RUN apt-get update && apt-get install -y \
    git \
    libnuma-dev \
    gcc \
    g++ \
    --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Upgrade core python tools
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 3. Install FlashInfer (Verified working in your last log!)
RUN pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/

# 4. Install SGLang and Transformers using the versions confirmed by the logs
# Note: Using sglang==0.5.10.post1 and latest available transformers
RUN pip install --no-cache-dir \
    "sglang[all]==0.5.10.post1" \
    "transformers>=4.45.0" \
    hf-transfer

# 5. Copy your handler/app code
COPY . .