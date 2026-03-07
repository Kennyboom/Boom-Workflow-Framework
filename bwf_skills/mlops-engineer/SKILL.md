---
name: mlops-engineer
description: Deploy, monitor, and optimize ML/LLM systems in production. Covers model serving (vLLM/Ollama), fine-tuning (LoRA/QLoRA), evaluation, monitoring, guardrails, cost optimization, and CI/CD for ML.
---

# MLOps / LLMOps Engineer

Expert guidance for operationalizing ML and LLM systems in production.

## When to Use

- Deploying ML/LLM models to production
- Model serving infrastructure
- Fine-tuning LLMs (LoRA/QLoRA)
- Monitoring performance and costs
- Building evaluation and guardrail pipelines

---

## 1. Model Serving

### Stack Comparison
| Tool | Best For | GPU | Deployment |
|------|----------|-----|------------|
| **vLLM** | High-throughput | Yes | Self-hosted |
| **TGI** | HuggingFace models | Yes | Self-hosted/HF |
| **Ollama** | Local dev | Optional | Local |
| **Triton** | Multi-model | Yes | Self-hosted |
| **OpenAI API** | Quick start | No | Managed |

### vLLM (Production)
```bash
pip install vllm

python -m vllm.entrypoints.openai.api_server \
    --model meta-llama/Llama-3.1-8B-Instruct \
    --tensor-parallel-size 2 \
    --max-model-len 8192 \
    --gpu-memory-utilization 0.9 \
    --port 8000
```

### Ollama (Local)
```bash
ollama pull llama3.1:8b
ollama run llama3.1:8b

# Custom Modelfile
FROM llama3.1:8b
SYSTEM "You are a helpful coding assistant."
PARAMETER temperature 0.3
```

### Docker Deployment
```dockerfile
FROM vllm/vllm-openai:latest
ENV MODEL_NAME=meta-llama/Llama-3.1-8B-Instruct
CMD ["python", "-m", "vllm.entrypoints.openai.api_server", \
     "--model", "${MODEL_NAME}", "--port", "8000"]
```

## 2. Fine-Tuning (LoRA/QLoRA)

### When to Fine-Tune vs Prompt Engineer
```
Prompt Engineering:        Fine-Tuning:
✅ <100 examples           ✅ 500+ high-quality examples
✅ Quick iteration         ✅ Consistent output format
✅ Task describable        ✅ Domain-specific knowledge
                           ✅ Cost optimization (smaller model)
```

### QLoRA Fine-Tuning
```python
from transformers import AutoModelForCausalLM, TrainingArguments
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from trl import SFTTrainer

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-8B-Instruct",
    quantization_config=BitsAndBytesConfig(
        load_in_4bit=True, bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
    ),
    device_map="auto",
)
model = prepare_model_for_kbit_training(model)

lora_config = LoraConfig(
    r=16, lora_alpha=32,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
    lora_dropout=0.05, task_type="CAUSAL_LM",
)
model = get_peft_model(model, lora_config)

trainer = SFTTrainer(
    model=model, train_dataset=dataset,
    args=TrainingArguments(
        output_dir="./output", num_train_epochs=3,
        per_device_train_batch_size=4,
        gradient_accumulation_steps=4,
        learning_rate=2e-4, bf16=True,
    ),
    max_seq_length=2048,
)
trainer.train()
```

### Dataset Format
```python
dataset = [
    {"messages": [
        {"role": "system", "content": "Medical coding assistant."},
        {"role": "user", "content": "ICD-10 for type 2 diabetes?"},
        {"role": "assistant", "content": "E11 - Type 2 diabetes mellitus"},
    ]},
]
```

## 3. Evaluation

### LLM-as-Judge
```python
JUDGE_PROMPT = """Rate the AI response (1-5) for:
1. Accuracy  2. Completeness  3. Clarity  4. Relevance

Question: {question}
Response: {response}
Reference: {reference}

Respond JSON: {{"accuracy":X,"completeness":X,"clarity":X,"relevance":X}}"""

def evaluate_response(question, response, reference):
    result = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": JUDGE_PROMPT.format(
            question=question, response=response, reference=reference
        )}],
        response_format={"type": "json_object"},
    )
    return json.loads(result.choices[0].message.content)
```

