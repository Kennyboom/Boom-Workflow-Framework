---
name: anti-tamper-protection
description: Desktop application security — HWID binding, anti-debug detection, code integrity verification, license validation, and update certificate pinning. For protecting commercial desktop software.
---

# Anti-Tamper Protection — Desktop Security

Use this skill for protecting desktop applications against piracy and tampering.

---

## 1. HWID (Hardware ID) Binding

```rust
use sysinfo::System;
use sha2::{Sha256, Digest};

pub fn generate_hwid() -> String {
    let mut sys = System::new_all();
    sys.refresh_all();

    let mut hasher = Sha256::new();

    // CPU info
    if let Some(cpu) = sys.cpus().first() {
        hasher.update(cpu.brand().as_bytes());
        hasher.update(cpu.vendor_id().as_bytes());
    }

    // Total memory (rounded to nearest GB)
    let ram_gb = sys.total_memory() / 1_073_741_824;
    hasher.update(ram_gb.to_be_bytes());

    // OS identifier
    hasher.update(System::os_version().unwrap_or_default().as_bytes());
    hasher.update(System::host_name().unwrap_or_default().as_bytes());

    // Disk serial (Windows)
    #[cfg(target_os = "windows")]
    {
        if let Ok(output) = std::process::Command::new("wmic")
            .args(["diskdrive", "get", "SerialNumber"])
            .output()
        {
            hasher.update(&output.stdout);
        }
    }

    let result = hasher.finalize();
    hex::encode(&result[..16]) // 32-char hex string
}
```

---

## 2. License Validation

```rust
use ed25519_dalek::{PublicKey, Signature, Verifier};

#[derive(Serialize, Deserialize)]
pub struct License {
    pub key: String,
    pub email: String,
    pub plan: String,
    pub hwid: String,
    pub expires_at: String,
    pub signature: String,
}

impl License {
    pub fn validate(&self) -> Result<bool, AppError> {
        // 1. Check expiry
        let expires = chrono::NaiveDateTime::parse_from_str(&self.expires_at, "%Y-%m-%dT%H:%M:%S")
            .map_err(|_| AppError::new("E8001", "Invalid license date"))?;
        if chrono::Utc::now().naive_utc() > expires {
            return Err(AppError::new("E8002", "License expired"));
        }

        // 2. Check HWID
        let current_hwid = generate_hwid();
        if self.hwid != current_hwid {
            return Err(AppError::new("E8003", "HWID mismatch — license bound to another device"));
        }

        // 3. Verify signature (Ed25519)
        let public_key_bytes = hex::decode(PUBLIC_KEY_HEX)?;
        let public_key = PublicKey::from_bytes(&public_key_bytes)?;
        let payload = format!("{}:{}:{}:{}", self.key, self.email, self.plan, self.hwid);
        let signature_bytes = hex::decode(&self.signature)?;
        let signature = Signature::from_bytes(&signature_bytes)?;
        public_key.verify(payload.as_bytes(), &signature)
            .map_err(|_| AppError::new("E8004", "Invalid license signature"))?;

        Ok(true)
    }
}
```

---

## 3. Anti-Debug Detection

```rust
/// Check if a debugger is attached
pub fn is_debugged() -> bool {
    #[cfg(target_os = "windows")]
    {
        use windows::Win32::System::Diagnostics::Debug::IsDebuggerPresent;
        unsafe { IsDebuggerPresent().into() }
    }
    #[cfg(target_os = "linux")]
    {
        use std::fs;
        let status = fs::read_to_string("/proc/self/status").unwrap_or_default();
        // TracerPid != 0 means debugger attached
        status.lines()
            .find(|l| l.starts_with("TracerPid:"))
            .map(|l| l.split(':').nth(1).unwrap_or("0").trim() != "0")
            .unwrap_or(false)
    }
    #[cfg(target_os = "macos")]
    {
        // sysctl check
        false // Simplified
    }
}
```

---

## 4. Binary Integrity Check

```rust
use sha2::{Sha256, Digest};

pub fn verify_binary_integrity() -> Result<(), AppError> {
    let exe_path = std::env::current_exe()?;
    let exe_bytes = std::fs::read(&exe_path)?;

    let mut hasher = Sha256::new();
    hasher.update(&exe_bytes);
    let hash = hex::encode(hasher.finalize());

    // Compare with embedded hash (set during build)
    let expected_hash = env!("BINARY_HASH");
    if hash != expected_hash {
        return Err(AppError::new("E8005", "Binary integrity check failed — possible tampering"));
    }
    Ok(())
}
```

---

## 5. Update Certificate Pinning

```rust
use reqwest::tls::Certificate;

pub fn create_pinned_client() -> Result<reqwest::Client, AppError> {
    let cert_pem = include_bytes!("../certs/update-server.pem");
    let cert = Certificate::from_pem(cert_pem)?;

    let client = reqwest::Client::builder()
        .add_root_certificate(cert)
        .danger_accept_invalid_certs(false)
        .min_tls_version(reqwest::tls::Version::TLS_1_3)
        .build()?;

    Ok(client)
}
```

---

## 6. Best Practices

1. **HWID = hash of hardware** — CPU + RAM + disk serial, not MAC address
2. **Ed25519 signatures** on licenses — fast, secure, small keys
3. **Check license on startup** — offline validation, online refresh weekly
4. **Anti-debug = detect only** — log and gracefully degrade, don't crash
5. **Binary hash at build time** — embed hash, verify at runtime
6. **TLS 1.3 + cert pinning** — prevent MITM on update channel
7. **Grace period** — 7-day offline grace before requiring re-validation
