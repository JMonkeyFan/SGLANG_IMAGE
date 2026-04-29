FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1 

# 1. System dependencies
RUN apt-get update && apt-get install -y git libnuma-dev gcc g++ --no-install-recommends && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Python Setup & Surgery (Combined to ensure paths exist)
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/ && \
    pip install --no-cache-dir "sglang[all]==0.5.10.post1" "transformers>=4.45.0" hf-transfer gguf && \
    # The Surgery starts here, only after pip install is done
    FILE_AUTO=$(python3 -c "import transformers; print(transformers.models.auto.modeling_auto.__file__)" 2>/dev/null) && \
    if [ -f "$FILE_AUTO" ]; then \
        sed -i 's/("qwen2", "Qwen2ForCausalLM"),/("qwen2", "Qwen2ForCausalLM"), ("qwen35", "Qwen2ForCausalLM"),/g' $FILE_AUTO; \
    fi && \
    FILE_GGUF=$(python3 -c "import transformers; print(transformers.modeling_gguf_pytorch_utils.__file__)" 2>/dev/null) && \
    if [ -f "$FILE_GGUF" ]; then \
        sed -i 's/"qwen2moe": Qwen2MoeTensorProcessor,/"qwen35": Qwen2MoeTensorProcessor, "qwen3": Qwen2MoeTensorProcessor, "qwen2moe": Qwen2MoeTensorProcessor,/g' $FILE_GGUF; \
    fi

# 3. GGUF Internal Rename (Safety wrapped)
RUN python3 -c "import os; \
    path = '/runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf'; \
    if os.path.exists(path): \
        import gguf; \
        reader = gguf.GGUFReader(path, 'r+'); \
        reader.kv_data[b'general.architecture'] = b'qwen2'; \
        reader.write_header(); reader.close(); \
        print('GGUF architecture set to qwen2');" || echo "Volume not accessible during build"

COPY . .

# 4. EXECUTION
CMD ["sglang", "serve", "--model-path", "/runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf", "--tokenizer-path", "/runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf", "--host", "0.0.0.0", "--port", "3000", "--mem-fraction-static", "0.7", "--trust-remote-code"]