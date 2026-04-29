#!/bin/bash
echo "------------------------------------------"
echo "I AM ALIVE: STARTING CUSTOM ENTRYPOINT"
echo "------------------------------------------"
# 1. Run the library surgery
echo "Starting library surgery..."
FILE_AUTO=$(python3 -c "import transformers; print(transformers.models.auto.modeling_auto.__file__)" 2>/dev/null)
if [ -f "$FILE_AUTO" ]; then
    sed -i 's/("qwen2", "Qwen2ForCausalLM"),/("qwen2", "Qwen2ForCausalLM"), ("qwen35", "Qwen2ForCausalLM"),/g' "$FILE_AUTO"
    echo "Surgery on modeling_auto.py successful."
fi

FILE_GGUF=$(python3 -c "import transformers; print(transformers.modeling_gguf_pytorch_utils.__file__)" 2>/dev/null)
if [ -f "$FILE_GGUF" ]; then
    sed -i 's/"qwen2moe": Qwen2MoeTensorProcessor,/"qwen35": Qwen2MoeTensorProcessor, "qwen3": Qwen2MoeTensorProcessor, "qwen2moe": Qwen2MoeTensorProcessor,/g' "$FILE_GGUF"
    echo "Surgery on gguf_utils.py successful."
fi

# 2. Launch SGLang (Using the environment variables you set in RunPod)
echo "Launching SGLang..."
exec sglang serve \
  --model-path /runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf \
  --tokenizer-path /runpod-volume/Qwen3.6-27B-heretic-heretic2.Q8_0.gguf \
  --host 0.0.0.0 \
  --port 3000 \
  --mem-fraction-static 0.7 \
  --trust-remote-code