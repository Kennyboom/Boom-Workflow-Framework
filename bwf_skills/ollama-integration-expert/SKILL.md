---
name: ollama-integration-expert
description: Ollama API integration patterns — model management, multimodal inference (Gemma 3n), streaming responses, tiered AI brain (PicoLM→Ollama→Cloud), process lifecycle, health monitoring, and fallback strategies. For Tauri v2 desktop apps with local AI.
---

# Ollama Integration Expert Skill

## Overview
Patterns for integrating Ollama as the local AI inference engine in Boom Open's tiered brain system.

## Tiered Brain Architecture

```
┌─── Tier 1: PicoLM (Embedded) ──────────────────┐
│  RAM: ~45MB | Latency: <50ms | Quality: Basic    │
│  Use: Simple classification, intent detection     │
│  Fallback: Always available, no external deps     │
└──────────────────────────┬──────────────────────┘
                           │ If task too complex
┌──────────────────────────▼──────────────────────┐
│  Tier 2: Ollama (Local Server)                   │
│  RAM: 2-16GB | Latency: 100-2000ms | Quality: High│
│  Models: Gemma 3n, Qwen2.5, Phi-3               │
│  Use: Reasoning, multimodal, complex tasks        │
└──────────────────────────┬──────────────────────┘
                           │ If Ollama unavailable / BYOK
┌──────────────────────────▼──────────────────────┐
│  Tier 3: Cloud API (Optional)                    │
│  Providers: Gemini, OpenAI, Anthropic (BYOK)     │
│  Use: Fallback, heavy tasks, user preference      │
└─────────────────────────────────────────────────┘
```

## Ollama API Reference

### Base URL
```
http://localhost:11434
```

### Generate (Streaming)
```rust
use reqwest::Client;
use serde::{Deserialize, Serialize};
use futures_util::StreamExt;

#[derive(Serialize)]
struct GenerateRequest {
    model: String,
    prompt: String,
    stream: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    images: Option<Vec<String>>,  // base64 for multimodal
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    options: Option<ModelOptions>,
}

#[derive(Serialize)]
struct ModelOptions {
    temperature: f32,
    num_predict: i32,
    top_p: f32,
    top_k: i32,
}

#[derive(Deserialize)]
struct GenerateResponse {
    model: String,
    response: String,
    done: bool,
    #[serde(default)]
    total_duration: u64,
    #[serde(default)]
    eval_count: u32,
}

async fn generate_streaming(client: &Client, prompt: &str) -> Result<String, Box<dyn std::error::Error>> {
    let req = GenerateRequest {
        model: "gemma3:4b".into(),
        prompt: prompt.into(),
        stream: true,
        images: None,
        system: Some("You are an AI Employee...".into()),
        options: Some(ModelOptions {
            temperature: 0.7,
            num_predict: 512,
            top_p: 0.9,
            top_k: 40,
        }),
    };

    let mut stream = client.post("http://localhost:11434/api/generate")
        .json(&req)
        .send()
        .await?
        .bytes_stream();

    let mut full_response = String::new();
    while let Some(chunk) = stream.next().await {
        let bytes = chunk?;
        let resp: GenerateResponse = serde_json::from_slice(&bytes)?;
        full_response.push_str(&resp.response);
        if resp.done { break; }
    }
    Ok(full_response)
}
```

### Chat API
```rust
#[derive(Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<ChatMessage>,
    stream: bool,
}

#[derive(Serialize, Deserialize, Clone)]
struct ChatMessage {
    role: String,      // "system", "user", "assistant"
    content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    images: Option<Vec<String>>,
}

async fn chat(client: &Client, messages: Vec<ChatMessage>) -> Result<String, Box<dyn std::error::Error>> {
    let req = ChatRequest {
        model: "gemma3:4b".into(),
        messages,
        stream: false,
    };
    let resp = client.post("http://localhost:11434/api/chat")
        .json(&req)
        .send().await?
        .json::<serde_json::Value>().await?;
    Ok(resp["message"]["content"].as_str().unwrap_or("").to_string())
}
```

### Multimodal (Vision)
```rust
use base64::Engine;

async fn analyze_screenshot(client: &Client, screenshot_bytes: &[u8]) -> Result<String, Box<dyn std::error::Error>> {
    let b64 = base64::engine::general_purpose::STANDARD.encode(screenshot_bytes);
    let req = GenerateRequest {
        model: "gemma3:4b".into(),
        prompt: "Describe what you see on this screen. Identify clickable elements.".into(),
        stream: false,
        images: Some(vec![b64]),
        system: None,
        options: None,
    };
    let resp = client.post("http://localhost:11434/api/generate")
        .json(&req)
        .send().await?
        .json::<GenerateResponse>().await?;
    Ok(resp.response)
}
```

