---
name: on-device-ai
description: Local AI inference patterns — ONNX Runtime, WebNN API, Gemma 3n, quantized models, on-device TTS, and privacy-first AI processing. For desktop apps that run AI without cloud dependency.
---

# On-Device AI — Local Inference Engine

Use this skill for running AI models locally on user devices without cloud APIs.

---

## 1. ONNX Runtime (Rust)

### Setup
```rust
use ort::{Session, Environment, Value, GraphOptimizationLevel};
use ndarray::{Array2, Array3};

pub struct LocalModel {
    session: Session,
}

impl LocalModel {
    pub fn load(model_path: &str) -> Result<Self, AppError> {
        let environment = Environment::builder()
            .with_name("metagen")
            .with_execution_providers([
                // Try GPU first, fallback to CPU
                ort::CUDAExecutionProvider::default().build(),
                ort::DirectMLExecutionProvider::default().build(),
                ort::CPUExecutionProvider::default().build(),
            ])
            .build()?;

        let session = Session::builder()?
            .with_optimization_level(GraphOptimizationLevel::Level3)?
            .with_intra_threads(4)?
            .commit_from_file(model_path)?;

        Ok(Self { session })
    }

    pub fn infer(&self, input: Array2<f32>) -> Result<Array2<f32>, AppError> {
        let input_value = Value::from_array(input)?;
        let outputs = self.session.run(ort::inputs![input_value]?)?;
        let output = outputs[0].extract_tensor::<f32>()?;
        Ok(output.to_owned())
    }
}
```

---

## 2. Quantized Model Loading

```rust
// 4-bit GGUF model loading for text generation
pub async fn load_quantized_model(model_path: &str) -> Result<LlmSession, AppError> {
    let params = LlmParams {
        model_path: model_path.to_string(),
        context_size: 4096,
        n_gpu_layers: 35,  // Offload to GPU
        n_threads: 4,
    };

    // Estimate memory requirement
    let model_size = std::fs::metadata(model_path)?.len();
    let available_ram = sysinfo::System::new().available_memory();
    if model_size > available_ram / 2 {
        return Err(AppError::new("E4010", "Insufficient RAM for model"));
    }

    LlmSession::new(params)
}
```

---

## 3. WebNN API (Frontend)

```typescript
// Check WebNN support
async function checkWebNN(): Promise<boolean> {
  return 'ml' in navigator;
}

// Create ML context
async function createMLContext(): Promise<MLContext> {
  const ml = navigator.ml;
  // Prefer NPU > GPU > CPU
  try {
    return await ml.createContext({ deviceType: 'npu' });
  } catch {
    try {
      return await ml.createContext({ deviceType: 'gpu' });
    } catch {
      return await ml.createContext({ deviceType: 'cpu' });
    }
  }
}
```

---

## 4. On-device TTS (Rust)

```rust
use tts::Tts;

pub struct LocalTts {
    engine: Tts,
}

impl LocalTts {
    pub fn new() -> Result<Self, AppError> {
        let mut engine = Tts::default()?;
        engine.set_rate(engine.normal_rate())?;
        Ok(Self { engine })
    }

    pub async fn synthesize_to_file(
        &mut self,
        text: &str,
        output_path: &str,
    ) -> Result<(), AppError> {
        // Use system TTS engine (SAPI on Windows, AVSpeechSynthesizer on macOS)
        self.engine.speak(text, false)?;
        // For file output, use external TTS like Piper
        let output = Command::new("piper")
            .args([
                "--model", "en_US-lessac-medium.onnx",
                "--output_file", output_path,
            ])
            .stdin(std::process::Stdio::piped())
            .spawn()?;
        // Pipe text to stdin
        output.stdin.unwrap().write_all(text.as_bytes())?;
        Ok(())
    }
}
```

---

## 5. Best Practices

1. **ONNX Runtime for cross-platform** — GPU auto-detection with fallback
2. **4-bit quantization** — good quality with 8GB RAM requirement
3. **Check RAM before loading** — prevent OOM crashes
4. **WebNN for browser inference** — NPU > GPU > CPU priority
5. **Piper for offline TTS** — fast, high quality ONNX-based
6. **Cache model in app data** — download once, use forever
