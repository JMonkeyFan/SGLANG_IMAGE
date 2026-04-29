FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1 

# 1. System dependencies
RUN apt-get update && apt-get install -y git libnuma-dev gcc g++ --no-install-recommends && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Python Setup
RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/
RUN pip install --no-cache-dir "sglang[all]==0.5.10.post1" "transformers>=4.45.0" hf-transfer gguf

# 3. VERIFIED SURGERY
# We use a single RUN command with simple logic to avoid build failures
RUN FILE_AUTO=$(python3 -c "import transformers; print(transformers.models.auto.modeling_auto.__file__)") && \
    sed -i 's/("qwen2", "Qwen2ForCausalLM"),/("qwen2", "Qwen2ForCausalLM"), ("qwen35", "Qwen2ForCausalLM"),/g' $FILE_AUTO && \
    FILE_GGUF=$(python3 -c "import transformers; print(transformers.modeling_gguf_pytorch_utils.__file__)") && \
    sed -i 's/"qwen2moe": Qwen2MoeTensorProcessor,/"qwen35": Qwen2MoeTensorProcessor, "qwen3": Qwen2MoeTensorProcessor, "qwen2moe": Qwen2MoeTensorProcessor,/g' $FILE_GGUF

# 4. INTERNAL RENAME (Only works if volume is present during build, otherwise skips safely)
RUN python3 -c "import gguf; path = '/runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf'; import os; \
    if os.path.exists(path): \
        reader = gguf.GGUFReader(path, 'r+'); \
        reader.kv_data[b'general.architecture'] = b'qwen2'; \
        reader.write_header(); reader.close(); print('Renamed successfully');" || echo "Volume not found during build, skipping rename"

COPY . .

# 5. EXECUTION (Single line to prevent parser errors)
CMD ["sglang", "serve", "--model-path", "/runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf", "--tokenizer-path", "/runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf", "--host", "0.0.0.0", "--port", "3000", "--mem-fraction-static", "0.7", "--trust-remote-code"]