---
name: ffmpeg-expert
description: Advanced FFmpeg video processing — GPU acceleration (NVENC AV1), complex filter graphs, concat, audio mixing, subtitle overlay, thumbnail generation, progress tracking. Orchestrated from Rust via tokio::process.
---

# FFmpeg Expert — Video Processing Engine

Use this skill for all video/audio processing tasks in desktop applications with FFmpeg.

---

## 1. Rust FFmpeg Orchestrator

### Process Wrapper
```rust
use tokio::process::Command;
use tokio::io::{AsyncBufReadExt, BufReader};

pub struct FfmpegJob {
    pub input: String,
    pub output: String,
    pub args: Vec<String>,
}

pub async fn run_ffmpeg(
    job: FfmpegJob,
    on_progress: impl Fn(f64),
) -> Result<String, AppError> {
    let mut cmd = Command::new("ffmpeg")
        .args(["-y", "-i", &job.input])
        .args(&job.args)
        .args(["-progress", "pipe:1", &job.output])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .map_err(|e| AppError::new("E4002", format!("FFmpeg spawn failed: {e}")))?;

    // Parse progress from stdout
    if let Some(stdout) = cmd.stdout.take() {
        let reader = BufReader::new(stdout);
        let mut lines = reader.lines();
        while let Ok(Some(line)) = lines.next_line().await {
            if line.starts_with("out_time_us=") {
                let us: f64 = line[12..].parse().unwrap_or(0.0);
                on_progress(us / 1_000_000.0); // seconds
            }
        }
    }

    let status = cmd.wait().await?;
    if !status.success() {
        return Err(AppError::new("E4001", "FFmpeg process failed"));
    }
    Ok(job.output)
}
```

---

## 2. GPU Acceleration (NVENC AV1)

### Hardware Detection
```rust
pub async fn detect_gpu_encoder() -> Option<String> {
    let output = Command::new("ffmpeg")
        .args(["-hide_banner", "-encoders"])
        .output().await.ok()?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    if stdout.contains("av1_nvenc") { Some("av1_nvenc".into()) }
    else if stdout.contains("hevc_nvenc") { Some("hevc_nvenc".into()) }
    else if stdout.contains("h264_nvenc") { Some("h264_nvenc".into()) }
    else { None }
}
```

### NVENC AV1 Encoding (75-100% faster)
```bash
# Full GPU pipeline — zero-copy CUDA
ffmpeg -y \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -c:v av1_nvenc -preset p5 -tune hq \
  -rc:v vbr -cq 24 -b:v 8M -maxrate 12M \
  -c:a aac -b:a 192k \
  output.mp4
```

### Presets (Speed vs Quality)
| Preset | Speed | Quality | Use Case |
|--------|:-----:|:-------:|----------|
| `p1` | Fastest | Low | Preview/Draft |
| `p4` | Fast | Good | Batch production |
| `p5` | Medium | High | Standard export |
| `p7` | Slowest | Best | Final delivery |

### Software Fallback
```bash
# CPU fallback when no GPU
ffmpeg -y -i input.mp4 \
  -c:v libsvtav1 -preset 6 -crf 30 \
  -c:a aac -b:a 128k \
  output.mp4
```

---

## 3. Complex Filter Graphs

### Text Overlay + Caption Burn-in
```bash
ffmpeg -y -i video.mp4 \
  -vf "drawtext=fontfile='Inter-Bold.ttf':\
    text='%{pts\:hms}':fontsize=24:fontcolor=white:\
    x=(w-tw)/2:y=h-th-40:\
    box=1:boxcolor=black@0.7:boxborderw=8" \
  -c:v av1_nvenc -preset p5 output.mp4
```

### Picture-in-Picture
```bash
ffmpeg -y \
  -i main.mp4 -i overlay.mp4 \
  -filter_complex "[1:v]scale=320:-1[pip];\
    [0:v][pip]overlay=W-w-20:H-h-20" \
  -c:v av1_nvenc output.mp4
```

### Multi-input Composition
```bash
ffmpeg -y \
  -i bg.mp4 -i avatar.png -i caption.ass \
  -filter_complex "\
    [0:v]scale=1920:1080[bg];\
    [1:v]scale=200:-1[avatar];\
    [bg][avatar]overlay=50:50[main];\
    [main]ass=caption.ass[out]" \
  -map "[out]" -map 0:a \
  -c:v av1_nvenc output.mp4
```

---

## 4. Video Concatenation

### Concat with Crossfade
```bash
ffmpeg -y \
  -i clip1.mp4 -i clip2.mp4 -i clip3.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[v01];\
    [v01][2:v]xfade=transition=fade:duration=1:offset=8[vout];\
    [0:a][1:a]acrossfade=d=1[a01];\
    [a01][2:a]acrossfade=d=1[aout]" \
  -map "[vout]" -map "[aout]" \
  -c:v av1_nvenc output.mp4
```

### Transition Types
| Transition | Effect |
|-----------|--------|
| `fade` | Classic fade |
| `wipeleft` | Wipe left to right |
| `slidedown` | Slide down |
| `circleopen` | Circle reveal |
| `dissolve` | Pixel dissolve |
| `smoothleft` | Smooth slide |

---

## 5. Audio Processing