### Evaluation Pipeline
```python
def run_eval(model_name: str, test_set: list) -> dict:
    results = []
    for test in test_set:
        response = generate(model_name, test["input"])
        scores = evaluate_response(test["input"], response, test["expected"])
        results.append({**test, "scores": scores})

    return {
        "model": model_name,
        "avg_accuracy": sum(r["scores"]["accuracy"] for r in results) / len(results),
        "pass_rate": sum(1 for r in results if r["scores"]["accuracy"] >= 4) / len(results),
    }
```

## 4. Monitoring

### Key Metrics
```
Latency:  TTFT, tokens/sec, end-to-end, queue wait
Quality:  hallucination rate, user feedback, task completion
Cost:     tokens (in/out), cost/user/day, cache hit rate
Infra:    GPU utilization, memory, queue depth
```

### Prometheus Metrics
```python
from prometheus_client import Counter, Histogram, Gauge

llm_requests = Counter('llm_requests_total', 'Total requests', ['model', 'status'])
llm_latency = Histogram('llm_latency_seconds', 'Response time', ['model'])
llm_tokens = Counter('llm_tokens_total', 'Tokens used', ['model', 'direction'])

with llm_latency.labels(model="gpt-4o").time():
    response = client.chat.completions.create(...)
llm_tokens.labels(model="gpt-4o", direction="input").inc(response.usage.prompt_tokens)
```

### LangSmith Tracing
```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "YOUR_KEY"
# All LangChain calls automatically traced
```

## 5. Guardrails

### LlamaGuard (Content Safety)
```python
def check_safety(text: str) -> dict:
    prompt = f"[INST] Task: Check safety.\n\n{text} [/INST]"
    output = guard_model.generate(tokenizer.encode(prompt, return_tensors="pt"))
    result = tokenizer.decode(output[0])
    return {"safe": "safe" in result.lower()}
```

### NeMo Guardrails
```yaml
models:
  - type: main
    engine: openai
    model: gpt-4o
rails:
  input:
    flows: [self check input]
  output:
    flows: [self check output, check facts]
```

## 6. Cost Optimization

| Strategy | Savings | How |
|----------|---------|-----|
| **Model routing** | 60-80% | GPT-4o-mini for simple, GPT-4o for complex |
| **Semantic cache** | 30-50% | Cache similar queries (cosine >0.95) |
| **Prompt compression** | 20-40% | Shorter prompts, structured output |
| **Batch API** | 50% | OpenAI Batch API for non-real-time |
| **Quantization** | GPU cost | FP16→INT8: 2x less memory |

### Semantic Cache
```python
class SemanticCache:
    def __init__(self, vectorstore, threshold=0.95):
        self.vs = vectorstore
        self.threshold = threshold
        self.cache = {}

    def get(self, query: str) -> str | None:
        results = self.vs.similarity_search_with_score(query, k=1)
        if results and results[0][1] >= self.threshold:
            return self.cache.get(results[0][0].metadata["key"])
        return None
```

## 7. CI/CD for ML

```yaml
name: ML Pipeline
on:
  push:
    paths: ['models/**', 'eval/**']
jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: python eval/run_eval.py --model ${{ vars.MODEL }}
      - run: python eval/check_gate.py --min-accuracy 0.85
      - if: success()
        run: kubectl set image deployment/llm llm=${{ vars.IMAGE }}
```

## 8. Best Practices

- **A/B testing**: Test new models against production baseline
- **Canary releases**: 5% traffic first, monitor, then expand
- **Structured logging**: Log every request with trace ID
- **Fallback models**: Route to backup if primary fails
- **Token budgets**: Set max_tokens per request and per user
- **Eval-driven**: Write evals before changing prompts
- **Version everything**: Model, prompt, eval versions tracked
- **Cost dashboards**: Real-time spend visibility per endpoint
