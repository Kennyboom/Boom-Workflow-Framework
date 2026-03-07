---
name: video-streaming-preview
description: Real-time video preview in desktop apps — custom Tauri protocol streaming, adaptive bitrate, frame-accurate seeking, waveform visualization, and timeline scrubbing. For video editing applications.
---

# Video Streaming & Preview — Desktop Video Player

Use this skill for video preview, playback, and timeline interaction in Tauri apps.

---

## 1. Custom Protocol for Video Streaming

```rust
use tauri::http::{Request, Response, header::*};
use std::io::{Read, Seek, SeekFrom};

fn register_media_protocol(builder: tauri::Builder<tauri::Wry>) -> tauri::Builder<tauri::Wry> {
    builder.register_asynchronous_uri_scheme_protocol("media", |_ctx, request, responder| {
        tauri::async_runtime::spawn(async move {
            let path = percent_decode_str(request.uri().path())
                .decode_utf8_lossy().to_string();
            let file_path = format!("data/media{path}");

            match handle_range_request(&file_path, &request).await {
                Ok(response) => responder.respond(response),
                Err(_) => responder.respond(
                    Response::builder().status(404).body(vec![]).unwrap()
                ),
            }
        });
    })
}

async fn handle_range_request(path: &str, request: &Request) -> Result<Response<Vec<u8>>, AppError> {
    let mut file = std::fs::File::open(path)?;
    let file_size = file.metadata()?.len();
    let mime = mime_from_path(path);

    // Parse Range header for streaming
    if let Some(range) = request.headers().get("range") {
        let range_str = range.to_str().unwrap_or("");
        let (start, end) = parse_range(range_str, file_size);
        let length = end - start + 1;

        file.seek(SeekFrom::Start(start))?;
        let mut buf = vec![0u8; length as usize];
        file.read_exact(&mut buf)?;

        Ok(Response::builder()
            .status(206)
            .header("Content-Type", mime)
            .header("Content-Range", format!("bytes {start}-{end}/{file_size}"))
            .header("Content-Length", length.to_string())
            .header("Accept-Ranges", "bytes")
            .body(buf)?)
    } else {
        let mut buf = Vec::new();
        file.read_to_end(&mut buf)?;
        Ok(Response::builder()
            .status(200)
            .header("Content-Type", mime)
            .header("Content-Length", file_size.to_string())
            .header("Accept-Ranges", "bytes")
            .body(buf)?)
    }
}

fn parse_range(range: &str, total: u64) -> (u64, u64) {
    let range = range.trim_start_matches("bytes=");
    let parts: Vec<&str> = range.split('-').collect();
    let start: u64 = parts[0].parse().unwrap_or(0);
    let end: u64 = parts.get(1).and_then(|s| s.parse().ok()).unwrap_or(total - 1);
    (start, end.min(total - 1))
}
```

---

## 2. Frame-Accurate Seeking

```rust
/// Generate keyframe index for instant seeking
pub async fn build_keyframe_index(video_path: &str) -> Result<Vec<KeyframeInfo>, AppError> {
    let output = Command::new("ffprobe")
        .args([
            "-v", "quiet",
            "-select_streams", "v:0",
            "-show_frames",
            "-show_entries", "frame=pkt_pts_time,pict_type,key_frame",
            "-print_format", "json",
            video_path,
        ])
        .output().await?;

    let data: serde_json::Value = serde_json::from_slice(&output.stdout)?;
    let frames = data["frames"].as_array().unwrap();

    Ok(frames.iter()
        .filter(|f| f["key_frame"].as_i64() == Some(1))
        .map(|f| KeyframeInfo {
            timestamp: f["pkt_pts_time"].as_str().unwrap().parse().unwrap(),
            frame_type: f["pict_type"].as_str().unwrap().to_string(),
        })
        .collect())
}
```

---

## 3. Adaptive Bitrate Preview

```typescript
interface PreviewQuality {
  label: string;
  scale: number;
  fps: number;
}

const PREVIEW_QUALITIES: PreviewQuality[] = [
  { label: 'Draft', scale: 0.25, fps: 15 },
  { label: 'Preview', scale: 0.5, fps: 24 },
  { label: 'Full', scale: 1.0, fps: 30 },
];

export function VideoPreview({ videoId }: { videoId: string }) {
  const [quality, setQuality] = useState<PreviewQuality>(PREVIEW_QUALITIES[1]);
  const [isPlaying, setIsPlaying] = useState(false);

  return (
    <div className="relative bg-black rounded-lg overflow-hidden">
      <video
        src={`media://localhost/videos/${videoId}/preview_${quality.label.toLowerCase()}.mp4`}
        className="w-full"
        onTimeUpdate={(e) => updateTimeline(e.currentTarget.currentTime)}
      />
      {/* Quality selector */}
      <div className="absolute top-2 right-2 flex gap-1">
        {PREVIEW_QUALITIES.map(q => (
          <button key={q.label}
            className={`px-2 py-1 text-xs rounded ${q === quality ? 'bg-white text-black' : 'bg-black/60 text-white'}`}
            onClick={() => setQuality(q)}>
            {q.label}
          </button>
        ))}
      </div>
    </div>
  );
}
```

---

## 4. Audio Waveform Visualization

```typescript
export async function generateWaveform(audioUrl: string): Promise<Float32Array> {
  const response = await fetch(audioUrl);
  const arrayBuffer = await response.arrayBuffer();
  const audioContext = new AudioContext();
  const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);

  const channelData = audioBuffer.getChannelData(0);
  const samplesPerPixel = Math.floor(channelData.length / 2000); // 2000 bars
  const peaks = new Float32Array(2000);

  for (let i = 0; i < 2000; i++) {
    const start = i * samplesPerPixel;
    const end = start + samplesPerPixel;
    let max = 0;
    for (let j = start; j < end; j++) {
      const abs = Math.abs(channelData[j]);
      if (abs > max) max = abs;
    }
    peaks[i] = max;
  }
  return peaks;
}

export function Waveform({ peaks, currentTime, duration }: WaveformProps) {
  return (
    <canvas
      ref={(canvas) => {
        if (!canvas) return;
        const ctx = canvas.getContext('2d')!;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const barWidth = canvas.width / peaks.length;
        const progress = currentTime / duration;

        peaks.forEach((peak, i) => {
          const x = i * barWidth;
          const height = peak * canvas.height * 0.8;
          ctx.fillStyle = i / peaks.length < progress ? '#818cf8' : '#374151';
          ctx.fillRect(x, (canvas.height - height) / 2, barWidth - 1, height);
        });
      }}
      className="w-full h-16"
    />
  );
}
```

---

## 5. Best Practices

1. **Range requests for video** — `206 Partial Content` for streaming
2. **Keyframe index** — build once, seek instantly
3. **Draft quality for editing** — 25% scale, 15fps = smooth UI
4. **Waveform from AudioContext** — decode + peak detection
5. **Custom protocol** — `media://` not `file://` for security
6. **Pre-generate preview proxies** — lower res copies for smooth editing
