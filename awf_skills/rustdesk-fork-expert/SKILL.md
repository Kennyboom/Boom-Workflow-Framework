---
name: rustdesk-fork-expert
description: Expert patterns for forking and customizing RustDesk v1.4.6 — architecture overview, AI control layer injection, gRPC bridge integration, custom protocol handlers, and cross-platform build system. For Boom Open remote desktop module.
---

# RustDesk Fork Expert Skill

## Overview
This skill provides expert guidance for forking, modifying, and extending RustDesk v1.4.6 as the remote desktop foundation for Boom Open. Focus areas: AI-driven desktop control, gRPC bridge for Flowise integration, and security hardening.

## RustDesk Architecture (v1.4.6)

```
rustdesk/
├── src/
│   ├── main.rs              # Entry point
│   ├── client.rs            # Client-side logic
│   ├── server.rs            # Server/relay logic
│   ├── ui.rs                # UI (sciter or Flutter)
│   ├── platform/            # OS-specific code
│   │   ├── windows.rs
│   │   ├── macos.rs
│   │   └── linux.rs
│   ├── rendezvous_mediator.rs
│   └── ipc.rs               # Inter-process communication
├── libs/
│   ├── hbb_common/          # Shared types, config, protobuf
│   ├── scrap/               # Screen capture
│   ├── enigo/               # Mouse/keyboard input
│   └── virtual_display/     # Virtual display driver
├── flutter/                  # Flutter desktop UI (newer versions)
└── Cargo.toml
```

### Key Crates
| Crate | Purpose |
|-------|---------|
| `hbb_common` | Shared protobuf messages, config, logging |
| `scrap` | Cross-platform screen capture |
| `enigo` | Mouse/keyboard simulation |
| `magnum-opus` | Audio codec |
| `vpx-sys` | VP9 video codec |
| `tokio` | Async runtime |

## Fork Strategy

### Step 1: Clone & Rename
```bash
git clone https://github.com/rustdesk/rustdesk.git boom-remote
cd boom-remote
git checkout v1.4.6
git remote rename origin upstream
git remote add origin <your-repo>
```

### Step 2: Rebrand
- Replace "RustDesk" with "Boom Remote" in all UI strings
- Update `Cargo.toml` package names: `rustdesk` → `boom-remote`
- Update icons, splash screens, about dialog

### Step 3: Add AI Control Layer
```rust
// src/ai_control.rs — New module
use enigo::{Enigo, MouseControllable, KeyboardControllable};
use scrap::{Capturer, Display};

pub struct AiDesktopController {
    enigo: Enigo,
    capturer: Option<Capturer>,
}

impl AiDesktopController {
    pub fn new() -> Self {
        Self {
            enigo: Enigo::new(),
            capturer: None,
        }
    }

    /// Take screenshot and return raw pixels
    pub fn capture_screen(&mut self) -> Result<Vec<u8>, String> {
        let display = Display::primary().map_err(|e| e.to_string())?;
        let mut capturer = Capturer::new(display).map_err(|e| e.to_string())?;
        // ... capture logic
        Ok(vec![])
    }

    /// Click at coordinates
    pub fn click(&mut self, x: i32, y: i32) {
        self.enigo.mouse_move_to(x, y);
        self.enigo.mouse_click(enigo::MouseButton::Left);
    }

    /// Type text
    pub fn type_text(&mut self, text: &str) {
        self.enigo.key_sequence(text);
    }

    /// Press key combination
    pub fn hotkey(&mut self, keys: &[enigo::Key]) {
        for key in keys {
            self.enigo.key_down(*key);
        }
        for key in keys.iter().rev() {
            self.enigo.key_up(*key);
        }
    }
}
```

### Step 4: gRPC Bridge Integration
```rust
// src/grpc_bridge.rs
use tonic::{transport::Server, Request, Response, Status};

pub mod boom_proto {
    tonic::include_proto!("boom.remote");
}

#[tonic::async_trait]
impl boom_proto::desktop_control_server::DesktopControl for AiDesktopController {
    async fn click(&self, req: Request<ClickRequest>) -> Result<Response<ActionResult>, Status> {
        let r = req.into_inner();
        self.click(r.x, r.y);
        Ok(Response::new(ActionResult { success: true, ..Default::default() }))
    }

    async fn capture_screen(&self, _req: Request<CaptureRequest>) -> Result<Response<ScreenFrame>, Status> {
        let pixels = self.capture_screen().map_err(|e| Status::internal(e))?;
        Ok(Response::new(ScreenFrame { data: pixels, ..Default::default() }))
    }
}
```

## Build Instructions

### Windows
```powershell
# Prerequisites
# 1. Visual Studio Build Tools 2022
# 2. vcpkg (for C dependencies)
vcpkg install libvpx:x64-windows opus:x64-windows aom:x64-windows

# Build
cargo build --release
```

### macOS
```bash
brew install opus libvpx
cargo build --release
```

### Linux
```bash
sudo apt install -y libxcb-randr0-dev libxcb-xfixes0-dev libpam0g-dev \
  libxdo-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libopus-dev libvpx-dev
cargo build --release
```

## Key Modifications for Boom Open

1. **Remove relay server dependency** — Boom Open runs local-only (same machine)
2. **Add AI control IPC** — Unix socket or named pipe for Flowise ↔ Desktop
3. **Screen analysis pipeline** — Capture → AI vision → Action decision
4. **Permission system** — AI Employee can only access approved windows/apps
5. **Activity logging** — Every action logged for audit trail
6. **Multi-monitor support** — AI Employee can work across displays

## Security Considerations
- AI Employee MUST NOT have unrestricted desktop access
- Implement window allowlist/blocklist
- Rate-limit mouse/keyboard actions (prevent abuse)
- Screenshot data NEVER leaves the machine
- Encrypt IPC channel between AI and desktop controller
