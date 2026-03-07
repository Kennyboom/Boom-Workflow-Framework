---
name: windows-virtual-device-integration
description: Expert in Windows Virtual Devices using Python and C#. Covers Virtual Camera (DirectShow/softcam), Virtual Audio (WASAPI), COM interface handling, ctypes bindings, and async device handling.
---

# Windows Virtual Device Integration

## What is this skill
This skill provides expertise in interacting with low-level Windows APIs for multimedia routing, specifically pushing custom video frames to virtual cameras and custom audio buffers to virtual microphones.

## Virtual Camera (Softcam/DirectShow)
Sending frames to `softcam` virtual camera via Python Python Binding:
```python
import softcam
import numpy as np
import cv2

# Initialize 720p 30fps virtual camera
cam = softcam.camera(1280, 720, 30)

def send_to_cam(frame_bgr):
    # Softcam API expects BGRA format matrices
    if frame_bgr.shape[2] == 3:
        frame_bgra = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2BGRA)
    else:
        frame_bgra = frame_bgr
        
    cam.send_frame(frame_bgra)
```

## Virtual Audio Driver (WASAPI)
Pushing floating point 32-bit audio buffers strictly to a Virtual Audio Cable/Driver using PyAudio (WASAPI):
```python
import pyaudio

pa = pyaudio.PyAudio()

# 1. Find device by name explicitly
device_index = None
for i in range(pa.get_device_count()):
    info = pa.get_device_info_by_index(i)
    if "Virtual-Audio-Driver" in info['name'] and info['maxOutputChannels'] > 0:
        device_index = i
        break

if device_index is None:
    raise RuntimeError("Virtual audio cable not found!")

# 2. Open stream targeting the exact device index
stream = pa.open(
    format=pyaudio.paFloat32,
    channels=1, # Mono or Stereo
    rate=48000, # 48kHz is standard for voice
    output=True,
    output_device_index=device_index,
    frames_per_buffer=1024
)

# 3. Write binary data (blocking, or can be done in callback)
def write_audio(audio_data_np_array):
    stream.write(audio_data_np_array.tobytes())
```

## Handling UAC/Admin Privileges for Installation
Registering driver DLLs on Windows requires Administrator rights. Use this robust ctypes snippet:
```python
import ctypes
import sys
import subprocess

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def request_admin_and_rerun():
    if not is_admin():
        # Rerun script with admin rights
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
        sys.exit()

def install_directshow_filter(dll_path):
    # Registration requires admin
    subprocess.run(["regsvr32", "/s", dll_path], check=True)
```
