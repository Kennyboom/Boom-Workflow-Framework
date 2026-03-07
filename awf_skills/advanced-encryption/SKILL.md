---
name: advanced-encryption
description: Data protection patterns — token vault with SQLCipher, at-rest encryption, key derivation (Argon2/PBKDF2), secure IPC validation, encrypted file attachments, and credential rotation. For desktop apps handling sensitive data.
---

# Advanced Encryption — Data Protection

Use this skill for encrypting sensitive data in desktop applications.

---

## 1. Token Vault (Encrypted Credential Storage)

```rust
use aes_gcm::{Aes256Gcm, Key, Nonce, aead::Aead, KeyInit};
use argon2::{Argon2, password_hash::{SaltString, PasswordHasher}};
use rand::RngCore;

pub struct TokenVault {
    cipher: Aes256Gcm,
}

impl TokenVault {
    pub fn new(master_password: &str, salt: &[u8]) -> Result<Self, AppError> {
        let key = Self::derive_key(master_password, salt)?;
        let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&key));
        Ok(Self { cipher })
    }

    fn derive_key(password: &str, salt: &[u8]) -> Result<[u8; 32], AppError> {
        let mut key = [0u8; 32];
        Argon2::default()
            .hash_password_into(password.as_bytes(), salt, &mut key)
            .map_err(|e| AppError::new("E9001", format!("Key derivation failed: {e}")))?;
        Ok(key)
    }

    pub fn encrypt(&self, plaintext: &[u8]) -> Result<Vec<u8>, AppError> {
        let mut nonce_bytes = [0u8; 12];
        rand::thread_rng().fill_bytes(&mut nonce_bytes);
        let nonce = Nonce::from_slice(&nonce_bytes);

        let ciphertext = self.cipher.encrypt(nonce, plaintext)
            .map_err(|e| AppError::new("E9002", format!("Encryption failed: {e}")))?;

        // Prepend nonce to ciphertext
        let mut result = nonce_bytes.to_vec();
        result.extend(ciphertext);
        Ok(result)
    }

    pub fn decrypt(&self, data: &[u8]) -> Result<Vec<u8>, AppError> {
        if data.len() < 12 {
            return Err(AppError::new("E9003", "Invalid encrypted data"));
        }
        let (nonce_bytes, ciphertext) = data.split_at(12);
        let nonce = Nonce::from_slice(nonce_bytes);

        self.cipher.decrypt(nonce, ciphertext)
            .map_err(|e| AppError::new("E9003", format!("Decryption failed: {e}")))
    }
}
```

---

## 2. API Key Storage

```rust
impl TokenVault {
    pub fn store_api_key(&self, db: &DbPool, provider: &str, key: &str) -> Result<(), AppError> {
        let encrypted = self.encrypt(key.as_bytes())?;
        let encoded = base64::engine::general_purpose::STANDARD.encode(&encrypted);
        db.execute(
            "INSERT OR REPLACE INTO api_keys (provider, key_value) VALUES (?1, ?2)",
            params![provider, encoded],
        )?;
        Ok(())
    }

    pub fn get_api_key(&self, db: &DbPool, provider: &str) -> Result<String, AppError> {
        let encoded: String = db.query_row(
            "SELECT key_value FROM api_keys WHERE provider = ?1 AND is_active = 1",
            params![provider],
            |row| row.get(0),
        )?;
        let encrypted = base64::engine::general_purpose::STANDARD.decode(&encoded)?;
        let plaintext = self.decrypt(&encrypted)?;
        String::from_utf8(plaintext).map_err(|e| AppError::new("E9004", e.to_string()))
    }
}
```

---

## 3. File Encryption

