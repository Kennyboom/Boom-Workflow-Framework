---
name: realtime-ml-engine-expert
description: Expert in realtime AI/ML engine optimization for Python. Focuses on FaceFusion module extraction, PyTorch, TensorRT 10.x execution provider for ONNXRuntime, multi-threading, shared memory IPC, and maintaining >30fps pipelines.
---

# Realtime ML Engine Expert

## What is this skill
This skill provides best practices for running Heavy Deep Learning models (like Face Swap, Voice Conversion) in real-time (>30fps), minimizing latency, and optimizing VRAM strictly.

## FaceFusion Module Extraction
DO NOT run FaceFusion as a CLI via subprocess for real-time. Instead, extract and load its modules directly in memory:
```python
import insightface
from insightface.app import FaceAnalysis

app = FaceAnalysis(name='buffalo_l')
app.prepare(ctx_id=0, det_size=(640, 640))
swapper = insightface.model_zoo.get_model('inswapper_128.onnx', providers=['CUDAExecutionProvider'])
```

## TensorRT 10.x with ONNXRuntime
To get maximum FPS on NVIDIA GPUs, use the TensorRT execution provider. The first run will compile an engine file `.trt` which takes a few minutes, but subsequent runs are instantaneous.
```python
providers = [
    ('TensorrtExecutionProvider', {
        'trt_engine_cache_enable': True,
        'trt_engine_cache_path': './trt_cache',
        'trt_fp16_enable': True, 
        'trt_max_workspace_size': 2147483648 # 2GB
    }),
    ('CUDAExecutionProvider', {}),
    ('CPUExecutionProvider', {})
]
import onnxruntime
session = onnxruntime.InferenceSession("model.onnx", providers=providers)
```

## Real-time Threading & Queues
Separate Capture, Processing, and Output into different threads to avoid blocking and stuttering. Always drop the oldest frames if processing is too slow.
```python
import threading
import queue
import cv2

frame_queue = queue.Queue(maxsize=2) # Keep maxsize small = lower latency

def capture_thread(cap):
    while running:
        ret, frame = cap.read()
        if not ret: break
        if frame_queue.full():
            try:
                frame_queue.get_nowait() # Drop oldest frame
            except queue.Empty:
                pass
        frame_queue.put(frame)
```

## Shared Memory (Python writes, Rust/C++ reads)
Use `multiprocessing.shared_memory` to pass large frames between processes with ZERO copy:
```python
from multiprocessing import shared_memory
import numpy as np

# Create memory block for a 1080p BGRA frame
size = 1920 * 1080 * 4
shm = shared_memory.SharedMemory(name="video_buffer", create=True, size=size)

# When you have a new frame:
dst = np.ndarray(frame.shape, dtype=frame.dtype, buffer=shm.buf)
np.copyto(dst, frame)
```
