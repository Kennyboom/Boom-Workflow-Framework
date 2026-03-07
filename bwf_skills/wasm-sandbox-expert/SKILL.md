---
name: wasm-sandbox-expert
description: WASM sandbox patterns for AI Employee isolation — Wasmtime runtime, permission system, resource limits, capability-based security, and inter-sandbox IPC. For Boom Open AI Employee security.
---

# WASM Sandbox Expert Skill

## Overview
Patterns for running AI Employee code in isolated WASM sandboxes with fine-grained permissions.

## Architecture

```
┌── Boom Open Host Process ──────────────────────────────┐
│                                                         │
│  ┌── WASM Sandbox (AI Employee A) ────────────────┐   │
│  │  Permissions: [browser, file.read]              │   │
│  │  Memory limit: 256MB                            │   │
│  │  CPU limit: 50%                                 │   │
│  │  Network: blocked                               │   │
│  │  ┌─ SKILL.md logic ─┐  ┌─ HAND.toml config ─┐│   │
│  │  └──────────────────┘  └────────────────────┘│   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌── WASM Sandbox (AI Employee B) ────────────────┐   │
│  │  Permissions: [network.http, clipboard.write]   │   │
│  │  Memory limit: 512MB                            │   │
│  │  ┌─ Different skills ─┐                        │   │
│  │  └────────────────────┘                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Host capabilities exposed via WASI + custom imports   │
└─────────────────────────────────────────────────────────┘
```

## Wasmtime Integration (Rust)

```rust
use wasmtime::*;
use std::collections::HashSet;

pub struct AiEmployeeSandbox {
    engine: Engine,
    store: Store<SandboxState>,
    instance: Option<Instance>,
}

pub struct SandboxState {
    permissions: HashSet<String>,
    memory_limit_mb: u32,
    action_log: Vec<SandboxAction>,
}

#[derive(Clone, Debug)]
pub struct SandboxAction {
    pub timestamp: u64,
    pub action_type: String,
    pub details: String,
    pub allowed: bool,
}

impl AiEmployeeSandbox {
    pub fn new(permissions: Vec<String>, memory_limit_mb: u32) -> Result<Self, anyhow::Error> {
        let mut config = Config::new();
        config.consume_fuel(true);         // CPU limiting
        config.memory_reservation(memory_limit_mb as u64 * 1024 * 1024);

        let engine = Engine::new(&config)?;
        let state = SandboxState {
            permissions: permissions.into_iter().collect(),
            memory_limit_mb,
            action_log: vec![],
        };
        let store = Store::new(&engine, state);
        Ok(Self { engine, store, instance: None })
    }

    /// Check if action is allowed
    pub fn check_permission(&self, permission: &str) -> bool {
        self.store.data().permissions.contains(permission)
    }

    /// Add fuel (CPU budget) for execution
    pub fn add_fuel(&mut self, fuel: u64) {
        self.store.set_fuel(fuel).ok();
    }
}
```

## Permission System

```rust
/// Standard permissions for AI Employees
pub enum Permission {
    // Desktop
    DesktopView,        // Can see screen (screenshot)
    DesktopClick,       // Can click mouse
    DesktopType,        // Can type keyboard
    DesktopOpenApp,     // Can open applications

    // File System
    FileRead,           // Read files (scoped to allowed paths)
    FileWrite,          // Write files (scoped)
    FileDelete,         // Delete files (scoped)

    // Network
    NetworkHttp,        // HTTP requests (scoped to allowed domains)
    NetworkWebSocket,   // WebSocket connections

    // System
    ClipboardRead,      // Read clipboard
    ClipboardWrite,     // Write clipboard
    NotificationSend,   // Send OS notifications
    ProcessSpawn,       // Spawn child processes (dangerous!)
}

/// Parse permissions from HAND.toml
pub fn parse_permissions(hand_toml: &str) -> Vec<Permission> {
    let config: toml::Value = toml::from_str(hand_toml).unwrap();
    let required = config["permissions"]["required"].as_array().unwrap();
    required.iter().filter_map(|p| {
        match p.as_str()? {
            "browser.navigate" => Some(Permission::NetworkHttp),
            "browser.input" => Some(Permission::DesktopClick),
            "file.read" => Some(Permission::FileRead),
            "network.http" => Some(Permission::NetworkHttp),
            "clipboard.write" => Some(Permission::ClipboardWrite),
            "notification.send" => Some(Permission::NotificationSend),
            _ => None,
        }
    }).collect()
}
```

## Resource Limits

```rust
pub struct ResourceLimits {
    pub max_memory_mb: u32,        // Default: 256MB
    pub max_cpu_percent: u8,       // Default: 50%
    pub max_actions_per_minute: u32, // Default: 60
    pub max_file_size_mb: u32,     // Default: 10MB
    pub allowed_domains: Vec<String>, // Network whitelist
    pub allowed_paths: Vec<String>,   // File system whitelist
}

impl Default for ResourceLimits {
    fn default() -> Self {
        Self {
            max_memory_mb: 256,
            max_cpu_percent: 50,
            max_actions_per_minute: 60,
            max_file_size_mb: 10,
            allowed_domains: vec![],
            allowed_paths: vec![],
        }
    }
}
```

## Security Best Practices

1. **NEVER** allow unrestricted file system or network access
2. **ALWAYS** log every action for audit trail
3. **RATE-LIMIT** all actions (prevent abuse)
4. **SIGN** WASM modules — only run signed, reviewed code
5. **ISOLATE** each AI Employee in its own sandbox instance
6. **TIMEOUT** — kill sandbox if execution exceeds time limit
7. **MEMORY CAP** — OOM kills sandbox, not host process
