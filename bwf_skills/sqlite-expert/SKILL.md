---
name: sqlite-expert
description: Advanced SQLite + SQLCipher patterns — encrypted databases, WAL mode, FTS5 full-text search, JSON functions, migrations, backup, concurrent access, and PRAGMA tuning. Optimized for Tauri v2 + Rust desktop apps.
---

# SQLite Expert — Encrypted Local Database

Use this skill for local database operations with SQLite + SQLCipher in Rust desktop apps.

---

## 1. SQLCipher Encrypted Database

### Connection Setup (Rust)
```rust
use rusqlite::{Connection, params};

pub struct DbPool {
    conn: Connection,
}

impl DbPool {
    pub fn new(path: &str, passphrase: &str) -> Result<Self, AppError> {
        let conn = Connection::open(path)?;
        // SQLCipher encryption
        conn.pragma_update(None, "key", passphrase)?;
        // Performance PRAGMAs
        conn.pragma_update(None, "journal_mode", "WAL")?;
        conn.pragma_update(None, "synchronous", "NORMAL")?;
        conn.pragma_update(None, "cache_size", "-64000")?; // 64MB
        conn.pragma_update(None, "mmap_size", "268435456")?; // 256MB
        conn.pragma_update(None, "temp_store", "MEMORY")?;
        conn.pragma_update(None, "foreign_keys", "ON")?;
        // Run migrations
        Self::run_migrations(&conn)?;
        Ok(Self { conn })
    }
}
```

### Key Derivation
```rust
use argon2::{Argon2, password_hash::{SaltString, PasswordHasher}};

pub fn derive_db_key(master_password: &str, hwid: &str) -> String {
    let salt = SaltString::from_b64(&base64_encode(hwid)).unwrap();
    let argon2 = Argon2::default();
    let hash = argon2.hash_password(master_password.as_bytes(), &salt).unwrap();
    hash.hash.unwrap().to_string()
}
```

---

## 2. Migration System

```rust
const MIGRATIONS: &[(u32, &str)] = &[
    (1, "CREATE TABLE users (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        email TEXT UNIQUE NOT NULL,
        license_key TEXT,
        hwid TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
    )"),
    (2, "CREATE TABLE api_keys (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        provider TEXT NOT NULL CHECK(provider IN ('gemini','openai','anthropic')),
        key_value TEXT NOT NULL,
        daily_usage INTEGER DEFAULT 0,
        daily_limit INTEGER DEFAULT 1500,
        is_active INTEGER DEFAULT 1,
        last_used TEXT,
        created_at TEXT DEFAULT (datetime('now'))
    )"),
    (3, "CREATE TABLE videos (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        status TEXT DEFAULT 'draft' CHECK(status IN ('draft','queued','rendering','completed','failed')),
        output_path TEXT,
        duration_seconds REAL,
        resolution TEXT,
        metadata TEXT DEFAULT '{}',
        created_at TEXT DEFAULT (datetime('now'))
    )"),
    (4, "CREATE INDEX idx_videos_project ON videos(project_id)"),
    (5, "CREATE INDEX idx_videos_status ON videos(status)"),
    // ... more migrations
];

impl DbPool {
    fn run_migrations(conn: &Connection) -> Result<(), AppError> {
        conn.execute(
            "CREATE TABLE IF NOT EXISTS _migrations (
                version INTEGER PRIMARY KEY,
                applied_at TEXT DEFAULT (datetime('now'))
            )", [])?;

        let current: u32 = conn.query_row(
            "SELECT COALESCE(MAX(version), 0) FROM _migrations", [], |r| r.get(0)
        )?;

        for &(version, sql) in MIGRATIONS {
            if version > current {
                conn.execute(sql, [])?;
                conn.execute(
                    "INSERT INTO _migrations (version) VALUES (?1)",
                    params![version],
                )?;
            }
        }
        Ok(())
    }
}
```

---

## 3. FTS5 Full-Text Search

### Create FTS Table
```sql
CREATE VIRTUAL TABLE videos_fts USING fts5(
    title, description, tags,
    content='videos',
    content_rowid='rowid',
    tokenize='unicode61 remove_diacritics 2'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER videos_ai AFTER INSERT ON videos BEGIN
    INSERT INTO videos_fts(rowid, title, description, tags)
    VALUES (new.rowid, new.title, new.description, new.tags);
END;
CREATE TRIGGER videos_ad AFTER DELETE ON videos BEGIN
    INSERT INTO videos_fts(videos_fts, rowid, title, description, tags)
    VALUES ('delete', old.rowid, old.title, old.description, old.tags);
END;
CREATE TRIGGER videos_au AFTER UPDATE ON videos BEGIN
    INSERT INTO videos_fts(videos_fts, rowid, title, description, tags)
    VALUES ('delete', old.rowid, old.title, old.description, old.tags);
    INSERT INTO videos_fts(rowid, title, description, tags)
    VALUES (new.rowid, new.title, new.description, new.tags);
END;
```

