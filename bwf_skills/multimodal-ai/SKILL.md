---
name: multimodal-ai
description: Build applications with vision, audio, video, and image generation AI. Covers GPT-4V/Gemini Vision, Whisper/TTS, DALL-E/Imagen/Stable Diffusion, video generation (Veo/Sora), CLIP embeddings, and multimodal pipelines.
---

# Multimodal AI Expert

Expert guidance for building applications that combine text, images, audio, and video AI.

## When to Use

- Image understanding / analysis (OCR, description, classification)
- Image generation (DALL-E, Imagen, Stable Diffusion)
- Audio processing (speech-to-text, text-to-speech, voice)
- Video understanding and generation
- Multimodal search (text → image, image → text)

---

## 1. Vision (Image Understanding)

### GPT-4 Vision
```python
from openai import OpenAI
import base64

client = OpenAI()

def analyze_image(image_path: str, prompt: str) -> str:
    with open(image_path, "rb") as f:
        image_b64 = base64.b64encode(f.read()).decode()

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {
                    "url": f"data:image/jpeg;base64,{image_b64}",
                    "detail": "high"  # low, auto, high
                }},
            ],
        }],
        max_tokens=1000,
    )
    return response.choices[0].message.content

# Usage
description = analyze_image("photo.jpg", "Describe this image in detail")
ocr_text = analyze_image("document.png", "Extract all text from this image")
analysis = analyze_image("chart.png", "Analyze this chart and summarize findings")
```

### Gemini Vision
```python
import google.generativeai as genai
from PIL import Image

genai.configure(api_key="YOUR_KEY")
model = genai.GenerativeModel("gemini-2.0-flash")

img = Image.open("photo.jpg")
response = model.generate_content([
    "What objects are in this image? List them with confidence scores.",
    img,
])
print(response.text)

# Multiple images
response = model.generate_content([
    "Compare these two images and describe the differences:",
    Image.open("before.jpg"),
    Image.open("after.jpg"),
])
```

### Vision Use Cases
| Task | Prompt Strategy | Model |
|------|----------------|-------|
| **OCR** | "Extract all text exactly as written" | GPT-4o, Gemini |
| **Description** | "Describe in detail for accessibility" | GPT-4o |
| **Classification** | "Classify into: [categories]. Respond JSON" | GPT-4o-mini |
| **Object Detection** | "List objects with bounding box coordinates" | Gemini |
| **Chart Analysis** | "Extract data from this chart as JSON" | GPT-4o |
| **UI Review** | "Review this UI screenshot for UX issues" | GPT-4o |
| **Document Parse** | "Extract fields: name, date, amount" | GPT-4o |

## 2. Image Generation

### DALL-E 3 (OpenAI)
```python
response = client.images.generate(
    model="dall-e-3",
    prompt="A serene Japanese garden with cherry blossoms at sunset, watercolor style",
    size="1024x1024",    # 1024x1024, 1024x1792, 1792x1024
    quality="hd",         # standard, hd
    n=1,
    style="vivid",        # vivid, natural
)

image_url = response.data[0].url
revised_prompt = response.data[0].revised_prompt  # DALL-E rewrites your prompt
```

### Stable Diffusion (Local / Replicate)
```python
import replicate

output = replicate.run(
    "stability-ai/sdxl:latest",
    input={
        "prompt": "A cyberpunk city at night, neon lights, rain, photorealistic",
        "negative_prompt": "blurry, low quality, distorted",
        "width": 1024,
        "height": 1024,
        "num_inference_steps": 30,
        "guidance_scale": 7.5,
        "scheduler": "DPMSolverMultistep",
    }
)
```

### Image Editing
```python
# OpenAI Image Edit (inpainting)
response = client.images.edit(
    model="dall-e-2",
    image=open("original.png", "rb"),
    mask=open("mask.png", "rb"),  # Transparent area = edit region
    prompt="A red sports car parked here",
    size="1024x1024",
)

# Variation
response = client.images.create_variation(
    model="dall-e-2",
    image=open("original.png", "rb"),
    n=3,
    size="1024x1024",
)
```

### Prompt Engineering for Images
```
Structure: [Subject] + [Style] + [Lighting] + [Composition] + [Details]

Examples:
- "A majestic owl perched on an ancient book, digital art, dramatic
   side lighting, close-up portrait, intricate feather details"
- "Minimalist logo for a tech startup called 'Nova', geometric
   shapes, flat design, blue and white color palette, SVG style"

Negative prompts (Stable Diffusion):
- "blurry, low quality, distorted, deformed, watermark, text"
```

## 3. Audio

### Speech-to-Text (Whisper)
```python
# OpenAI Whisper API
audio_file = open("interview.mp3", "rb")
transcript = client.audio.transcriptions.create(
    model="whisper-1",
    file=audio_file,
    response_format="verbose_json",  # Includes timestamps
    timestamp_granularities=["word", "segment"],
    language="en",
)

# With timestamps
for segment in transcript.segments:
    print(f"[{segment.start:.1f}s] {segment.text}")

# Translation (any language → English)
translation = client.audio.translations.create(
    model="whisper-1",
    file=open("vietnamese_speech.mp3", "rb"),
)
```

### Local Whisper
```python
import whisper

model = whisper.load_model("large-v3")
result = model.transcribe("audio.mp3", language="vi", task="transcribe")

for segment in result["segments"]:
    print(f"[{segment['start']:.1f}-{segment['end']:.1f}] {segment['text']}")
```

