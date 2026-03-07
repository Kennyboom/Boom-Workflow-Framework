---
name: tauri-v2-expert
description: Expert patterns for Tauri v2 desktop apps — IPC commands, state management, multi-window, system tray, auto-updater, security isolation, deep linking, and custom protocols. Optimized for Next.js 16 frontend integration.
---

# Tauri v2 Expert — Desktop Application Patterns

Use this skill when building desktop applications with Tauri v2 + Rust backend + WebView frontend.

---

## 1. IPC Command Patterns

### Basic Command
```rust
use tauri::State;
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
pub struct VideoParams {
    pub title: String,
    pub model: String,
    pub resolution: String,
}

#[derive(Serialize, Deserialize)]
pub struct VideoResponse {
    pub id: String,
    pub status: String,
    pub output_path: Option<String>,
}

// Every command returns Result<T, AppError>
#[tauri::command]
async fn video_create(
    params: VideoParams,
    db: State<'_, DbPool>,
    ai: State<'_, AiService>,
) -> Result<VideoResponse, AppError> {
    let video = ai.generate(&params).await
        .map_err(|e| AppError::new("E4001", e))?;
    db.save_video(&video).await?;
    Ok(VideoResponse {
        id: video.id,
        status: "completed".into(),
        output_path: Some(video.path),
    })
}
```

### Registering Commands
```rust
fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_store::Builder::default().build())
        .plugin(tauri_plugin_updater::Builder::default().build())
        .plugin(tauri_plugin_shell::init())
        .manage(DbPool::new("data/metagen.db").unwrap())
        .manage(AiService::new())
        .manage(QueueManager::new())
        .invoke_handler(tauri::generate_handler![
            // Auth
            auth_login, auth_register, auth_verify_license,
            // AI Keys
            ai_key_add, ai_key_list, ai_key_rotate, ai_key_test,
            // Videos
            video_create, video_list, video_delete, video_export,
            // Queue
            queue_add, queue_status, queue_cancel, queue_retry,
        ])
        .setup(|app| {
            // Startup health checks
            let db = app.state::<DbPool>();
            db.run_integrity_check()?;
            db.reset_stuck_tasks()?;
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error running tauri application");
}
```

### Frontend IPC Bridge (TypeScript)
```typescript
import { invoke } from '@tauri-apps/api/core';

// Type-safe IPC wrapper
export async function ipcInvoke<T>(
  command: string,
  args?: Record<string, unknown>
): Promise<T> {
  try {
    return await invoke<T>(command, args);
  } catch (error: unknown) {
    const appError = error as AppError;
    useErrorStore.getState().addError(appError);
    throw appError;
  }
}

// Usage
const video = await ipcInvoke<VideoResponse>('video_create', {
  params: { title: 'My Video', model: 'veo', resolution: '1080p' }
});
```

---

## 2. State Management

### Shared Mutable State (Rust)
```rust
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct AppState {
    pub db: DbPool,
    pub queue: Arc<RwLock<QueueManager>>,
    pub settings: Arc<RwLock<AppSettings>>,
    pub ai_pool: AiKeyPool,
}

// Read state (concurrent)
#[tauri::command]
async fn get_settings(state: State<'_, AppState>) -> Result<AppSettings, AppError> {
    let settings = state.settings.read().await;
    Ok(settings.clone())
}

// Write state (exclusive)
#[tauri::command]
async fn update_settings(
    patch: SettingsPatch,
    state: State<'_, AppState>,
) -> Result<(), AppError> {
    let mut settings = state.settings.write().await;
    settings.apply(patch);
    settings.save_to_disk()?;
    Ok(())
}
```

### Persistent Store (Plugin)
```rust
use tauri_plugin_store::StoreExt;

// In setup
app.store("settings.json")?
    .set("theme", "dark");

// In command
#[tauri::command]
fn get_preference(app: tauri::AppHandle, key: String) -> Option<serde_json::Value> {
    app.store("settings.json").ok()?.get(&key)
}
```

---

## 3. Event System

### Rust → Frontend Events
```rust
use tauri::Emitter;

// Emit to all windows
app.emit("queue:progress", QueueProgress {
    task_id: "abc",
    percent: 75,
    stage: "rendering",
}).unwrap();

// Emit to specific window
app.get_webview_window("main")
    .unwrap()
    .emit("video:complete", video_id)
    .unwrap();
```

### Frontend Event Listener
```typescript
import { listen } from '@tauri-apps/api/event';

// Listen for queue progress
const unlisten = await listen<QueueProgress>('queue:progress', (event) => {
  useQueueStore.getState().updateProgress(event.payload);
});

// Cleanup on unmount
useEffect(() => {
  return () => { unlisten(); };
}, []);
```

### Channels (Streaming Data)
```rust
use tauri::ipc::Channel;

#[tauri::command]
async fn render_video(
    params: RenderParams,
    on_progress: Channel<RenderProgress>,
) -> Result<String, AppError> {
    for frame in 0..total_frames {
        // Process frame...
        on_progress.send(RenderProgress {
            frame, total: total_frames,
            percent: (frame * 100) / total_frames,
        })?;
    }
    Ok(output_path)
}
```

---

## 4. Multi-Window Architecture

### Spawn Window
```rust
use tauri::WebviewWindowBuilder;

#[tauri::command]
async fn open_editor(app: tauri::AppHandle, video_id: String) -> Result<(), AppError> {
    WebviewWindowBuilder::new(
        &app,
        format!("editor-{video_id}"),
        tauri::WebviewUrl::App(format!("/editor/{video_id}").into()),
    )
    .title(format!("Editor — {video_id}"))
    .inner_size(1280.0, 720.0)
    .min_inner_size(800.0, 600.0)
    .build()?;
    Ok(())
}
```

