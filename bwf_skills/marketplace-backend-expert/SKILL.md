---
name: marketplace-backend-expert
description: AI Employee Marketplace backend patterns — review pipeline, developer tiers, revenue tracking, credit system, FTS5 search, recommendation engine, payout processing, and abuse protection. For Boom Open Marketplace API.
---

# Marketplace Backend Expert Skill

## Overview
Backend architecture and API patterns for the AI Employee Marketplace in Boom Open.

## Database Schema (SQLite + SQLCipher)

```sql
-- AI Employee Definitions (listings)
CREATE TABLE ai_e_definitions (
    id TEXT PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK(category IN ('business','marketing','technical','ecommerce','creative','hr','finance')),
    author_id TEXT NOT NULL REFERENCES developer_profiles(id),
    version TEXT NOT NULL,
    price_model TEXT NOT NULL CHECK(price_model IN ('free','subscription','one_time','credits')),
    price_usd REAL DEFAULT 0,
    trial_days INTEGER DEFAULT 0,
    credits_per_action INTEGER DEFAULT 0,
    min_engine TEXT DEFAULT 'picolm',
    min_ram_mb INTEGER DEFAULT 128,
    permissions_json TEXT NOT NULL,    -- JSON array
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','reviewing','approved','rejected','archived')),
    install_count INTEGER DEFAULT 0,
    rating_avg REAL DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    hand_toml TEXT NOT NULL,           -- Full HAND.toml content
    package_hash TEXT NOT NULL,        -- SHA-256 of package
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (author_id) REFERENCES developer_profiles(id)
);

-- Full-text search index
CREATE VIRTUAL TABLE ai_e_fts USING fts5(
    name, description, category, tags,
    content='ai_e_definitions',
    content_rowid='rowid'
);

-- Reviews
CREATE TABLE ai_e_reviews (
    id TEXT PRIMARY KEY,
    definition_id TEXT NOT NULL REFERENCES ai_e_definitions(id),
    user_id TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
    title TEXT,
    body TEXT,
    usage_days INTEGER DEFAULT 0,
    helpful_count INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now')),
    UNIQUE(definition_id, user_id)
);

-- Installed instances
CREATE TABLE ai_e_instances (
    id TEXT PRIMARY KEY,
    definition_id TEXT NOT NULL REFERENCES ai_e_definitions(id),
    user_id TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK(status IN ('active','paused','error','fired')),
    config_json TEXT,
    hired_at TEXT DEFAULT (datetime('now')),
    fired_at TEXT
);

-- Developer profiles
CREATE TABLE developer_profiles (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    tier TEXT DEFAULT 'starter' CHECK(tier IN ('starter','verified','gold','partner')),
    total_revenue REAL DEFAULT 0,
    total_installs INTEGER DEFAULT 0,
    kyc_verified BOOLEAN DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now'))
);

-- Revenue tracking
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    definition_id TEXT NOT NULL,
    buyer_id TEXT NOT NULL,
    developer_id TEXT NOT NULL,
    amount_usd REAL NOT NULL,
    platform_fee REAL NOT NULL,          -- 15-20%
    developer_payout REAL NOT NULL,      -- 80-85%
    type TEXT CHECK(type IN ('subscription','one_time','credits')),
    stripe_payment_id TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);

-- Payout requests
CREATE TABLE developer_payouts (
    id TEXT PRIMARY KEY,
    developer_id TEXT NOT NULL,
    amount_usd REAL NOT NULL,
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','processing','completed','failed')),
    stripe_transfer_id TEXT,
    requested_at TEXT DEFAULT (datetime('now')),
    completed_at TEXT
);

-- Credit system
CREATE TABLE user_credits (
    user_id TEXT PRIMARY KEY,
    balance INTEGER DEFAULT 0,
    total_purchased INTEGER DEFAULT 0,
    total_spent INTEGER DEFAULT 0
);

CREATE TABLE credit_transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    amount INTEGER NOT NULL,           -- positive = add, negative = spend
    reason TEXT NOT NULL,
    definition_id TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);
```