### Model Management
```rust
/// List available models
async fn list_models(client: &Client) -> Vec<String> {
    let resp = client.get("http://localhost:11434/api/tags")
        .send().await.unwrap()
        .json::<serde_json::Value>().await.unwrap();
    resp["models"].as_array().unwrap_or(&vec![])
        .iter()
        .map(|m| m["name"].as_str().unwrap_or("").to_string())
        .collect()
}

/// Pull model with progress
async fn pull_model(client: &Client, model: &str) -> Result<(), Box<dyn std::error::Error>> {
    let mut stream = client.post("http://localhost:11434/api/pull")
        .json(&serde_json::json!({"name": model, "stream": true}))
        .send().await?
        .bytes_stream();
    while let Some(chunk) = stream.next().await {
        let bytes = chunk?;
        let progress: serde_json::Value = serde_json::from_slice(&bytes)?;
        // Emit progress to frontend via Tauri event
        if let Some(status) = progress["status"].as_str() {
            println!("Pull {}: {}", model, status);
        }
    }
    Ok(())
}

/// Check if Ollama is running
async fn health_check(client: &Client) -> bool {
    client.get("http://localhost:11434/").send().await.map(|r| r.status().is_success()).unwrap_or(false)
}
```

## Ollama Process Management (Tauri)

```rust
use std::process::{Command, Child};
use tauri::AppHandle;

pub struct OllamaManager {
    process: Option<Child>,
    port: u16,
}

impl OllamaManager {
    pub fn new() -> Self {
        Self { process: None, port: 11434 }
    }

    /// Start Ollama server if not running
    pub async fn ensure_running(&mut self) -> Result<(), String> {
        if self.is_running().await { return Ok(()); }

        #[cfg(target_os = "windows")]
        let cmd = Command::new("ollama").arg("serve").spawn();

        #[cfg(not(target_os = "windows"))]
        let cmd = Command::new("ollama").arg("serve").spawn();

        match cmd {
            Ok(child) => { self.process = Some(child); Ok(()) }
            Err(e) => Err(format!("Failed to start Ollama: {}", e))
        }
    }

    pub async fn is_running(&self) -> bool {
        reqwest::get(format!("http://localhost:{}", self.port))
            .await.map(|r| r.status().is_success()).unwrap_or(false)
    }

    /// Graceful shutdown
    pub fn stop(&mut self) {
        if let Some(ref mut child) = self.process {
            let _ = child.kill();
            self.process = None;
        }
    }
}
```

## Tiered Brain Router

```rust
pub enum AiBrain {
    PicoLM,
    Ollama(String),  // model name
    Cloud(CloudProvider),
}

pub enum CloudProvider {
    Gemini { api_key: String },
    OpenAI { api_key: String },
}

pub struct BrainRouter {
    ollama_client: reqwest::Client,
    cloud_keys: Option<CloudProvider>,
}

impl BrainRouter {
    /// Automatically select the best brain for the task
    pub async fn route(&self, task: &AiTask) -> AiBrain {
        match task.complexity {
            Complexity::Simple => AiBrain::PicoLM,
            Complexity::Medium => {
                if self.ollama_available().await {
                    AiBrain::Ollama("phi3:mini".into())
                } else {
                    AiBrain::PicoLM
                }
            }
            Complexity::Complex | Complexity::Multimodal => {
                if self.ollama_available().await {
                    AiBrain::Ollama("gemma3:4b".into())
                } else if let Some(ref cloud) = self.cloud_keys {
                    AiBrain::Cloud(cloud.clone())
                } else {
                    AiBrain::Ollama("phi3:mini".into()) // best effort
                }
            }
        }
    }
}
```

## Recommended Models

| Model | Size | Best For | Min RAM |
|-------|:----:|---------|:-------:|
| `phi3:mini` | 2.3GB | Fast general tasks | 4GB |
| `gemma3:4b` | 3GB | Multimodal (text+image) | 6GB |
| `qwen2.5:7b` | 4.7GB | Reasoning, coding | 8GB |
| `gemma3:12b` | 8GB | Complex analysis | 16GB |
