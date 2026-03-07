---
name: ai-lip-sync
description: AI-powered lip synchronization — facial landmark detection, phoneme-to-viseme mapping, audio-visual alignment, multi-language dubbing, and quality scoring. For video localization and avatar animation.
---

# AI Lip Sync — Audio-Visual Alignment

Use this skill for lip-sync generation, dubbing, and avatar mouth animation.

---

## 1. Lip-Sync Pipeline Architecture

```
Audio Input → STT → Phoneme Extraction → Viseme Mapping → Face Landmark Detection
                                                                    ↓
Output Video ← Face Transform ← Blend Weights ← Temporal Smoothing ←
```

---

## 2. Phoneme-to-Viseme Mapping

```rust
// Standard viseme groups (14 mouth shapes)
pub enum Viseme {
    Silence,  // Mouth closed
    AE,       // "cat", "bat"
    AH,       // "cut", "but"
    AO,       // "caught", "bought"
    EH,       // "red", "said"
    ER,       // "bird", "her"
    IH,       // "sit", "big"
    OH,       // "go", "no"
    OO,       // "too", "blue"
    P_B_M,    // Lips pressed: "pat", "bat", "mat"
    F_V,      // Lower lip + upper teeth: "fat", "vat"
    TH,       // Tongue between teeth: "the", "think"
    L_N,      // Tongue tip up: "let", "net"
    S_Z,      // Teeth together: "sit", "zip"
}

pub fn phoneme_to_viseme(phoneme: &str) -> Viseme {
    match phoneme {
        "SIL" | "SP" => Viseme::Silence,
        "AA" | "AE" => Viseme::AE,
        "AH" | "AX" => Viseme::AH,
        "AO" | "AW" => Viseme::AO,
        "EH" | "EY" => Viseme::EH,
        "ER" => Viseme::ER,
        "IH" | "IY" => Viseme::IH,
        "OW" => Viseme::OH,
        "UH" | "UW" => Viseme::OO,
        "P" | "B" | "M" => Viseme::P_B_M,
        "F" | "V" => Viseme::F_V,
        "TH" | "DH" => Viseme::TH,
        "L" | "N" | "NG" => Viseme::L_N,
        "S" | "Z" | "SH" | "ZH" => Viseme::S_Z,
        _ => Viseme::AH,
    }
}
```

---

## 3. Audio-Visual Alignment

```rust
pub struct LipSyncFrame {
    pub timestamp_ms: u64,
    pub viseme: Viseme,
    pub intensity: f32,    // 0.0 - 1.0
    pub blend_weights: Vec<f32>, // For morph targets
}

pub fn generate_lip_sync_track(
    phoneme_timeline: &[(u64, String, f32)], // (timestamp, phoneme, duration)
) -> Vec<LipSyncFrame> {
    let mut frames = Vec::new();
    let frame_rate = 30.0; // 30 FPS

    for (timestamp, phoneme, duration) in phoneme_timeline {
        let viseme = phoneme_to_viseme(phoneme);
        let frame_count = (duration * frame_rate).ceil() as usize;

        for i in 0..frame_count {
            let t = i as f32 / frame_count as f32;
            // Smooth attack/release envelope
            let intensity = if t < 0.2 {
                t / 0.2 // Attack
            } else if t > 0.7 {
                (1.0 - t) / 0.3 // Release
            } else {
                1.0 // Sustain
            };

            frames.push(LipSyncFrame {
                timestamp_ms: timestamp + (i as f32 / frame_rate * 1000.0) as u64,
                viseme,
                intensity,
                blend_weights: viseme_to_blend_weights(&viseme, intensity),
            });
        }
    }
    frames
}
```

---

## 4. External Lip-Sync API Integration

```rust
// Option A: Sync Labs / Wav2Lip cloud API
pub async fn cloud_lip_sync(
    video_path: &str,
    audio_path: &str,
) -> Result<String, AppError> {
    let client = reqwest::Client::new();
    let form = reqwest::multipart::Form::new()
        .file("video", video_path).await?
        .file("audio", audio_path).await?;

    let resp = client.post("https://api.synclabs.so/lipsync")
        .bearer_auth(env::var("SYNCLABS_API_KEY")?)
        .multipart(form)
        .send().await?;

    let result: serde_json::Value = resp.json().await?;
    Ok(result["output_url"].as_str().unwrap().to_string())
}

// Option B: Local Wav2Lip (Python subprocess)
pub async fn local_lip_sync(
    video_path: &str,
    audio_path: &str,
    output_path: &str,
) -> Result<(), AppError> {
    Command::new("python3")
        .args([
            "models/Wav2Lip/inference.py",
            "--face", video_path,
            "--audio", audio_path,
            "--outfile", output_path,
            "--pads", "0", "15", "0", "0",
            "--nosmooth",
        ])
        .status().await?;
    Ok(())
}
```

---

## 5. Quality Scoring

```rust
pub fn score_lip_sync(
    audio_phonemes: &[(u64, String)],
    video_visemes: &[(u64, Viseme)],
) -> f32 {
    let mut matches = 0;
    let mut total = 0;
    let tolerance_ms = 80; // 80ms tolerance

    for (a_time, phoneme) in audio_phonemes {
        let expected = phoneme_to_viseme(phoneme);
        total += 1;
        // Find closest video viseme
        if let Some((_, viseme)) = video_visemes.iter()
            .find(|(v_time, _)| (*v_time as i64 - *a_time as i64).unsigned_abs() < tolerance_ms)
        {
            if *viseme == expected { matches += 1; }
        }
    }

    matches as f32 / total as f32
}
```

---

## 6. Best Practices

1. **Phoneme extraction** with Whisper timestamps — word-level alignment
2. **14 viseme groups** cover all English sounds
3. **Smooth transitions** — attack/sustain/release envelope per phoneme
4. **80ms tolerance** for audio-visual sync — human perception threshold
5. **Cloud API for quality** — Sync Labs for production lip-sync
6. **Local Wav2Lip for privacy** — offline processing option
