---
name: webassembly-expert
description: Build high-performance web applications with WebAssembly. Covers Wasm fundamentals, WASI, Component Model, Rust/Go/C++ compilation to Wasm, JavaScript interop, edge deployment, and use cases like image processing and cryptography.
---

# WebAssembly Expert

Expert guidance for building and deploying WebAssembly modules for web and server-side applications.

## When to Use

- Performance-critical web computation (image/video/audio processing)
- Porting native libraries to the browser
- Edge computing (Cloudflare Workers, Fastly, Vercel Edge)
- Sandboxed plugin systems
- Cross-language interop in web apps

---

## 1. Wasm Fundamentals

### What Wasm IS and IS NOT
```
IS:
✅ Binary instruction format for a stack-based VM
✅ Near-native performance (within 10-20% of native)
✅ Language-agnostic compilation target
✅ Sandboxed execution (memory-safe by default)
✅ Portable across browsers, servers, and edge

IS NOT:
❌ A replacement for JavaScript (complement, not replace)
❌ Directly accessing the DOM (needs JS bridge)
❌ Always faster than JS (JIT-optimized JS can be close)
❌ Only for the browser (WASI enables server-side)
```

### When Wasm Beats JavaScript
| Use Case | Speedup | Why |
|----------|---------|-----|
| Image processing | 5-20x | SIMD, tight loops, no GC pauses |
| Cryptography | 10-50x | Constant-time ops, bit manipulation |
| Video codecs | 10-30x | Heavy computation, predictable memory |
| Physics/simulation | 5-15x | Float math, large data structures |
| Compression | 5-20x | Byte-level operations |
| PDF rendering | 5-10x | Complex layout algorithms |
| Game engines | 5-15x | Real-time constraints |

## 2. Rust → Wasm (Recommended Path)

### Setup
```bash
# Install wasm-pack
cargo install wasm-pack

# Create project
cargo new --lib my-wasm-lib
```

### Cargo.toml
```toml
[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
wasm-bindgen = "0.2"
serde = { version = "1", features = ["derive"] }
serde-wasm-bindgen = "0.6"
web-sys = { version = "0.3", features = ["console", "Window", "Document"] }
js-sys = "0.3"

[profile.release]
opt-level = "z"        # Optimize for size
lto = true             # Link-time optimization
codegen-units = 1      # Better optimization
strip = true           # Strip debug info
```

### Wasm Module
```rust
use wasm_bindgen::prelude::*;
use serde::{Serialize, Deserialize};

// Expose function to JavaScript
#[wasm_bindgen]
pub fn fibonacci(n: u32) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        _ => {
            let (mut a, mut b) = (0u64, 1u64);
            for _ in 2..=n {
                let temp = a + b;
                a = b;
                b = temp;
            }
            b
        }
    }
}

// Complex types via serde
#[derive(Serialize, Deserialize)]
pub struct ImageResult {
    pub data: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

#[wasm_bindgen]
pub fn resize_image(data: &[u8], new_width: u32, new_height: u32) -> JsValue {
    let result = ImageResult {
        data: perform_resize(data, new_width, new_height),
        width: new_width,
        height: new_height,
    };
    serde_wasm_bindgen::to_value(&result).unwrap()
}

// Access browser APIs
#[wasm_bindgen]
pub fn log_to_console(msg: &str) {
    web_sys::console::log_1(&msg.into());
}
```

### Build & Use
```bash
# Build for web
wasm-pack build --target web --release

# Output in pkg/
# ├── my_wasm_lib_bg.wasm    (binary)
# ├── my_wasm_lib.js         (JS bindings)
# └── my_wasm_lib.d.ts       (TypeScript types)
```

### JavaScript Usage
```javascript
import init, { fibonacci, resize_image } from './pkg/my_wasm_lib.js';

async function main() {
  await init();  // Initialize Wasm module

  // Call Wasm function
  const result = fibonacci(40);  // Nearly instant
  console.log(`Fibonacci(40) = ${result}`);

  // Heavy computation offloaded to Wasm
  const imageData = ctx.getImageData(0, 0, width, height);
  const resized = resize_image(imageData.data, 800, 600);
}
```

## 3. Go → Wasm

