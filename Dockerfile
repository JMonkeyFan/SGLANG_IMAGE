FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# System setup
ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Install SGLang & FlashInfer
RUN apt-get update && apt-get install -y git --no-install-recommends && \
    pip install --upgrade pip && \
    pip install "sglang[all]>=0.5.0" --find-links https://flashinfer.ai/whl/cu121/torch2.4/flashinfer && \
    pip install hf-transfer && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# No CMD needed here, we will define it in the Template