### Mix BGM + Voiceover
```bash
ffmpeg -y \
  -i video.mp4 -i bgm.mp3 -i voiceover.wav \
  -filter_complex "\
    [1:a]volume=0.15[bgm];\
    [2:a]volume=1.0[vo];\
    [bgm][vo]amix=inputs=2:duration=first[aout]" \
  -map 0:v -map "[aout]" \
  -c:v copy -c:a aac -b:a 192k output.mp4
```

### Volume Normalization
```bash
# Two-pass loudness normalization (EBU R128)
ffmpeg -y -i input.mp4 -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json -f null -
# Then apply measured values in second pass
ffmpeg -y -i input.mp4 \
  -af "loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=-23.5:measured_TP=-4.2:measured_LRA=7.1" \
  output.mp4
```

### Audio Extraction
```bash
ffmpeg -y -i video.mp4 -vn -acodec pcm_s16le -ar 44100 -ac 2 audio.wav
```

---

## 6. Subtitle / Caption

### SRT Burn-in with Styling
```bash
ffmpeg -y -i video.mp4 \
  -vf "subtitles=captions.srt:force_style='\
    FontName=Inter,FontSize=22,\
    PrimaryColour=&H00FFFFFF,\
    OutlineColour=&H00000000,Outline=2,\
    Shadow=1,MarginV=40'" \
  output.mp4
```

### ASS Animated Captions
```ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Style: Default,Inter,48,&H00FFFFFF,&H000000FF,&H00000000,&HAA000000,-1,0,0,0,100,100,0,0,1,3,1,2,10,10,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,{\fad(500,500)}Welcome to MetaGen Studio
```

---

## 7. Thumbnail & Poster Generation

### Scene Detection → Keyframes
```bash
# Extract keyframes at scene changes
ffmpeg -y -i video.mp4 \
  -vf "select='gt(scene,0.3)',scale=640:-1" \
  -vsync vfr -frame_pts true \
  thumbnails/thumb_%04d.jpg
```

### Grid Thumbnail (Contact Sheet)
```bash
ffmpeg -y -i video.mp4 \
  -vf "fps=1/10,scale=320:-1,tile=4x3" \
  -frames:v 1 contact_sheet.jpg
```

---

## 8. Resolution & Format Presets

```rust
pub enum ExportPreset {
    YouTube1080p,
    YouTube4K,
    InstagramReels,
    TikTok,
    Shorts,
    TwitterX,
}

impl ExportPreset {
    pub fn to_args(&self) -> Vec<String> {
        match self {
            Self::YouTube1080p => vec![
                "-s", "1920x1080", "-r", "30",
                "-c:v", "av1_nvenc", "-preset", "p5",
                "-b:v", "8M", "-c:a", "aac", "-b:a", "192k",
            ],
            Self::YouTube4K => vec![
                "-s", "3840x2160", "-r", "30",
                "-c:v", "av1_nvenc", "-preset", "p5",
                "-b:v", "35M", "-c:a", "aac", "-b:a", "256k",
            ],
            Self::InstagramReels => vec![
                "-s", "1080x1920", "-r", "30", "-t", "90",
                "-c:v", "av1_nvenc", "-b:v", "6M",
            ],
            Self::TikTok | Self::Shorts => vec![
                "-s", "1080x1920", "-r", "30", "-t", "60",
                "-c:v", "av1_nvenc", "-b:v", "5M",
            ],
            _ => vec!["-c:v", "av1_nvenc", "-preset", "p5"],
        }.iter().map(|s| s.to_string()).collect()
    }
}
```

---

## 9. Probe & Metadata

```rust
pub async fn probe_video(path: &str) -> Result<VideoMeta, AppError> {
    let output = Command::new("ffprobe")
        .args([
            "-v", "quiet",
            "-print_format", "json",
            "-show_format", "-show_streams",
            path,
        ])
        .output().await?;
    let info: serde_json::Value = serde_json::from_slice(&output.stdout)?;
    Ok(VideoMeta {
        duration: info["format"]["duration"].as_str()
            .and_then(|d| d.parse::<f64>().ok()).unwrap_or(0.0),
        width: info["streams"][0]["width"].as_u64().unwrap_or(0) as u32,
        height: info["streams"][0]["height"].as_u64().unwrap_or(0) as u32,
        fps: parse_fps(info["streams"][0]["r_frame_rate"].as_str().unwrap_or("30/1")),
        codec: info["streams"][0]["codec_name"].as_str().unwrap_or("unknown").into(),
    })
}
```

---

## 10. Best Practices

1. **Always use `-y`** to overwrite without prompt
2. **GPU first, CPU fallback** — detect encoder at startup
3. **Progress via `-progress pipe:1`** — parse `out_time_us` for progress bar
4. **Timeout with `tokio::time::timeout`** — kill stuck FFmpeg after 5 min
5. **Save partial on crash** — use `-f segment` for long renders
6. **Normalize audio** with EBU R128 — consistent loudness
7. **AV1 for storage, H.264 for compatibility** — offer both export options
8. **Batch with `-threads 0`** — let FFmpeg use all CPU cores
9. **Probe before process** — validate input metadata
10. **Clean temp files** — delete intermediates after concat/merge
