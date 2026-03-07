---
name: hand-toml-spec
description: HAND.toml specification for AI Employee packages — format definition, validation rules, SKILL.md structure, versioning, dependency resolution, marketplace submission requirements, and example templates.
---

# HAND.toml Specification — AI Employee Package Format

## Overview
HAND.toml is the manifest file for AI Employee packages in Boom Open. It defines identity, pricing, permissions, skills, and runtime requirements.

## Full Specification

```toml
# ═══════════════════════════════════════════════
# HAND.toml — AI Employee Definition
# Version: 1.0
# ═══════════════════════════════════════════════

[hand]
id = "sales-rep-pro"              # Unique ID (lowercase, hyphens)
name = "👨‍💼 Sales Rep Pro"          # Display name (emoji + text)
version = "1.2.0"                  # Semver
author = "@top_developer"          # Developer handle
category = "business"              # business|marketing|technical|ecommerce|creative|hr|finance
description = "Autonomous sales development representative that generates and qualifies leads."
min_engine = "ollama"              # picolm|ollama|cloud
min_ram_mb = 512                   # Minimum RAM required
tags = ["sales", "leads", "outreach", "crm"]

[pricing]
model = "subscription"             # free|subscription|one_time|credits
price_usd = 29.00                  # Price in USD
trial_days = 7                     # Free trial period (0 = no trial)
credits_per_action = 0             # For credit-based pricing

[permissions]
required = [
    "browser.navigate",
    "browser.input",
    "file.read",
    "network.http",
]
optional = [
    "clipboard.write",
    "notification.send",
]

[employee]
role = "Sales Development Representative"
avatar = "assets/avatar.png"       # 256x256 PNG
banner = "assets/banner.png"       # 1200x400 PNG (marketplace)

[employee.schedule]
type = "interval"                  # interval|cron|manual|event
every = "2h"                       # For interval type
# cron = "0 9 * * 1-5"            # For cron type (weekdays 9am)

[employee.kpi]
metrics = [
    { name = "leads_generated", label = "Leads Generated", unit = "count" },
    { name = "emails_sent", label = "Emails Sent", unit = "count" },
    { name = "response_rate", label = "Response Rate", unit = "percent" },
]

[skills]
files = [
    "skills/outreach.md",
    "skills/qualify-lead.md",
    "skills/follow-up.md",
]

[dependencies]
boom_open = ">=1.0.0"              # Min Boom Open version
ollama_models = ["gemma3:4b"]      # Required models

[marketplace]
demo_video = "assets/demo.mp4"     # 30-60s demo (optional)
screenshots = [
    "assets/screenshot-1.png",
    "assets/screenshot-2.png",
]
changelog = "CHANGELOG.md"
readme = "README.md"
```

## SKILL.md Format

```markdown
# Skill: Lead Outreach

## Trigger
When: Every 2 hours (scheduled)
Condition: Leads queue has uncontacted entries

## Steps

1. **Open CRM** (browser.navigate)
   - Go to https://app.hubspot.com
   - Login if needed

2. **Get uncontacted leads** (browser.input + file.read)
   - Navigate to Leads → Filter: Status = New
   - Extract: Name, Email, Company, Title

3. **Draft personalized email** (ai.generate)
   - Use template: outreach-v2
   - Personalize with lead's company and role
   - Tone: professional, friendly

4. **Send email** (network.http)
   - Via SendGrid API or Gmail
   - Track: message_id, timestamp

5. **Update CRM** (browser.input)
   - Mark lead as "Contacted"
   - Add note with email summary

6. **Log KPI** (internal)
   - Increment: leads_contacted +1
   - Increment: emails_sent +1

## Error Handling
- If CRM login fails → Retry 3x → Notify user
- If email send fails → Queue for next run
- If lead has no email → Skip, log warning
```

## Package Structure

```
sales-rep-pro/
├── HAND.toml              # Manifest (required)
├── README.md              # Documentation (required)
├── CHANGELOG.md           # Version history
├── assets/
│   ├── avatar.png         # 256x256 employee avatar
│   ├── banner.png         # 1200x400 marketplace banner
│   ├── demo.mp4           # 30-60s demo video
│   ├── screenshot-1.png
│   └── screenshot-2.png
└── skills/
    ├── outreach.md        # Lead outreach skill
    ├── qualify-lead.md    # Lead qualification skill
    └── follow-up.md      # Follow-up skill
```

## Validation Rules

| Field | Rule |
|-------|------|
| `hand.id` | `^[a-z0-9-]{3,50}$`, unique in marketplace |
| `hand.version` | Valid semver |
| `hand.category` | One of allowed categories |
| `pricing.price_usd` | >= 0, max 999.99 |
| `permissions.required` | Only known permission strings |
| `employee.avatar` | PNG, 256x256, < 500KB |
| `skills.files` | All files must exist, valid markdown |

## Rust Validator

```rust
use serde::Deserialize;
use std::path::Path;

#[derive(Deserialize)]
pub struct HandToml {
    pub hand: HandMeta,
    pub pricing: Pricing,
    pub permissions: Permissions,
    pub employee: Employee,
    pub skills: Skills,
}

pub fn validate(path: &Path) -> Result<HandToml, Vec<String>> {
    let content = std::fs::read_to_string(path.join("HAND.toml"))
        .map_err(|_| vec!["HAND.toml not found".into()])?;
    let hand: HandToml = toml::from_str(&content)
        .map_err(|e| vec![format!("Parse error: {}", e)])?;

    let mut errors = vec![];

    // Validate ID format
    if !hand.hand.id.chars().all(|c| c.is_ascii_lowercase() || c == '-' || c.is_ascii_digit()) {
        errors.push("hand.id must be lowercase alphanumeric with hyphens".into());
    }

    // Validate skill files exist
    for skill in &hand.skills.files {
        if !path.join(skill).exists() {
            errors.push(format!("Skill file not found: {}", skill));
        }
    }

    // Validate avatar exists
    if !path.join(&hand.employee.avatar).exists() {
        errors.push("Avatar file not found".into());
    }

    if errors.is_empty() { Ok(hand) } else { Err(errors) }
}
```
