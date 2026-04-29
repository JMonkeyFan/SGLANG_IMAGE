FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1 

RUN apt-get update && apt-get install -y git libnuma-dev gcc g++ --no-install-recommends && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/ && \
    pip install --no-cache-dir "sglang[all]==0.5.10.post1" "transformers>=4.45.0" hf-transfer gguf

# Copy your files (including entrypoint.sh)
COPY . .

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set the script as the starting command
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]