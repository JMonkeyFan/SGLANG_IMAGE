FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1 

# Install system tools
RUN apt-get update && apt-get install -y git libnuma-dev gcc g++ --no-install-recommends && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install SGLang and requirements
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/ && \
    pip install --no-cache-dir "sglang[all]==0.5.10.post1" "transformers>=4.45.0" hf-transfer gguf

# We leave the surgery out of the Dockerfile and do it in the start script or just rely on the GGUF rename
COPY . .

# No CMD here, we will provide it in the RunPod UI