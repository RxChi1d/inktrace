---
title: "Self-Hosting Fish Speech S2-Pro: A Local TTS Service Guide"
slug: "fish-speech-local-tts"
date: 2026-06-30T00:28:34+08:00
tags: ["tts", "fish-speech", "gpu", "self-hosted", "hermes-agent"]
categories: ["engineering"]
description: "Deploy Fish Speech S2-Pro on an RTX 3090 for a fully local TTS service — VRAM tuning, voice pinning, and Hermes Agent integration."
---

Fish Speech S2-Pro is Fish Audio's SOTA open‑source TTS model. This article records how to deploy it on an RTX 3090 (24 GB VRAM) and integrate it with Hermes Agent to create a fully local, low‑latency speech synthesis service.

<!--more-->

## What is Fish Speech S2-Pro

{{< github repo="fishaudio/fish-speech" showThumbnail=true >}}

Fish Speech S2-Pro is Fish Audio’s fourth‑generation TTS model, adopting a self‑developed **Dual‑AR (Dual Autoregressive)** architecture: a 4 B‑parameter Slow AR handles semantic prediction, paired with a 400 M‑parameter Fast AR handling audio details, then synthesized via a VQ‑GAN codec into the final audio file. Training data spans **80+ languages, over 10 million hours**, and uses GRPO reinforcement learning to align with human preferences.

### Key Capabilities

- **Natural language style control**: Insert `[laugh]`, `[breath]`, or descriptive instructions (e.g., “say in a low voice”) directly in the text; the model instantly adjusts rhythm and emotion.
- **Voice cloning**: Provide roughly 10 seconds of reference audio to lock in a specific voice—no extra training needed.
- **Mixed‑language sentence synthesis**: Handles mixed Chinese‑English, Taiwanese, etc., within a single request.
- **Streaming inference**: With SGLang support for continuous batching and paged KV cache.

### Performance (official numbers, NVIDIA H200)

| Metric | Value |
|--------|-------|
| Real‑Time Factor (RTF) | **0.195** (generation speed 5× real‑time) |
| Time‑to‑First‑Audio (TTFA) | **~100 ms** (latency from input to first audio) |
| Max throughput | **3000+ acoustic tokens/s** (under concurrent load RTF still ≤ 0.5) |

### Objective Metrics

| Benchmark | S2‑Pro | Remarks |
|-----------|--------|---------|
| Seed‑TTSEval WER (ZH/EN) | **0.54 % / 0.99 %** | Champion, beats all closed‑source models |
| Audio Turing Test | **0.515** | Closed‑source Seed‑TTS is 0.417; S2‑Pro is 24 % higher |
| EmergentTTS‑Eval Win Rate | **81.88 %** | Prosody 91.61 %, questions 84.41 % are strongest |
| Fish Instruction Benchmark (TAR / Quality) | **93.3 % / 4.51** | TAR = instruction‑following rate; Quality max 5.0 |
| Multi‑language WER (MiniMax 24 lang) | **#1 in 11 languages** | Broadest coverage |
| Multi‑language Speaker Sim (MiniMax 24 lang) | **#1 in 17 languages** | Best voice similarity |