## API Endpoints

```rust
// Marketplace browsing
GET  /api/marketplace                    → List/search AI Employees
GET  /api/marketplace/:slug             → AI Employee detail
GET  /api/marketplace/categories        → List categories
GET  /api/marketplace/trending          → Trending AI Employees
GET  /api/marketplace/recommended       → Personalized recommendations

// Install/uninstall
POST /api/instances                      → Hire (install) AI Employee
DELETE /api/instances/:id               → Fire (uninstall) AI Employee
GET  /api/instances                      → List hired AI Employees
PATCH /api/instances/:id                → Update config (pause/resume)

// Reviews
POST /api/marketplace/:slug/reviews     → Leave review
GET  /api/marketplace/:slug/reviews     → List reviews
POST /api/reviews/:id/helpful           → Mark review as helpful

// Developer
POST /api/marketplace/submit            → Submit AI Employee for review
GET  /api/developer/dashboard           → Revenue + install stats
GET  /api/developer/revenue             → Revenue history
POST /api/developer/payouts/request     → Request payout ($50 min)
GET  /api/developer/payouts             → Payout history

// Credits
GET  /api/credits/balance               → Current balance
POST /api/credits/purchase              → Buy credits (Stripe)
GET  /api/credits/history               → Transaction history

// Admin
GET  /api/admin/review-queue            → Pending reviews
POST /api/admin/review/:id/approve      → Approve submission
POST /api/admin/review/:id/reject       → Reject with reason
```

## Search (FTS5)

```sql
-- Search AI Employees with ranking
SELECT ae.*, rank
FROM ai_e_fts fts
JOIN ai_e_definitions ae ON ae.rowid = fts.rowid
WHERE ai_e_fts MATCH ?
  AND ae.status = 'approved'
ORDER BY rank
LIMIT 20 OFFSET ?;

-- Autocomplete suggestions
SELECT DISTINCT name FROM ai_e_fts
WHERE ai_e_fts MATCH ? || '*'
LIMIT 5;
```

## Revenue Share Logic

```rust
pub fn calculate_shares(amount: f64, developer_tier: &str) -> (f64, f64) {
    let developer_share = match developer_tier {
        "partner" => 0.90,   // 90%
        "gold" => 0.88,      // 88%
        "verified" | "starter" => 0.85, // 85%
        _ => 0.85,
    };
    let dev_payout = amount * developer_share;
    let platform_fee = amount - dev_payout;
    (dev_payout, platform_fee)
}
```

## Review Pipeline

```
Submit → Auto-Scan → Review Queue → Manual Review → Approve/Reject
   │         │              │              │
   │    ☑ WASM sandbox  ☑ Queue     ☑ Checklist:
   │    ☑ Malware scan  ☑ Priority    - No malware
   │    ☑ Size check    ☑ Assign      - Permissions minimal
   │    ☑ Schema valid  ☑ Notify      - Description accurate
   │                                   - Works as described
   │                                   - Pricing reasonable
   └─→ Developer notified of result
```

## Credit System Logic

```rust
pub async fn consume_credits(
    db: &SqlitePool,
    user_id: &str,
    definition_id: &str,
    action_cost: i32,
) -> Result<bool, sqlx::Error> {
    let balance: i32 = sqlx::query_scalar("SELECT balance FROM user_credits WHERE user_id = ?")
        .bind(user_id).fetch_one(db).await?;

    if balance < action_cost {
        return Ok(false); // Insufficient credits
    }

    sqlx::query("UPDATE user_credits SET balance = balance - ?, total_spent = total_spent + ? WHERE user_id = ?")
        .bind(action_cost).bind(action_cost).bind(user_id).execute(db).await?;

    sqlx::query("INSERT INTO credit_transactions (id, user_id, amount, reason, definition_id) VALUES (?, ?, ?, 'action', ?)")
        .bind(uuid::Uuid::new_v4().to_string()).bind(user_id).bind(-action_cost).bind(definition_id)
        .execute(db).await?;

    Ok(true)
}
```
