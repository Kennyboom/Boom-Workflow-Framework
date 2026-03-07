---
name: ollama-integration-expert
description: Ollama API integration patterns — model management, multimodal inference (Gemma 3n), streaming responses, tiered AI brain (PicoLM→Ollama→Cloud), process lifecycle, health monitoring, and fallback strategies. For Tauri v2 desktop apps with local AI.
---

# Ollama Integration Expert Skill

## Overview
Patterns for integrating with OpenFang's AI engine, which manages Ollama (and all other providers) internally. Boom Open communicates with OpenFang via gRPC — it does NOT spawn or manage Ollama processes directly.

## Tiered Brain Architecture (Inside OpenFang)

```
┌─── Tier 0: PicoLM (Provider #28, Always-On) ──────┐
│  Model: TinyLlama 1.1B (~45MB)                      │
│  Latency: <50ms | RAM: Negligible                    │
│  Use: Intent detection, routing, simple classification│
│  Status: ALWAYS RUNNING by default                    │
└──────────────────────────┬──────────────────────────┘
                           │ If task too complex
┌──────────────────────────▼──────────────────────────┐
│  Tier 1: Ollama (Built-in Provider)                  │
│  RAM: 2-16GB | Latency: 100-2000ms | Quality: High   │
│  Models: Gemma 3n, Qwen2.5, Phi-4                    │
│  Use: Reasoning, multimodal, complex tasks            │
└──────────────────────────┬──────────────────────────┘
                           │ If Ollama unavailable / BYOK
┌──────────────────────────▼──────────────────────────┐
│  Tier 2: Cloud API (27 Providers)                    │
│  Gemini, OpenAI, Anthropic, DeepSeek (BYOK)          │
│  Use: Fallback, heavy tasks, user preference          │
└─────────────────────────────────────────────────────┘
```

> ⚠️ **CRITICAL**: Boom Open does NOT run `ollama serve`. OpenFang manages all providers internally.

## Communication Pattern: Boom Open → OpenFang

### gRPC Bridge (Correct Way)
```rust
use tonic::transport::Channel;
use openfang_bridge::ai_engine_client::AiEngineClient;
use openfang_bridge::{InferRequest, InferResponse, TierPreference};

pub struct BoomAiClient {
    client: AiEngineClient<Channel>,
}

impl BoomAiClient {
    /// Connect to OpenFang engine via gRPC
    pub async fn connect() -> Result<Self, Box<dyn std::error::Error>> {
        let channel = Channel::from_static("http://127.0.0.1:50051")
            .connect()
            .await?;
        Ok(Self {
            client: AiEngineClient::new(channel),
        })
    }

    /// Send inference request — OpenFang handles routing internally
    pub async fn infer(&mut self, prompt: &str, tier: TierPreference) -> Result<String, Box<dyn std::error::Error>> {
        let request = tonic::Request::new(InferRequest {
            prompt: prompt.to_string(),
            tier_preference: tier as i32,
            stream: false,
            images: vec![],
        });
        let response = self.client.infer(request).await?;
        Ok(response.into_inner().text)
    }

    /// Vision inference (screenshot analysis)
    pub async fn analyze_screenshot(&mut self, image_b64: String) -> Result<String, Box<dyn std::error::Error>> {
        let request = tonic::Request::new(InferRequest {
            prompt: "Describe what you see on this screen. Identify clickable elements.".to_string(),
            tier_preference: TierPreference::Tier1Ollama as i32, // VLM needs Ollama
            stream: false,
            images: vec![image_b64],
        });
        let response = self.client.infer(request).await?;
        Ok(response.into_inner().text)
    }

    /// Health check — is OpenFang engine responsive?
    pub async fn health_check(&mut self) -> bool {
        self.client
            .health(tonic::Request::new(()))
            .await
            .is_ok()
    }
}
```

### Tier Preference Enum
```rust
/// Hint to OpenFang which tier to prefer (OpenFang may override based on availability)
pub enum TierPreference {
    Auto = 0,          // Let OpenFang decide (recommended)
    Tier0PicoLM = 1,   // Force PicoLM (TinyLlama 1.1B)
    Tier1Ollama = 2,   // Prefer Ollama (Gemma 3n, Phi-4)
    Tier2Cloud = 3,    // Prefer Cloud (Gemini, OpenAI)
}
```

### Streaming Inference
```rust
use futures_util::StreamExt;

impl BoomAiClient {
    /// Stream inference response from OpenFang
    pub async fn infer_stream(
        &mut self,
        prompt: &str,
        on_chunk: impl Fn(&str),
    ) -> Result<String, Box<dyn std::error::Error>> {
        let request = tonic::Request::new(InferRequest {
            prompt: prompt.to_string(),
            tier_preference: TierPreference::Auto as i32,
            stream: true,
            images: vec![],
        });

        let mut stream = self.client.infer_stream(request).await?.into_inner();
        let mut full_response = String::new();

        while let Some(chunk) = stream.next().await {
            let chunk = chunk?;
            on_chunk(&chunk.text);
            full_response.push_str(&chunk.text);
        }

        Ok(full_response)
    }
}
```

## What OpenFang Handles (Boom Open Does NOT)

| Responsibility | Who Handles |
|---------------|-------------|
| Start/stop Ollama process | ✅ OpenFang |
| Model pulling & management | ✅ OpenFang |
| Provider URL configuration | ✅ OpenFang (editable, hot-reload) |
| Routing logic (cost, complexity) | ✅ OpenFang |
| Fallback chain (Tier 0→1→2) | ✅ OpenFang |
| PicoLM lifecycle | ✅ OpenFang |
| GPU allocation | ✅ OpenFang |
| Health monitoring | ✅ OpenFang |
| Boom Open only does | → Send gRPC requests, receive responses |

## OpenFang REST API (Alternative to gRPC)

If needed, Boom Open can also use OpenFang's OpenAI-compatible REST API:

```bash
# Inference via OpenFang's REST endpoint
curl -X POST http://localhost:4200/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:4b",
    "messages": [{"role": "user", "content": "Analyze this task"}],
    "stream": true
  }'
```

## Recommended Models (Managed by OpenFang)

| Model | Provider | Size | Best For | Min RAM |
|-------|----------|:----:|---------|:-------:|
| TinyLlama 1.1B | PicoLM (Tier 0) | 45MB | Intent, routing | 1GB |
| `phi3:mini` | Ollama (Tier 1) | 2.3GB | Fast general tasks | 4GB |
| `gemma3:4b` | Ollama (Tier 1) | 3GB | Multimodal (text+image) | 6GB |
| `qwen2.5:7b` | Ollama (Tier 1) | 4.7GB | Reasoning, coding | 8GB |
| `gemma3:12b` | Ollama (Tier 1) | 8GB | Complex analysis | 16GB |

## Anti-Patterns (DO NOT DO)

```rust
// ❌ WRONG: Don't spawn Ollama directly
Command::new("ollama").arg("serve").spawn();

// ❌ WRONG: Don't call Ollama API directly
client.post("http://localhost:11434/api/generate");

// ❌ WRONG: Don't set OLLAMA_HOST env vars
std::env::set_var("OLLAMA_HOST", "127.0.0.1:11434");

// ✅ CORRECT: Go through OpenFang gRPC
let mut ai = BoomAiClient::connect().await?;
let result = ai.infer("your prompt", TierPreference::Auto).await?;
```
