# Use the official SGLang dev image which already has the nightly build and kernels
FROM lmsysorg/sglang:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Install only the extra GGUF/Transformer requirements 
# We don't reinstall SGLang to avoid breaking the pre-compiled kernels
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir "transformers>=5.3.0" hf-transfer gguf

# Apply Architecture Surgery for Qwen 3.6 GGUF Support
# Note: Path is slightly different in this base image
RUN sed -i 's/("qwen2", "Qwen2ForCausalLM"),/("qwen2", "Qwen2ForCausalLM"), ("qwen35", "Qwen2ForCausalLM"),/g' /usr/local/lib/python3.10/dist-packages/transformers/models/auto/modeling_auto.py && \
    sed -i 's/"qwen2moe": Qwen2MoeTensorProcessor,/"qwen35": Qwen2MoeTensorProcessor, "qwen3": Qwen2MoeTensorProcessor, "qwen2moe": Qwen2MoeTensorProcessor,/g' /usr/local/lib/python3.10/dist-packages/transformers/modeling_gguf_pytorch_utils.py

# RunPod Serverless Mount Point
WORKDIR /runpod-volume

# Reasoning & Networking Defaults
ENV SGLANG_REASONING_PRESERVE_THINKING=1
ENV PORT=3000
ENV PORT_HEALTH=3000

# Explicitly launch the server
CMD ["sh", "-c", "python3 -m sglang.launch_server $SGLANG_ARGS"]