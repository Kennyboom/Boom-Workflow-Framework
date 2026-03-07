---
name: telemetry-analytics
description: Privacy-first product analytics — opt-in telemetry, feature usage tracking, error reporting with Sentry, A/B testing with feature flags, and GDPR-compliant data collection. For desktop apps.
---

# Telemetry & Analytics — Product Intelligence

Use this skill for implementing privacy-respecting analytics in desktop applications.

---

## 1. Opt-in Telemetry System

```rust
use serde::{Serialize, Deserialize};
use reqwest::Client;

#[derive(Serialize, Deserialize, Clone)]
pub struct TelemetryConfig {
    pub enabled: bool,
    pub anonymous_id: String, // Random UUID, not tied to user
    pub share_usage: bool,
    pub share_errors: bool,
}

pub struct Telemetry {
    config: TelemetryConfig,
    client: Client,
    queue: Vec<TelemetryEvent>,
}

#[derive(Serialize)]
struct TelemetryEvent {
    event: String,
    properties: serde_json::Value,
    timestamp: String,
    anonymous_id: String,
    app_version: String,
    os: String,
}

impl Telemetry {
    pub fn track(&mut self, event: &str, properties: serde_json::Value) {
        if !self.config.enabled || !self.config.share_usage { return; }
        self.queue.push(TelemetryEvent {
            event: event.to_string(),
            properties,
            timestamp: chrono::Utc::now().to_rfc3339(),
            anonymous_id: self.config.anonymous_id.clone(),
            app_version: env!("CARGO_PKG_VERSION").to_string(),
            os: std::env::consts::OS.to_string(),
        });
    }

    pub async fn flush(&mut self) -> Result<(), AppError> {
        if self.queue.is_empty() { return Ok(()); }
        let events: Vec<_> = self.queue.drain(..).collect();
        self.client.post("https://telemetry.metagen.app/v1/batch")
            .json(&events)
            .send().await?;
        Ok(())
    }
}
```

---

## 2. Feature Usage Tracking

```rust
impl Telemetry {
    pub fn track_feature(&mut self, feature: &str) {
        self.track("feature_used", serde_json::json!({ "feature": feature }));
    }
    pub fn track_export(&mut self, format: &str, resolution: &str, duration: f64) {
        self.track("video_export", serde_json::json!({
            "format": format, "resolution": resolution, "duration_seconds": duration,
        }));
    }
    pub fn track_ai_model(&mut self, model: &str, action: &str) {
        self.track("ai_usage", serde_json::json!({ "model": model, "action": action }));
    }
}
```

---

## 3. Error Reporting (Sentry)

```typescript
// Frontend Sentry setup
import * as Sentry from '@sentry/react';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  release: `metagen@${APP_VERSION}`,
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0,
  replaysOnErrorSampleRate: 1.0,
  beforeSend(event) {
    // Strip PII
    if (event.user) {
      delete event.user.email;
      delete event.user.ip_address;
    }
    return event;
  },
  integrations: [
    Sentry.replayIntegration({ maskAllText: true, blockAllMedia: true }),
  ],
});
```

```rust
// Rust-side error reporting
pub fn report_error(error: &AppError) {
    if !telemetry_config.share_errors { return; }
    sentry::capture_event(sentry::protocol::Event {
        message: Some(format!("[{}] {}", error.code, error.message)),
        level: match error.severity {
            Severity::Critical => sentry::Level::Fatal,
            Severity::Error => sentry::Level::Error,
            Severity::Warning => sentry::Level::Warning,
            _ => sentry::Level::Info,
        },
        ..Default::default()
    });
}
```

---

## 4. Feature Flags & A/B Testing

```rust
use std::collections::HashMap;

pub struct FeatureFlags {
    flags: HashMap<String, FeatureFlag>,
}

#[derive(Deserialize)]
struct FeatureFlag {
    enabled: bool,
    rollout_percentage: u8, // 0-100
    variant: Option<String>, // A/B variant
}

impl FeatureFlags {
    pub fn is_enabled(&self, flag: &str, user_id: &str) -> bool {
        match self.flags.get(flag) {
            Some(f) => {
                if !f.enabled { return false; }
                if f.rollout_percentage >= 100 { return true; }
                // Consistent bucketing by user ID
                let bucket = crc32fast::hash(user_id.as_bytes()) % 100;
                bucket < f.rollout_percentage as u32
            }
            None => false,
        }
    }

    pub async fn refresh(&mut self) -> Result<(), AppError> {
        let resp = reqwest::get("https://api.metagen.app/v1/feature-flags")
            .await?.json().await?;
        self.flags = resp;
        Ok(())
    }
}
```

---

## 5. Best Practices

1. **Opt-in only** — never collect without explicit consent
2. **Anonymous IDs** — random UUID, never HWID or email
3. **No PII in telemetry** — strip emails, IP, usernames
4. **Batch sends** — queue events, flush every 5 min or on exit
5. **Feature flags** — consistent bucketing by user for A/B tests
6. **Sentry for errors** — session replay on error, masked text
