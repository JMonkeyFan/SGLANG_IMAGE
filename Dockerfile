# Use the official SGLang dev image (contains pre-compiled kernels)
FROM lmsysorg/sglang:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Install only the light requirements needed for GGUF/Qwen 3.6
# We don't reinstall SGLang to keep the highly-optimized built-in version
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir "transformers>=5.3.0" hf-transfer gguf

# Apply Architecture Surgery for Qwen 3.6 GGUF Support
# This dynamic version finds the correct path for modeling_auto.py and modeling_gguf_pytorch_utils.py automatically
RUN export TRANSFORMERS_PATH=$(python3 -c "import transformers; import os; print(os.path.dirname(transformers.__file__))") && \
    sed -i 's/("qwen2", "Qwen2ForCausalLM"),/("qwen2", "Qwen2ForCausalLM"), ("qwen35", "Qwen2ForCausalLM"),/g' ${TRANSFORMERS_PATH}/models/auto/modeling_auto.py && \
    sed -i 's/"qwen2moe": Qwen2MoeTensorProcessor,/"qwen35": Qwen2MoeTensorProcessor, "qwen3": Qwen2MoeTensorProcessor, "qwen2moe": Qwen2MoeTensorProcessor,/g' ${TRANSFORMERS_PATH}/modeling_gguf_pytorch_utils.py

# RunPod Serverless Mount Point
WORKDIR /runpod-volume

# Reasoning & Networking Defaults
ENV SGLANG_REASONING_PRESERVE_THINKING=1
ENV PORT=3000
ENV PORT_HEALTH=3000

# Explicitly launch the server
CMD ["sh", "-c", "python3 -m sglang.launch_server $SGLANG_ARGS"]