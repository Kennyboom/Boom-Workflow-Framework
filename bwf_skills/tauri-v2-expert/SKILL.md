---
name: tauri-v2-expert
description: Expert in building desktop applications using Tauri v2. Covers Tauri 2 Sidecar setup, Rust-React IPC bindings, API commands, shared memory from Rust, build configuration, and window management. Use when starting or working on Tauri v2 projects.
---

# Tauri v2 Expert

## What is this skill
This skill provides expertise for building applications with Tauri v2, specifically focusing on complex integrations like Sidecar process management, Inter-Process Communication (IPC) via Shared Memory, and bridging Rust backend with React frontend.

## Tauri v2 Sidecar Management
Tauri v2 Native Sidecar:
1. Define perfectly in `tauri.conf.json`:
```json
{
  "bundle": {
    "externalBin": ["binaries/app-engine"]
  }
}
```
2. Spawn in Rust (`src-tauri/src/main.rs`):
```rust
use tauri::api::process::Command;
use tauri::api::process::CommandEvent;

let (mut rx, child) = Command::new_sidecar("app-engine")
    .expect("failed to create `app-engine` binary command")
    .spawn()
    .expect("Failed to spawn sidecar");

tauri::async_runtime::spawn(async move {
    // read events such as stdout
    while let Some(event) = rx.recv().await {
        if let CommandEvent::Stdout(line) = event {
            println!("got: {}", line);
        }
    }
});
```

## Rust and Shared Memory
When working with heavy IPC (like video frames or uncompressed audio), DO NOT use JSON over stdout or websockets. Use Shared Memory:
```rust
use shared_memory::ShmemConf;

// Ensure Python has already created the memory region
let shm = ShmemConf::new()
    .os_id("app_video_buffer") // Or whatever name Python used
    .open()
    .expect("Failed to open shared memory");

// Get a raw slice to the memory
let frame_data: &[u8] = unsafe { shm.as_slice() };
```

## IPC Binding (Rust <-> React)
1. Define command in Rust:
```rust
#[tauri::command]
fn get_status() -> String {
    "Running".into()
}
```
2. Register in main:
```rust
tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![get_status])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
```
3. Call from React via `@tauri-apps/api/core` (v2 API):
```typescript
import { invoke } from '@tauri-apps/api/core';

async function checkStatus() {
    const status = await invoke<string>('get_status');
    console.log(status);
}
```
