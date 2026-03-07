---
name: flowise-fork-expert
description: Expert patterns for forking Flowise 3.0.13 — custom node development, Agent Flows v2, embedded mode for Tauri, TypeORM SQLite config, Socket.IO integration, and Express.js middleware. For Boom Open Visual Builder (Boom Builder).
---

# Flowise Fork Expert Skill

## Overview
Patterns for forking Flowise 3.0.13 as the visual workflow builder for Boom Open AI Employees.

## Flowise Architecture (v3.0.13)

```
flowise/
├── packages/
│   ├── server/            # Express.js backend
│   │   ├── src/
│   │   │   ├── index.ts          # Server entry
│   │   │   ├── routes/           # API routes
│   │   │   ├── services/         # Business logic
│   │   │   ├── database/         # TypeORM entities
│   │   │   └── utils/            # Helpers
│   │   └── package.json
│   ├── ui/                # React frontend
│   │   ├── src/
│   │   │   ├── views/            # Pages (Canvas, Marketplace)
│   │   │   ├── ui-component/     # Shared components
│   │   │   └── store/            # Redux store
│   │   └── package.json
│   └── components/        # Node definitions
│       ├── nodes/                # All available nodes
│       │   ├── llms/
│       │   ├── chains/
│       │   ├── agents/
│       │   ├── memory/
│       │   └── tools/
│       ├── credentials/          # API key configs
│       └── package.json
└── package.json
```

## Custom Node Development

### Node Structure
```typescript
// packages/components/nodes/desktopAction/DesktopAction.ts
import { INode, INodeData, INodeParams } from '../../../src/Interface';

class DesktopAction_Nodes implements INode {
    label: string = 'Desktop Action';
    name: string = 'desktopAction';
    version: number = 1.0;
    type: string = 'DesktopAction';
    icon: string = 'desktop.svg';
    category: string = 'Boom Open';
    description: string = 'Control desktop: click, type, screenshot, open app';
    baseClasses: string[] = ['DesktopAction'];

    inputs: INodeParams[] = [
        {
            label: 'Action Type',
            name: 'actionType',
            type: 'options',
            options: [
                { label: 'Click', name: 'click' },
                { label: 'Type Text', name: 'type' },
                { label: 'Screenshot', name: 'screenshot' },
                { label: 'Open App', name: 'openApp' },
                { label: 'Hotkey', name: 'hotkey' },
            ],
        },
        {
            label: 'Parameters',
            name: 'params',
            type: 'json',
            placeholder: '{"x": 100, "y": 200}',
            optional: true,
        },
    ];

    async init(nodeData: INodeData): Promise<any> {
        const actionType = nodeData.inputs?.actionType as string;
        const params = nodeData.inputs?.params;
        return { actionType, params };
    }

    async run(nodeData: INodeData, input: string): Promise<string> {
        const { actionType, params } = nodeData.instance;
        // Call gRPC bridge to execute desktop action
        const result = await grpcClient.executeAction(actionType, params);
        return JSON.stringify(result);
    }
}

module.exports = { nodeClass: DesktopAction_Nodes };
```

### Timer/Cron Node
```typescript
class TimerCron_Nodes implements INode {
    label: string = 'Timer / Cron';
    name: string = 'timerCron';
    category: string = 'Boom Open';
    description: string = 'Schedule AI Employee tasks on interval or cron';

    inputs: INodeParams[] = [
        {
            label: 'Schedule Type',
            name: 'scheduleType',
            type: 'options',
            options: [
                { label: 'Interval', name: 'interval' },
                { label: 'Cron Expression', name: 'cron' },
                { label: 'Once At', name: 'once' },
            ],
        },
        {
            label: 'Value',
            name: 'value',
            type: 'string',
            placeholder: '*/5 * * * * (every 5 min)',
        },
    ];
}
```

## Embedding Flowise in Tauri

### Strategy: Spawn as Child Process
```rust
// src-tauri/src/flowise_manager.rs
use std::process::{Command, Child, Stdio};

pub struct FlowiseManager {
    process: Option<Child>,
    port: u16,
}

impl FlowiseManager {
    pub fn new(port: u16) -> Self {
        Self { process: None, port }
    }

    pub fn start(&mut self, app_dir: &str) -> Result<(), String> {
        let flowise_path = format!("{}/flowise", app_dir);

        let child = Command::new("node")
            .arg(format!("{}/packages/server/dist/index.js", flowise_path))
            .env("PORT", self.port.to_string())
            .env("DATABASE_PATH", format!("{}/data/flowise.db", app_dir))
            .env("APIKEY_PATH", format!("{}/data/.api_keys", app_dir))
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| format!("Failed to start Flowise: {}", e))?;

        self.process = Some(child);
        Ok(())
    }

    pub fn stop(&mut self) {
        if let Some(ref mut child) = self.process {
            let _ = child.kill();
        }
        self.process = None;
    }
}
```

### Tauri WebView Integration
```rust
// Load Flowise UI inside a Tauri webview
tauri::WebviewWindowBuilder::new(
    &app,
    "builder",
    tauri::WebviewUrl::External(format!("http://localhost:{}", flowise_port).parse().unwrap()),
)
.title("Boom Builder")
.build()?;
```

## TypeORM SQLite Configuration

```typescript
// packages/server/src/database/config.ts
import { DataSource } from 'typeorm';

export const AppDataSource = new DataSource({
    type: 'better-sqlite3',
    database: process.env.DATABASE_PATH || './data/flowise.db',
    synchronize: false,
    logging: false,
    entities: ['src/database/entities/*.ts'],
    migrations: ['src/database/migrations/*.ts'],
});
```

## Key Modifications for Boom Open

1. **Rebrand UI** — "Boom Builder" header, colors matching design system
2. **Add custom node category** — "Boom Open" with Desktop Action, Timer, etc.
3. **Remove cloud-only nodes** — Keep only relevant nodes
4. **Embed database** — Share SQLite with main Tauri app
5. **gRPC client** — Connect to desktop controller service
6. **HAND.toml export** — Export workflow as AI Employee package