```rust
use aes_gcm::aead::stream::{EncryptorBE32, DecryptorBE32};
use std::io::{Read, Write, BufReader, BufWriter};

pub fn encrypt_file(
    vault: &TokenVault,
    input_path: &str,
    output_path: &str,
) -> Result<(), AppError> {
    let key = vault.derive_file_key(input_path)?;
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&key));

    let input = std::fs::File::open(input_path)?;
    let output = std::fs::File::create(output_path)?;
    let mut reader = BufReader::new(input);
    let mut writer = BufWriter::new(output);

    // Stream encryption in 64KB chunks
    let mut buffer = [0u8; 65536];
    let mut nonce_bytes = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    writer.write_all(&nonce_bytes)?;

    let mut chunk_index: u32 = 0;
    loop {
        let n = reader.read(&mut buffer)?;
        if n == 0 { break; }

        // Unique nonce per chunk
        let mut chunk_nonce = nonce_bytes;
        chunk_nonce[8..12].copy_from_slice(&chunk_index.to_be_bytes());
        let nonce = Nonce::from_slice(&chunk_nonce);

        let encrypted = cipher.encrypt(nonce, &buffer[..n])
            .map_err(|_| AppError::new("E9002", "Chunk encryption failed"))?;

        writer.write_all(&(encrypted.len() as u32).to_be_bytes())?;
        writer.write_all(&encrypted)?;
        chunk_index += 1;
    }
    writer.flush()?;
    Ok(())
}
```

---

## 4. Secure IPC Validation

```rust
/// Validate IPC payload before processing
pub fn validate_ipc_payload(command: &str, args: &serde_json::Value) -> Result<(), AppError> {
    match command {
        "auth_login" => {
            require_fields(args, &["email", "password"])?;
            validate_email(args["email"].as_str().unwrap())?;
        }
        "ai_key_add" => {
            require_fields(args, &["provider", "key"])?;
            let provider = args["provider"].as_str().unwrap();
            if !["gemini", "openai", "anthropic"].contains(&provider) {
                return Err(AppError::new("E9005", "Invalid provider"));
            }
            // Never log the actual key
        }
        "video_create" => {
            require_fields(args, &["title", "model"])?;
            validate_length(args["title"].as_str().unwrap(), 1, 200)?;
        }
        _ => {
            // Unknown command — reject
            return Err(AppError::new("E9006", format!("Unknown command: {command}")));
        }
    }
    Ok(())
}
```

---

## 5. Credential Rotation

```rust
pub async fn rotate_encryption_key(
    db: &DbPool,
    old_vault: &TokenVault,
    new_password: &str,
) -> Result<(), AppError> {
    // 1. Get all encrypted values
    let keys: Vec<(String, String)> = db.query_map(
        "SELECT provider, key_value FROM api_keys",
        [], |row| Ok((row.get(0)?, row.get(1)?)),
    )?;

    // 2. Decrypt with old vault
    let mut decrypted: Vec<(String, String)> = Vec::new();
    for (provider, encrypted) in &keys {
        let plain = old_vault.get_api_key(db, provider)?;
        decrypted.push((provider.clone(), plain));
    }

    // 3. Create new vault with new password
    let new_salt = generate_salt();
    let new_vault = TokenVault::new(new_password, &new_salt)?;

    // 4. Re-encrypt with new vault
    for (provider, plaintext) in &decrypted {
        new_vault.store_api_key(db, provider, plaintext)?;
    }

    // 5. Update salt in database
    db.execute("UPDATE settings SET value = ?1 WHERE key = 'vault_salt'",
        params![base64::encode(&new_salt)])?;

    Ok(())
}
```

---

## 6. Best Practices

1. **AES-256-GCM** for symmetric encryption — authenticated encryption
2. **Argon2id** for key derivation — memory-hard, GPU-resistant
3. **Unique nonce per encryption** — never reuse with same key
4. **Stream encryption** for large files — 64KB chunks
5. **Base64-encode ciphertext** for database storage
6. **Validate all IPC inputs** — whitelist commands, check fields
7. **Never log secrets** — API keys, passwords, tokens
8. **Key rotation** — support re-encryption with new password
9. **Zeroize sensitive data** — use `zeroize` crate to clear secrets from memory
10. **Encrypted backups** — backup files inherit encryption
