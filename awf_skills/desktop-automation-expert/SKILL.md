---
name: desktop-automation-expert
description: Desktop automation patterns in Rust — enigo mouse/keyboard control, screenshots crate for screen capture, window management, OCR integration, element detection, and multi-monitor support. For AI Employee desktop actions.
---

# Desktop Automation Expert Skill

## Overview
Patterns for AI Employee desktop control: mouse, keyboard, screen capture, window management, and visual element detection.

## Core Crates

| Crate | Version | Purpose |
|-------|---------|---------|
| `enigo` | 0.3+ | Mouse & keyboard simulation |
| `screenshots` | 0.8+ | Screen capture |
| `xcap` | latest | Cross-platform capture (alternative) |
| `windows` | latest | Windows API bindings |
| `accessibility` | latest | macOS accessibility API |

## Mouse Control

```rust
use enigo::{Enigo, MouseControllable, MouseButton};

pub struct MouseController {
    enigo: Enigo,
}

impl MouseController {
    pub fn new() -> Self { Self { enigo: Enigo::new() } }

    pub fn move_to(&mut self, x: i32, y: i32) {
        self.enigo.mouse_move_to(x, y);
    }

    pub fn click(&mut self, x: i32, y: i32) {
        self.enigo.mouse_move_to(x, y);
        std::thread::sleep(std::time::Duration::from_millis(50));
        self.enigo.mouse_click(MouseButton::Left);
    }

    pub fn double_click(&mut self, x: i32, y: i32) {
        self.enigo.mouse_move_to(x, y);
        self.enigo.mouse_click(MouseButton::Left);
        self.enigo.mouse_click(MouseButton::Left);
    }

    pub fn right_click(&mut self, x: i32, y: i32) {
        self.enigo.mouse_move_to(x, y);
        self.enigo.mouse_click(MouseButton::Right);
    }

    pub fn drag(&mut self, from: (i32, i32), to: (i32, i32)) {
        self.enigo.mouse_move_to(from.0, from.1);
        self.enigo.mouse_down(MouseButton::Left);
        std::thread::sleep(std::time::Duration::from_millis(100));
        self.enigo.mouse_move_to(to.0, to.1);
        self.enigo.mouse_up(MouseButton::Left);
    }

    pub fn scroll(&mut self, amount: i32) {
        self.enigo.mouse_scroll_y(amount);
    }
}
```

## Keyboard Control

```rust
use enigo::{Enigo, KeyboardControllable, Key};

pub struct KeyboardController {
    enigo: Enigo,
}

impl KeyboardController {
    pub fn new() -> Self { Self { enigo: Enigo::new() } }

    pub fn type_text(&mut self, text: &str) {
        self.enigo.key_sequence(text);
    }

    pub fn type_text_with_delay(&mut self, text: &str, delay_ms: u64) {
        for c in text.chars() {
            self.enigo.key_sequence(&c.to_string());
            std::thread::sleep(std::time::Duration::from_millis(delay_ms));
        }
    }

    pub fn hotkey(&mut self, modifier: Key, key: Key) {
        self.enigo.key_down(modifier);
        self.enigo.key_click(key);
        self.enigo.key_up(modifier);
    }

    pub fn ctrl_c(&mut self) { self.hotkey(Key::Control, Key::Layout('c')); }
    pub fn ctrl_v(&mut self) { self.hotkey(Key::Control, Key::Layout('v')); }
    pub fn ctrl_a(&mut self) { self.hotkey(Key::Control, Key::Layout('a')); }
    pub fn ctrl_s(&mut self) { self.hotkey(Key::Control, Key::Layout('s')); }
    pub fn enter(&mut self) { self.enigo.key_click(Key::Return); }
    pub fn tab(&mut self) { self.enigo.key_click(Key::Tab); }
    pub fn escape(&mut self) { self.enigo.key_click(Key::Escape); }

    pub fn alt_tab(&mut self) {
        self.enigo.key_down(Key::Alt);
        self.enigo.key_click(Key::Tab);
        self.enigo.key_up(Key::Alt);
    }
}
```

## Screen Capture

```rust
use screenshots::Screen;

pub fn capture_primary() -> Result<Vec<u8>, String> {
    let screens = Screen::all().map_err(|e| e.to_string())?;
    let primary = screens.first().ok_or("No screen found")?;
    let image = primary.capture().map_err(|e| e.to_string())?;
    Ok(image.to_png().map_err(|e| e.to_string())?)
}

pub fn capture_region(x: i32, y: i32, w: u32, h: u32) -> Result<Vec<u8>, String> {
    let screens = Screen::all().map_err(|e| e.to_string())?;
    let primary = screens.first().ok_or("No screen found")?;
    let image = primary.capture_area(x, y, w, h).map_err(|e| e.to_string())?;
    Ok(image.to_png().map_err(|e| e.to_string())?)
}

pub fn list_monitors() -> Vec<MonitorInfo> {
    Screen::all().unwrap_or_default().iter().enumerate().map(|(i, s)| {
        MonitorInfo {
            index: i as u32,
            x: s.display_info.x,
            y: s.display_info.y,
            width: s.display_info.width,
            height: s.display_info.height,
            is_primary: s.display_info.is_primary,
        }
    }).collect()
}

pub struct MonitorInfo {
    pub index: u32,
    pub x: i32, pub y: i32,
    pub width: u32, pub height: u32,
    pub is_primary: bool,
}
```

## AI Vision Pipeline

```
Screenshot → Encode PNG → Send to Ollama (Gemma 3n) → Parse response → Execute action
    ↑                                                        │
    └────────────────── Feedback loop ──────────────────────┘
```

```rust
pub async fn ai_vision_action_loop(
    mouse: &mut MouseController,
    keyboard: &mut KeyboardController,
    ai_client: &reqwest::Client,
    instruction: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    for attempt in 0..5 {
        // 1. Capture screen
        let screenshot = capture_primary()?;
        let b64 = base64::engine::general_purpose::STANDARD.encode(&screenshot);

        // 2. Send to AI for analysis
        let prompt = format!(
            "Instruction: {}\nAttempt: {}/5\nAnalyze the screenshot. Return JSON:\n{{\n  \"action\": \"click|type|hotkey|scroll|done\",\n  \"x\": 0, \"y\": 0,\n  \"text\": \"\",\n  \"keys\": []\n}}",
            instruction, attempt + 1
        );

        // 3. Parse AI response and execute
        // ... (call Ollama, parse JSON, execute action)

        // 4. Wait for UI to update
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
    }
    Ok(())
}
```

## Safety Rules
1. **Rate limit**: Max 60 actions/minute per AI Employee
2. **Confirmation**: Dangerous actions (delete, payment) require user approval
3. **Allowlist**: AI Employee can only interact with approved applications
4. **Kill switch**: Global hotkey (Ctrl+Shift+Esc) stops all AI Employees instantly
5. **Logging**: Every action is recorded with timestamp and screenshot
