---
name: webgpu-video-processing
description: WebGPU compute shaders for real-time video processing in WebView — color correction, chroma key, filters, CNN upscale, and zero-copy video textures. For Tauri desktop apps with GPU-accelerated preview.
---

# WebGPU Video Processing — GPU Compute in WebView

Use this skill for GPU-accelerated video effects and real-time preview in Tauri WebView.

---

## 1. WebGPU Device Setup

```typescript
export async function initWebGPU(): Promise<GPUDevice> {
  if (!navigator.gpu) throw new Error('WebGPU not supported');
  const adapter = await navigator.gpu.requestAdapter({ powerPreference: 'high-performance' });
  if (!adapter) throw new Error('No GPU adapter found');
  const device = await adapter.requestDevice({
    requiredFeatures: ['float32-filterable'],
    requiredLimits: { maxStorageBufferBindingSize: 256 * 1024 * 1024 },
  });
  return device;
}
```

---

## 2. Zero-Copy Video Texture

```typescript
export function importVideoFrame(device: GPUDevice, video: HTMLVideoElement): GPUExternalTexture {
  // Direct GPU memory — no CPU copy
  return device.importExternalTexture({ source: video });
}

// Usage in render pass
const bindGroup = device.createBindGroup({
  layout: pipeline.getBindGroupLayout(0),
  entries: [
    { binding: 0, resource: importVideoFrame(device, videoElement) },
    { binding: 1, resource: device.createSampler({ magFilter: 'linear' }) },
  ],
});
```

---

## 3. Color Correction Compute Shader

```wgsl
// color_correction.wgsl
@group(0) @binding(0) var inputTex: texture_external;
@group(0) @binding(1) var outputTex: texture_storage_2d<rgba8unorm, write>;
@group(0) @binding(2) var<uniform> params: ColorParams;

struct ColorParams {
  brightness: f32,
  contrast: f32,
  saturation: f32,
  temperature: f32,
  hue_shift: f32,
  gamma: f32,
}

fn rgb_to_hsl(c: vec3f) -> vec3f {
  let mx = max(c.r, max(c.g, c.b));
  let mn = min(c.r, min(c.g, c.b));
  let l = (mx + mn) * 0.5;
  if (mx == mn) { return vec3f(0.0, 0.0, l); }
  let d = mx - mn;
  let s = select(d / (2.0 - mx - mn), d / (mx + mn), l > 0.5);
  var h: f32;
  if (mx == c.r) { h = (c.g - c.b) / d; }
  else if (mx == c.g) { h = 2.0 + (c.b - c.r) / d; }
  else { h = 4.0 + (c.r - c.g) / d; }
  h = h / 6.0;
  if (h < 0.0) { h += 1.0; }
  return vec3f(h, s, l);
}

@compute @workgroup_size(16, 16)
fn main(@builtin(global_invocation_id) gid: vec3u) {
  let dims = textureDimensions(inputTex);
  if (gid.x >= dims.x || gid.y >= dims.y) { return; }

  var color = textureLoad(inputTex, vec2i(gid.xy));

  // Brightness
  color = vec4f(color.rgb + params.brightness, color.a);
  // Contrast
  color = vec4f((color.rgb - 0.5) * params.contrast + 0.5, color.a);
  // Gamma
  color = vec4f(pow(color.rgb, vec3f(1.0 / params.gamma)), color.a);
  // Saturation
  let gray = dot(color.rgb, vec3f(0.2126, 0.7152, 0.0722));
  color = vec4f(mix(vec3f(gray), color.rgb, params.saturation), color.a);

  textureStore(outputTex, vec2i(gid.xy), clamp(color, vec4f(0.0), vec4f(1.0)));
}
```

---

## 4. Chroma Key (Green Screen Removal)

```wgsl
@compute @workgroup_size(16, 16)
fn chroma_key(@builtin(global_invocation_id) gid: vec3u) {
  let color = textureLoad(inputTex, vec2i(gid.xy));
  let key_color = vec3f(0.0, 1.0, 0.0); // Green
  let distance = length(color.rgb - key_color);
  let threshold = 0.4;
  let alpha = smoothstep(threshold - 0.1, threshold + 0.1, distance);
  textureStore(outputTex, vec2i(gid.xy), vec4f(color.rgb, alpha));
}
```

---

## 5. Real-time Filter Pipeline

```typescript
export class FilterPipeline {
  private device: GPUDevice;
  private pipelines: Map<string, GPUComputePipeline> = new Map();

  async addFilter(name: string, shaderCode: string) {
    const module = this.device.createShaderModule({ code: shaderCode });
    const pipeline = this.device.createComputePipeline({
      layout: 'auto',
      compute: { module, entryPoint: 'main' },
    });
    this.pipelines.set(name, pipeline);
  }

  processFrame(video: HTMLVideoElement, filters: string[]) {
    const encoder = this.device.createCommandEncoder();
    let currentTexture = this.importVideoFrame(video);

    for (const filterName of filters) {
      const pipeline = this.pipelines.get(filterName)!;
      const pass = encoder.beginComputePass();
      pass.setPipeline(pipeline);
      pass.setBindGroup(0, this.createBindGroup(currentTexture));
      pass.dispatchWorkgroups(
        Math.ceil(video.videoWidth / 16),
        Math.ceil(video.videoHeight / 16),
      );
      pass.end();
    }

    this.device.queue.submit([encoder.finish()]);
  }
}
```

---

## 6. Best Practices

1. **`importExternalTexture`** for video — zero-copy, maximum performance
2. **Workgroup size 16x16** — optimal for most GPUs
3. **Check dimensions** in shader — prevent out-of-bounds writes
4. **Pipeline caching** — create once, reuse per frame
5. **Fallback to Canvas2D** — if WebGPU unavailable (older WebView)
6. **`requestAnimationFrame`** for preview loop — sync with display refresh