```go
//go:build js && wasm

package main

import (
    "encoding/json"
    "syscall/js"
)

func processData(this js.Value, args []js.Value) interface{} {
    input := args[0].String()
    // Process...
    return js.ValueOf(result)
}

func main() {
    js.Global().Set("processData", js.FuncOf(processData))
    // Keep Go runtime alive
    select {}
}
```

```bash
GOOS=js GOARCH=wasm go build -o main.wasm
```

## 4. WASI (WebAssembly System Interface)

### Purpose
```
WASI provides system-level capabilities to Wasm modules:
- File system access (sandboxed)
- Network sockets
- Environment variables
- Clock/time
- Random number generation

Use cases:
- Server-side Wasm (Wasmtime, Wasmer)
- Edge computing (Cloudflare Workers)
- Plugin systems (sandboxed execution)
- Portable CLI tools
```

### Rust WASI Example
```rust
// Runs outside the browser with WASI runtime
use std::fs;

fn main() {
    let contents = fs::read_to_string("/data/input.txt")
        .expect("Failed to read file");
    let result = process(&contents);
    fs::write("/data/output.txt", result)
        .expect("Failed to write file");
}
```

```bash
# Build for WASI
cargo build --target wasm32-wasi --release

# Run with Wasmtime
wasmtime --dir=/data target/wasm32-wasi/release/my_app.wasm
```

## 5. Component Model

```
The Component Model (2024+) enables:
- Module composition (link Wasm modules together)
- Rich type system (records, variants, resources)
- Language-agnostic interfaces (WIT - Wasm Interface Type)

WIT example:
  package myapp:image-processor@1.0.0;

  interface process {
    record image { data: list<u8>, width: u32, height: u32 }
    enum filter { blur, sharpen, grayscale }
    process: func(img: image, filter: filter) -> image;
  }

  world image-app {
    export process;
  }
```

## 6. Edge Deployment

### Cloudflare Workers
```rust
use worker::*;

#[event(fetch)]
pub async fn main(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    Router::new()
        .get("/api/process", |req, ctx| {
            let data = req.bytes().await?;
            let result = heavy_computation(&data);
            Response::from_bytes(result)
        })
        .run(req, env)
        .await
}
```

### Vercel Edge (with Wasm)
```typescript
import { processImage } from './wasm/image_processor.js';

export const config = { runtime: 'edge' };

export default async function handler(req: Request) {
  const imageData = await req.arrayBuffer();
  const result = processImage(new Uint8Array(imageData));
  return new Response(result, {
    headers: { 'Content-Type': 'image/webp' },
  });
}
```

## 7. Performance Optimization

### SIMD (Single Instruction, Multiple Data)
```rust
// Enable SIMD for parallel data processing
// Cargo.toml: [build] rustflags = ["-C", "target-feature=+simd128"]

use std::arch::wasm32::*;

pub fn add_arrays_simd(a: &[f32], b: &[f32], out: &mut [f32]) {
    for i in (0..a.len()).step_by(4) {
        unsafe {
            let va = v128_load(a[i..].as_ptr() as *const v128);
            let vb = v128_load(b[i..].as_ptr() as *const v128);
            let sum = f32x4_add(va, vb);
            v128_store(out[i..].as_mut_ptr() as *mut v128, sum);
        }
    }
}
```

### Memory Management
```
Tips for smaller Wasm binaries:
1. Use wee_alloc (smaller allocator): saves ~10KB
2. opt-level = "z" (optimize for size)
3. Enable LTO (link-time optimization)
4. wasm-opt -Os (Binaryen optimizer)
5. Avoid String where &str suffices
6. Use #[wasm_bindgen(skip)] for internal fields

Typical sizes:
- Hello world: ~20KB
- Image processor: ~100-300KB
- Full application: ~500KB-2MB
```

## 8. Best Practices

- **Right tool for the job**: Use Wasm for compute, JS for DOM/UI
- **Minimize JS↔Wasm boundary calls**: Batch operations, pass buffers
- **Use SharedArrayBuffer**: For zero-copy data sharing with threads
- **Lazy-load Wasm**: Don't block page load, load async
- **Web Workers**: Run Wasm in workers for non-blocking computation
- **Streaming compilation**: Use `WebAssembly.instantiateStreaming()` (faster)
- **Profile first**: Measure JS performance before reaching for Wasm
- **Feature detection**: Check `WebAssembly` support before loading
