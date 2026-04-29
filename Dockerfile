FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Install system dependencies
RUN apt-get update && apt-get install -y git libnuma-dev gcc g++ --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install SGLang Nightly + Qwen 3.6 dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/ && \
    pip install --no-cache-dir "git+https://github.com/sgl-project/sglang.git#egg=sglang[all]" \
    "transformers>=5.3.0" \
    hf-transfer \
    gguf

# Apply Architecture Surgery for Qwen 3.6 GGUF Support
RUN sed -i 's/("qwen2", "Qwen2ForCausalLM"),/("qwen2", "Qwen2ForCausalLM"), ("qwen35", "Qwen2ForCausalLM"),/g' /usr/local/lib/python3.11/dist-packages/transformers/models/auto/modeling_auto.py && \
    sed -i 's/"qwen2moe": Qwen2MoeTensorProcessor,/"qwen35": Qwen2MoeTensorProcessor, "qwen3": Qwen2MoeTensorProcessor, "qwen2moe": Qwen2MoeTensorProcessor,/g' /usr/local/lib/python3.11/dist-packages/transformers/modeling_gguf_pytorch_utils.py

# Set Serverless Mount Point as WORKDIR
WORKDIR /runpod-volume

# Global Env Vars
ENV SGLANG_REASONING_PRESERVE_THINKING=1
ENV PORT=3000
ENV PORT_HEALTH=3000

# Explicitly launch using the environment variable string
CMD ["sh", "-c", "python3 -m sglang.launch_server $SGLANG_ARGS"]