### Text-to-Speech
```python
# OpenAI TTS
response = client.audio.speech.create(
    model="tts-1-hd",       # tts-1 (fast) or tts-1-hd (quality)
    voice="nova",            # alloy, echo, fable, onyx, nova, shimmer
    input="Hello! Welcome to our application.",
    speed=1.0,               # 0.25 to 4.0
    response_format="mp3",   # mp3, opus, aac, flac, wav, pcm
)
response.stream_to_file("output.mp3")

# Google Cloud TTS
from google.cloud import texttospeech

tts = texttospeech.TextToSpeechClient()
response = tts.synthesize_speech(
    input=texttospeech.SynthesisInput(text="Xin chào!"),
    voice=texttospeech.VoiceSelectionParams(
        language_code="vi-VN",
        name="vi-VN-Neural2-A",
    ),
    audio_config=texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3,
        speaking_rate=1.0,
        pitch=0.0,
    ),
)
with open("output.mp3", "wb") as f:
    f.write(response.audio_content)
```

### ElevenLabs (Voice Cloning)
```python
from elevenlabs import ElevenLabs

el = ElevenLabs(api_key="YOUR_KEY")

# Clone voice from samples
voice = el.clone(
    name="My Voice",
    files=["sample1.mp3", "sample2.mp3", "sample3.mp3"],
)

# Generate with cloned voice
audio = el.generate(
    text="This sounds just like me!",
    voice=voice,
    model="eleven_multilingual_v2",
)
```

## 4. Video

### Video Understanding (Gemini)
```python
import google.generativeai as genai

model = genai.GenerativeModel("gemini-2.0-flash")

video_file = genai.upload_file("demo.mp4")

# Wait for processing
import time
while video_file.state.name == "PROCESSING":
    time.sleep(5)
    video_file = genai.get_file(video_file.name)

response = model.generate_content([
    "Summarize this video. Include key events with timestamps.",
    video_file,
])
print(response.text)
```

### Video Generation
```
Available APIs (2025-2026):

Google Veo 2:
- Via Vertex AI
- 1080p, up to 8 seconds
- Best quality/consistency

OpenAI Sora:
- Via API (limited access)
- Up to 60 seconds
- Strong prompt adherence

Runway Gen-3:
- Via API
- Image-to-video, text-to-video
- Good motion control

Prompt tips for video generation:
- Describe motion explicitly: "camera slowly pans left"
- Specify duration: "a 4-second clip of..."
- Include style: "cinematic, 24fps, shallow depth of field"
- Describe start/end states: "begins with X, transitions to Y"
```

## 5. Multimodal Embeddings (CLIP)

```python
from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import torch

model = CLIPModel.from_pretrained("openai/clip-vit-large-patch14")
processor = CLIPProcessor.from_pretrained("openai/clip-vit-large-patch14")

# Text → Image Search
def search_images(query: str, images: list[Image.Image]) -> list[float]:
    inputs = processor(text=[query], images=images, return_tensors="pt", padding=True)
    outputs = model(**inputs)

    # Cosine similarity between text and each image
    text_embeds = outputs.text_embeds / outputs.text_embeds.norm(dim=-1, keepdim=True)
    image_embeds = outputs.image_embeds / outputs.image_embeds.norm(dim=-1, keepdim=True)
    similarities = (text_embeds @ image_embeds.T).squeeze().tolist()
    return similarities

# Image → Text Search
def find_caption(image: Image.Image, captions: list[str]) -> str:
    inputs = processor(text=captions, images=[image], return_tensors="pt", padding=True)
    outputs = model(**inputs)
    idx = outputs.logits_per_image.argmax().item()
    return captions[idx]
```

### Use Cases
| Task | Approach |
|------|----------|
| **Visual search** | Embed images + queries with CLIP, cosine similarity |
| **Image tagging** | Compare image embedding against tag embeddings |
| **Content moderation** | Compare against "inappropriate content" embeddings |
| **Product search** | "Red dress under $50" → find matching product images |
| **Duplicate detection** | High cosine similarity = potential duplicate |

## 6. Multimodal Pipelines

### Document Understanding Pipeline
```python
async def process_document(file_path: str) -> dict:
    # Step 1: Extract text and images from PDF
    pages = extract_pdf_pages(file_path)

    results = []
    for page in pages:
        # Step 2: OCR any images/charts
        if page.has_images:
            image_analysis = await analyze_image(
                page.image, "Extract all text and describe charts/figures"
            )
        # Step 3: Combine text + image analysis
        combined = f"{page.text}\n{image_analysis}"
        results.append(combined)

    # Step 4: Generate summary
    full_text = "\n\n".join(results)
    summary = await llm.invoke(f"Summarize this document:\n{full_text}")

    return {"text": full_text, "summary": summary, "pages": len(pages)}
```

### Audio → Text → Summary → Speech
```python
async def audio_summary_pipeline(audio_path: str) -> str:
    # 1. Transcribe audio
    transcript = client.audio.transcriptions.create(
        model="whisper-1", file=open(audio_path, "rb")
    )
    # 2. Summarize text
    summary = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user",
                   "content": f"Summarize:\n{transcript.text}"}],
    )
    # 3. Convert summary to speech
    speech = client.audio.speech.create(
        model="tts-1-hd", voice="nova",
        input=summary.choices[0].message.content,
    )
    speech.stream_to_file("summary.mp3")
    return summary.choices[0].message.content
```

## 7. Best Practices

- **Resolution matters**: Higher detail = better accuracy but more tokens
- **Image optimization**: Resize before sending (max 2048px per side)
- **Audio chunking**: Split long audio into <25MB segments for Whisper
- **Prompt specificity**: "Extract the price from this receipt" > "What's in this image?"
- **Fallback chains**: Gemini → GPT-4o → local model for reliability
- **Cost awareness**: Vision API costs scale with image detail level
- **Caching**: Cache analysis results for identical/similar images
- **Edge inference**: Use ONNX Runtime or TF Lite for on-device inference
