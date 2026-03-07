---
name: grpc-rust-expert
description: gRPC patterns with tonic + prost in Rust — service definitions, bidirectional streaming, Tauri↔Flowise communication, error handling, reconnection, and health checks. For Boom Open's bridge between AI Engine and Visual Builder.
---

# gRPC Rust Expert Skill

## Overview
Patterns for building the gRPC bridge that connects Boom Open components: Tauri (Rust) ↔ Flowise (Node.js) ↔ AI Engine.

## Proto Definitions

```protobuf
// proto/boom.proto
syntax = "proto3";
package boom;

// Desktop Control Service (Rust server, Flowise client)
service DesktopControl {
    rpc Click (ClickRequest) returns (ActionResult);
    rpc TypeText (TypeRequest) returns (ActionResult);
    rpc CaptureScreen (CaptureRequest) returns (ScreenFrame);
    rpc Hotkey (HotkeyRequest) returns (ActionResult);
    rpc OpenApp (OpenAppRequest) returns (ActionResult);
    rpc StreamScreenUpdates (CaptureRequest) returns (stream ScreenFrame);
}

// AI Engine Service (Rust server, Flowise client)
service AiEngine {
    rpc Generate (GenerateRequest) returns (stream GenerateChunk);
    rpc Chat (ChatRequest) returns (stream ChatChunk);
    rpc AnalyzeScreen (ScreenFrame) returns (AnalysisResult);
    rpc ListModels (Empty) returns (ModelList);
}

// AI Employee Lifecycle (Rust server, UI client)
service EmployeeManager {
    rpc Hire (HireRequest) returns (EmployeeStatus);
    rpc Fire (FireRequest) returns (ActionResult);
    rpc GetStatus (EmployeeId) returns (EmployeeStatus);
    rpc StreamLogs (EmployeeId) returns (stream LogEntry);
}

// Common messages
message ClickRequest { int32 x = 1; int32 y = 2; string button = 3; }
message TypeRequest { string text = 1; }
message HotkeyRequest { repeated string keys = 1; }
message OpenAppRequest { string app_name = 1; string path = 2; }
message CaptureRequest { int32 monitor = 1; string format = 2; }
message ScreenFrame { bytes data = 1; int32 width = 2; int32 height = 3; string format = 4; }
message ActionResult { bool success = 1; string error = 2; }
message GenerateRequest { string model = 1; string prompt = 2; repeated string images = 3; }
message GenerateChunk { string text = 1; bool done = 2; }
message ChatRequest { string model = 1; repeated ChatMessage messages = 2; }
message ChatMessage { string role = 1; string content = 2; }
message ChatChunk { string content = 1; bool done = 2; }
message AnalysisResult { string description = 1; repeated UiElement elements = 2; }
message UiElement { string label = 1; int32 x = 2; int32 y = 3; int32 w = 4; int32 h = 5; string type = 6; }
message HireRequest { string definition_id = 1; string config_json = 2; }
message FireRequest { string instance_id = 1; }
message EmployeeId { string id = 1; }
message EmployeeStatus { string id = 1; string state = 2; string name = 3; }
message LogEntry { int64 timestamp = 1; string level = 2; string message = 3; }
message ModelList { repeated ModelInfo models = 1; }
message ModelInfo { string name = 1; int64 size = 2; string family = 3; }
message Empty {}
```

## Rust Server (tonic)

```rust
// build.rs
fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        .compile(&["proto/boom.proto"], &["proto"])?;
    Ok(())
}
```

```rust
// src/grpc_server.rs
use tonic::{transport::Server, Request, Response, Status};
use tokio_stream::wrappers::ReceiverStream;

pub mod boom_proto {
    tonic::include_proto!("boom");
}

use boom_proto::desktop_control_server::{DesktopControl, DesktopControlServer};
use boom_proto::*;

pub struct DesktopControlService { /* ... */ }

#[tonic::async_trait]
impl DesktopControl for DesktopControlService {
    async fn click(&self, req: Request<ClickRequest>) -> Result<Response<ActionResult>, Status> {
        let r = req.into_inner();
        // Execute click via enigo
        Ok(Response::new(ActionResult { success: true, error: String::new() }))
    }

    type StreamScreenUpdatesStream = ReceiverStream<Result<ScreenFrame, Status>>;

    async fn stream_screen_updates(
        &self, req: Request<CaptureRequest>,
    ) -> Result<Response<Self::StreamScreenUpdatesStream>, Status> {
        let (tx, rx) = tokio::sync::mpsc::channel(16);
        tokio::spawn(async move {
            loop {
                // Capture screen frame and send
                let frame = ScreenFrame { data: vec![], width: 1920, height: 1080, format: "png".into() };
                if tx.send(Ok(frame)).await.is_err() { break; }
                tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
            }
        });
        Ok(Response::new(ReceiverStream::new(rx)))
    }
}

pub async fn start_grpc_server(port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let addr = format!("[::1]:{}", port).parse()?;
    let service = DesktopControlService {};
    Server::builder()
        .add_service(DesktopControlServer::new(service))
        .serve(addr)
        .await?;
    Ok(())
}
```

## Node.js Client (for Flowise)

```typescript
// Flowise side: gRPC client to call Rust desktop controller
import * as grpc from '@grpc/grpc-js';
import * as protoLoader from '@grpc/proto-loader';

const PROTO_PATH = './proto/boom.proto';
const packageDef = protoLoader.loadSync(PROTO_PATH);
const boomProto = grpc.loadPackageDefinition(packageDef).boom as any;

const client = new boomProto.DesktopControl(
    'localhost:50051',
    grpc.credentials.createInsecure()
);

export function click(x: number, y: number): Promise<any> {
    return new Promise((resolve, reject) => {
        client.Click({ x, y, button: 'left' }, (err: any, resp: any) => {
            if (err) reject(err); else resolve(resp);
        });
    });
}
```

## Cargo.toml Dependencies
```toml
[dependencies]
tonic = "0.12"
prost = "0.13"
tokio = { version = "1", features = ["full"] }
tokio-stream = "0.1"

[build-dependencies]
tonic-build = "0.12"
```