### Inter-Window Communication
```rust
// Window A sends to Window B
app.get_webview_window("editor-abc")
    .unwrap()
    .emit("timeline:update", timeline_data)?;
```

---

## 5. System Tray

```rust
use tauri::{
    menu::{MenuBuilder, MenuItemBuilder},
    tray::TrayIconBuilder,
};

fn setup_tray(app: &tauri::App) -> Result<(), Box<dyn std::error::Error>> {
    let show = MenuItemBuilder::with_id("show", "Show MetaGen").build(app)?;
    let queue = MenuItemBuilder::with_id("queue", "Queue (3 active)").build(app)?;
    let quit = MenuItemBuilder::with_id("quit", "Quit").build(app)?;

    let menu = MenuBuilder::new(app)
        .items(&[&show, &queue, &quit])
        .build()?;

    TrayIconBuilder::new()
        .icon(app.default_window_icon().unwrap().clone())
        .menu(&menu)
        .tooltip("MetaGen Studio")
        .on_menu_event(|app, event| match event.id().as_ref() {
            "show" => { app.get_webview_window("main").unwrap().show().unwrap(); }
            "queue" => { app.emit("navigate", "/queue").unwrap(); }
            "quit" => { app.exit(0); }
            _ => {}
        })
        .build(app)?;

    Ok(())
}
```

---

## 6. Auto-Updater

```rust
use tauri_plugin_updater::UpdaterExt;

#[tauri::command]
async fn check_for_updates(app: tauri::AppHandle) -> Result<Option<UpdateInfo>, AppError> {
    let updater = app.updater()?;
    match updater.check().await? {
        Some(update) => {
            Ok(Some(UpdateInfo {
                version: update.version.clone(),
                notes: update.body.clone(),
                date: update.date.map(|d| d.to_string()),
            }))
        }
        None => Ok(None),
    }
}

#[tauri::command]
async fn install_update(app: tauri::AppHandle) -> Result<(), AppError> {
    let updater = app.updater()?;
    if let Some(update) = updater.check().await? {
        update.download_and_install(
            |progress, total| {
                app.emit("update:progress", (progress, total)).unwrap();
            },
            || { app.emit("update:ready", ()).unwrap(); },
        ).await?;
    }
    Ok(())
}
```

---

## 7. Security — IPC Isolation Pattern

```json
// tauri.conf.json
{
  "app": {
    "security": {
      "csp": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'",
      "dangerousDisableAssetCspModification": false,
      "pattern": { "use": "isolation", "options": { "dir": "./isolation" } }
    }
  }
}
```

### Isolation Script
```javascript
// isolation/index.html — validates IPC messages before Tauri Core
window.__TAURI_ISOLATION_HOOK__ = (payload) => {
  // Validate command whitelist
  const allowed = ['video_create', 'auth_login', 'queue_status'];
  if (!allowed.includes(payload.cmd)) {
    console.warn('Blocked IPC:', payload.cmd);
    return null; // Block
  }
  // Sanitize params
  if (payload.args?.params?.title) {
    payload.args.params.title = sanitize(payload.args.params.title);
  }
  return payload; // Allow
};
```

---

## 8. Custom Protocol (Asset Serving)

```rust
use tauri::http::{Request, Response};

// Serve video files via custom protocol
tauri::Builder::default()
    .register_asynchronous_uri_scheme_protocol("media", |_ctx, request, responder| {
        tauri::async_runtime::spawn(async move {
            let path = request.uri().path();
            let file_path = format!("data/videos{path}");
            match tokio::fs::read(&file_path).await {
                Ok(data) => {
                    let mime = if path.ends_with(".mp4") { "video/mp4" }
                        else if path.ends_with(".webm") { "video/webm" }
                        else { "application/octet-stream" };
                    responder.respond(
                        Response::builder()
                            .header("Content-Type", mime)
                            .header("Accept-Ranges", "bytes")
                            .body(data)
                            .unwrap()
                    );
                }
                Err(_) => responder.respond(
                    Response::builder().status(404).body(vec![]).unwrap()
                ),
            }
        });
    })
```

### Frontend Usage
```tsx
<video src="media://localhost/output/video-abc.mp4" controls />
```

---

## 9. Deep Linking & File Association

```json
// tauri.conf.json
{
  "plugins": {
    "deep-link": {
      "desktop": {
        "schemes": ["metagen"]
      }
    }
  },
  "bundle": {
    "fileAssociations": [
      { "ext": ["mgn"], "mimeType": "application/x-metagen", "description": "MetaGen Project" }
    ]
  }
}
```

```rust
use tauri_plugin_deep_link::DeepLinkExt;

app.deep_link().on_open_url(|event| {
    let url = &event.urls()[0];
    // metagen://open?project=abc
    if url.scheme() == "metagen" {
        let project_id = url.query_pairs()
            .find(|(k, _)| k == "project")
            .map(|(_, v)| v.to_string());
        // Navigate to project
    }
});
```

---

## 10. Best Practices

1. **Always return `Result<T, AppError>`** from commands — never unwrap
2. **Use `State<'_>`** for dependency injection — not global statics
3. **Emit events for long operations** — queue, render, AI processing
4. **Use Channels** for streaming progress — not repeated events
5. **Isolate IPC** in production — validate all frontend messages
6. **Custom protocols** for media — `media://` not `file://` (security)
7. **Background mode** via system tray — don't exit when window closes
8. **Test commands** with `#[cfg(test)]` — mock State with test fixtures
9. **Use `tauri-plugin-store`** for preferences — not manual file I/O
10. **Scope permissions** in tauri.conf.json — minimal allowlist