If you just want to try it out, you can first try the web demo at [fish.audio](https://fish.audio) before deciding to self‑host.

---

## Deployment Environment

First, get the source code. The official repo is [fishaudio/fish-speech](https://github.com/fishaudio/fish-speech); just clone it:

```bash
git clone https://github.com/fishaudio/fish-speech.git
cd fish-speech
```

Installation can follow the [Fish Speech official docs](https://speech.fish.audio/install/); this article uses the official UV install method, which one‑clicks the Python environment and CUDA dependencies:

```bash
uv sync --extra cu129   # CUDA 12.9 torch
```

> [!NOTE]
> UV is Astral’s Python package & project manager; see the [official docs](https://docs.astral.sh/uv/).

| Item | Spec |
|------|------|
| GPU | NVIDIA RTX 3090 (24 GB) |
| Model weights | S2‑Pro, ~11 GB |
| Service port | `127.0.0.1:8080` (default localhost) |
| Service address | `http://127.0.0.1:8080` |

## Starting the Service

Start the API server with:

```bash
cd fish-speech
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
  uv run tools/api_server.py --listen 127.0.0.1:8080 --compile
```

- `--compile` triggers `torch.compile`, giving a noticeable speed‑up (see benchmark later).
- `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True` reduces allocator fragmentation, helping avoid OOM from memory churn.

> [!NOTE]
> The default bind address `127.0.0.1` accepts only local connections. If you need access from other devices (e.g., via Tailscale VPN), change to `--listen 0.0.0.0:8080` to expose all interfaces—but **make sure you have additional access controls** (firewall, VPN, etc.), otherwise the service will be exposed to the public internet.

## VRAM Tuning

Out‑of‑the‑box S2‑Pro consumes ~19.8 GB VRAM. If your GPU has less memory or you want to free space for other workloads, you can greatly reduce usage by shrinking `max_seq_len`.

Let’s examine the root cause. Inspecting `fish_speech/models/text2semantic/llama.py` and `checkpoints/s2-pro/config.json` shows that `text_config.max_seq_len` defaults to `32768`, pre‑allocating two buffers:

| Buffer | Formula | @ 32768 | @ 4096 |
|--------|---------|---------|--------|
| KV cache | 2(k+v) × 36 × 8 × max_seq_len × 128 × 2B | 4.8 GB | 0.6 GB |
| causal_mask | max_seq_len² × 1B (bool) | 1.07 GB | 0.016 GB |

Both buffers are **pre‑allocated based on max_seq_len, independent of actual text length**. A value of 32768 is vastly over‑provisioned for TTS—the model weights themselves (BF16 ≈ 10 GB + codec 1.87 GB) are the irreducible floor.

### Solution: Reduce max_seq_len

Edit `checkpoints/s2-pro/config.json` (back up as `config.json.bak`):

```jsonc
// checkpoints/s2-pro/config.json (backup as config.json.bak)
"text_config": {
  "max_seq_len": 4096,   // was 32768
  ...
}
```

### Why 4096?

TTS text is automatically chunked by `chunk_length`; `max_seq_len` is the **per‑chunk upper bound**, not the total request length. A typical chunk is ~1500–1900 tokens, well under 4096, leaving plenty of headroom while saving substantial pre‑allocated memory.

### Benchmark

Fixed text (~277 chars), fixed seed, 5‑run average:

| Setting | Generation time | RTF | VRAM |
|---------|----------------|-----|------|
| `--compile`, seq 32768 (original) | 15.47 s | 1.05× | 19.8 GB |
| no‑compile, seq 32768 | 83.14 s | 0.19× | 19.8 GB |
| **`--compile`, seq 4096** | **8.94 s** | **1.81×** | **14.7 GB** |

Reducing `max_seq_len` from 32768 to 4096 **saves 5.1 GB VRAM and speeds up generation 1.7×**. Shrinking the KV cache reduces overall data throughput, lowering cache miss rate; combined with `torch.compile` acceleration, you get a double win.

---

## Voice Locking

S2‑Pro is a voice‑cloning architecture; without a reference audio, each request uses a random timbre. To get consistent output (e.g., for narration or customer‑service voices), you need to lock a voice.

> [!TIP]
> For general synthesis (stories, audiobooks) you can keep `use_memory_cache: off` to let the voice vary naturally; enable voice locking only when you need a fixed voice.

### How‑to

1. **Generate candidates**: Request synthesis without a reference, try different seeds, pick a favorite (here we use seed 5).
2. **Freeze the reference**: Save the chosen audio as `references/default/voice.wav` and prepare a matching transcript `voice.lab` (contents must match the audio exactly, character‑for‑character).
3. **Pass `reference_id`**: In later requests, add `"reference_id": "default"` to use that voice.

### Specifying via request parameters

The simplest method is to include `reference_id` in each request:

```bash
curl -X POST http://127.0.0.1:8080/v1/tts \
  -H "content-type: application/json" \
  -d '{"text":"要合成的文字","reference_id":"default"}' --output out.wav
```

This requires no code changes; the caller controls the voice directly.

### Setting a global default (code change)

If you want requests *without* an explicit `reference_id` to automatically use a fixed voice, edit `fish_speech/utils/schema.py`:

```python
# fish_speech/utils/schema.py

class ServeTTSRequest(BaseModel):
    reference_id: str | None = "default"             # was None
    use_memory_cache: Literal["on", "off"] = "on"    # was "off"
```

After this change, requests that only supply `text` will automatically apply the `default` voice (with `use_memory_cache: "on"` enabling cache reuse for similar requests). Callers can still override by providing their own `reference_id`.

> [!WARNING]
> This approach edits fish‑speech source code; a `git pull` or update will overwrite it, so you’ll need to re‑apply the patch.

### Local changes checklist

After pulling or updating fish‑speech, re‑apply these three changes:

1. `checkpoints/s2-pro/config.json`: `max_seq_len` 32768 → 4096 (keep a backup as `config.json.bak`).
2. `fish_speech/utils/schema.py`: set `ServeTTSRequest.reference_id` default to `"default"` and `use_memory_cache` default to `"on"`.
3. `references/default/`: place the chosen voice WAV and its `.lab` transcript (e.g., from seed 5).

> [!TIP]
> Consider wrapping these three steps in a patch script so you can re‑apply them with one command after each update.

---

## Output Format Limitations

libsndfile 1.2.2 **does not support Opus**; requesting `format: "opus"` returns a 500 error. Available formats:

| Format | Notes |
|--------|-------|
| `wav` | Default, works everywhere |
| `mp3` | Native output, moderate size |
| `ogg‑opus` | Requires local ffmpeg conversion |

If you need Opus for Telegram voice bubbles, have the server emit WAV, then run a local `ffmpeg` conversion to Ogg/Opus.

> [!WARNING]
> Asking the server directly for `format: "opus"` will produce a 500 error; request `wav` and convert locally with `ffmpeg`.

---

## Auto‑Start on Boot

To have the service survive reboots, a simple, robust approach is to use `tmux` plus an `@reboot` cron entry. Create a `start.sh` script that waits for the GPU driver to be ready, then launches the server, and make it idempotent (safe to run multiple times).

```bash
# crontab -e
@reboot /path/to/fish-speech/start.sh
```

---

## Hermes Agent Integration

The final step is to let [Hermes Agent](https://hermes-agent.nousresearch.com/) use this local Fish Speech service as its TTS provider—no plugin or custom code needed.

We’ll use the **custom command provider**: add a Fish‑Speech provider under the `tts` section in `~/.hermes/config.yaml`.

### One‑click Hermes Agent configuration

The simplest method: paste the following prompt into Hermes Agent; it will generate the wrapper script, write the config via `hermes config set`, and switch the provider:

```
I want to use my local Fish Speech service as the TTS provider, details:
- API address: http://127.0.0.1:8080/v1/tts
- Supported formats: wav, mp3 (no Opus; needs local ffmpeg conversion)
- Required output format: ogg (for Telegram voice bubbles)
- Need a wrapper script to handle “take wav → ffmpeg → ogg/opus”
- Example command: python3 ~/.hermes/scripts/fish_speech_tts.py --input {input_path} --output {output_path} --format {format}

Please:
1. Create ~/.hermes/scripts/fish_speech_tts.py wrapper script
2. Use `hermes config set` to write the fish‑speech provider section in config.yaml
3. Set tts.provider to fish-speech
```

Hermes Agent’s `hermes config set` supports dot‑notation (e.g., `tts.providers.fish-speech.command`) and will auto‑write `config.yaml`—no manual YAML editing needed.

### Manual configuration

If you prefer to do it yourself:

1. **Create the wrapper script** `~/.hermes/scripts/fish_speech_tts.py` (it fetches WAV from the server and uses ffmpeg to output the requested format).

2. Configure the provider via `hermes config set`:

```bash
hermes config set tts.providers.fish-speech.type command
hermes config set tts.providers.fish-speech.command "python3 ~/.hermes/scripts/fish_speech_tts.py --input {input_path} --output {output_path} --format {format}"
hermes config set tts.providers.fish-speech.output_format ogg
hermes config set tts.providers.fish-speech.voice_compatible true
hermes config set tts.providers.fish-speech.timeout 240
hermes config set tts.providers.fish-speech.max_text_length 5000
hermes config set tts.provider fish-speech
```

3. (Alternative) Edit `~/.hermes/config.yaml` directly and add:

```yaml
# ~/.hermes/config.yaml (tts section)
tts:
  provider: fish-speech              # enable fish‑speech
  providers:
    fish-speech:
      type: command
      command: "python3 ~/.hermes/scripts/fish_speech_tts.py --input {input_path} --output {output_path} --format {format}"
      output_format: ogg
      voice_compatible: true
      timeout: 240
      max_text_length: 5000
```

### Manual test

For a quick sanity check, hit the endpoint directly:

```bash
curl -X POST http://127.0.0.1:8080/v1/tts \
  -H "content-type: application/json" \
  -d '{"text":"要合成的文字"}' --output out.wav
```

Supplying only `text` uses the server’s defaults (default voice, WAV format). Add `format: "mp3"` or `reference_id` as needed.

### Switching providers

```bash
# Enable Fish Speech
hermes config set tts.provider fish-speech

# Switch back to another TTS (e.g., Gemini)
hermes config set tts.provider gemini
```

The change takes effect immediately—no session restart needed.

---

## Summary

Fish Speech S2‑Pro runs comfortably on an RTX 3090 after VRAM trimming, delivering a high‑quality, fully local TTS service with low latency. VRAM tuning (cutting `max_seq_len` from 32768 to 4096) saves ~5 GB and nearly doubles speed when combined with `torch.compile`. Voice locking via `reference_id` (or a global default) gives consistent output for narrations or agents. Integrating with Hermes Agent is straightforward via the custom command provider, letting you swap TTS backends on the fly.

Next steps could involve wrapping the helper script into Hermes’ official toolchain, or fine‑tuning `use_memory_cache` for batch workloads.

---

## References

- [Fish Speech official documentation](https://speech.fish.audio/install/)
- [fishaudio/fish-speech GitHub repository](https://github.com/fishaudio/fish-speech)
- [Hermes Agent TTS documentation](https://hermes-agent.nousresearch.com/docs/user-guide/features/tts)