### Search with Highlights
```rust
pub fn search_videos(query: &str) -> Result<Vec<SearchResult>, AppError> {
    let sql = "
        SELECT v.id, v.title, v.status,
            highlight(videos_fts, 0, '<mark>', '</mark>') as title_hl,
            snippet(videos_fts, 1, '<mark>', '</mark>', '...', 32) as desc_snippet,
            rank
        FROM videos_fts
        JOIN videos v ON v.rowid = videos_fts.rowid
        WHERE videos_fts MATCH ?1
        ORDER BY rank
        LIMIT 20
    ";
    // ...
}
```

---

## 4. JSON Functions

### Store & Query Metadata
```sql
-- Store flexible metadata as JSON
UPDATE videos SET metadata = json_patch(metadata, '{
    "model": "veo",
    "resolution": "1080p",
    "style": "cinematic",
    "tags": ["ai", "tutorial"]
}') WHERE id = ?;

-- Query JSON fields
SELECT id, title,
    json_extract(metadata, '$.model') as model,
    json_extract(metadata, '$.resolution') as resolution
FROM videos
WHERE json_extract(metadata, '$.model') = 'veo';

-- Array operations
SELECT id, title
FROM videos, json_each(json_extract(metadata, '$.tags')) AS tags
WHERE tags.value = 'tutorial';
```

---

## 5. Startup Health Check

```rust
pub fn run_integrity_check(&self) -> Result<(), AppError> {
    // 1. Database integrity
    let integrity: String = self.conn.query_row(
        "PRAGMA integrity_check", [], |r| r.get(0)
    )?;
    if integrity != "ok" {
        return Err(AppError::new("E5002", format!("DB corrupted: {integrity}")));
    }

    // 2. Reset stuck tasks
    self.conn.execute(
        "UPDATE queue_tasks SET status = 'pending', retry_count = retry_count + 1
         WHERE status = 'running'", []
    )?;

    // 3. WAL checkpoint
    self.conn.pragma_update(None, "wal_checkpoint", "TRUNCATE")?;

    // 4. Disk space check
    let free = fs2::free_space(".")?;
    if free < 1_073_741_824 { // < 1GB
        return Err(AppError::new("E5001", "Disk space < 1GB"));
    }

    Ok(())
}
```

---

## 6. Online Backup

```rust
use rusqlite::backup;

pub fn backup_database(&self, dest_path: &str) -> Result<(), AppError> {
    let dest = Connection::open(dest_path)?;
    let backup = backup::Backup::new(&self.conn, &dest)?;

    // Progressive backup (non-blocking)
    loop {
        let more = backup.step(100)?; // 100 pages per step
        let remaining = backup.remaining();
        let total = backup.pagecount();
        let progress = ((total - remaining) as f64 / total as f64) * 100.0;
        // Emit progress...
        if !more { break; }
        std::thread::sleep(std::time::Duration::from_millis(50));
    }

    Ok(())
}
```

---

## 7. Concurrent Access Patterns

```rust
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;

pub fn create_pool(path: &str, passphrase: &str) -> Pool<SqliteConnectionManager> {
    let manager = SqliteConnectionManager::file(path)
        .with_init(move |conn| {
            conn.pragma_update(None, "key", passphrase)?;
            conn.pragma_update(None, "journal_mode", "WAL")?;
            conn.pragma_update(None, "busy_timeout", "5000")?;
            Ok(())
        });

    Pool::builder()
        .max_size(8) // 1 writer + 7 readers
        .build(manager)
        .unwrap()
}
```

---

## 8. Query Optimization

```sql
-- Covering index (no table lookup needed)
CREATE INDEX idx_videos_status_created
ON videos(status, created_at DESC)
INCLUDE (id, title, output_path);

-- Partial index (only active records)
CREATE INDEX idx_queue_pending
ON queue_tasks(created_at)
WHERE status = 'pending';

-- Analyze query plan
EXPLAIN QUERY PLAN
SELECT * FROM videos WHERE project_id = ? AND status = 'completed'
ORDER BY created_at DESC LIMIT 10;
```

---

## 9. Best Practices

1. **WAL mode always** — concurrent reads + sequential writes
2. **`busy_timeout = 5000`** — retry on SQLITE_BUSY instead of failing
3. **Use transactions** — batch inserts/updates in `BEGIN...COMMIT`
4. **`foreign_keys = ON`** — enforce referential integrity
5. **JSON for flexible data** — metadata, config, tags
6. **FTS5 for search** — tokenize with `unicode61` for multilingual
7. **Backup daily** — use online backup API, not file copy
8. **Integrity check on startup** — detect corruption early
9. **Parameterized queries only** — never string interpolation (SQL injection)
10. **Index strategically** — `EXPLAIN QUERY PLAN` before and after
