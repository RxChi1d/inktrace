---
title: "Porting MTP to Ornith-1.0-35B: From GGUF Surgery to Hermes Agent"
date: 2026-07-06T21:15:09+08:00
lastmod: 2026-07-11T02:06:20+08:00
slug: ornith-1-0-35b-mtp-deployment-notes
tags: ["llm", "ornith", "qwen", "mtp", "gguf", "llama-cpp", "cuda", "self-hosted", "hermes-agent"]
categories: ["ai-technical"]
description: "Deploy Ornith-1.0-35B locally with llama.cpp and wire it into Hermes Agent, then graft on an MTP head for a further inference speedup — with ablation data to back every choice."
---

This guide walks through deploying Ornith-1.0-35B locally with llama.cpp, wiring it into Hermes Agent, and finally grafting on an MTP head to push inference speed even higher.

<!--more-->

## 1. What Is Ornith-1.0-35B

{{< huggingface model="deepreinforce-ai/Ornith-1.0-35B-GGUF" >}}

Ornith-1.0-35B is a research model from DeepReinforce AI, continued-trained on top of Qwen3.5-35B-A3B with their in-house reinforcement-learning framework; it currently ships in four sizes — 9B / 31B / 35B / 397B. What sets it apart is that during training it doesn't just learn to solve problems — it learns to **generate its own scaffold to drive the solution**, optimizing the scaffold and the final answer together. That gives Ornith-1.0-35B a clear edge over Qwen3.5-35B-A3B on the kind of long, multi-turn, tool-calling workflows found in Terminal-Bench and SWE-bench:

- **Long-horizon agentic coding**: officially positioned for long, multi-turn tool-calling workflows like Terminal-Bench and SWE-bench
- **262K context window**: thanks to the Gated Delta Net hybrid linear-attention architecture, most layers keep a fixed state size that doesn't grow linearly with context
- **MIT license**: free to self-host and fine-tune

Here are the official benchmark numbers, for reference:

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>Benchmark</th><th>Ornith-1.0-35B</th><th>Qwen3.6-35B</th></tr>
</thead>
<tbody>
<tr><td>Terminal-Bench 2.1</td><td class="cell-win">64.2</td><td class="cell-dim">52.5</td></tr>
<tr><td>SWE-bench Verified</td><td class="cell-win">75.6</td><td class="cell-dim">73.4</td></tr>
<tr><td>SWE-bench Pro</td><td class="cell-win">50.4</td><td class="cell-dim">49.5</td></tr>
<tr><td>NL2Repo</td><td class="cell-win">34.6</td><td class="cell-dim">29.4</td></tr>
</tbody>
</table>
</div>

> This guide uses the Q4_K_M quant; the official GGUF page is [deepreinforce-ai/Ornith-1.0-35B-GGUF](https://huggingface.co/deepreinforce-ai/Ornith-1.0-35B-GGUF).

---

## 2. Deploying Ornith-1.0-35B

Now that we have a rough picture of the model, let's get it running locally.

### 2.1 Choosing an Inference Engine

There's no shortage of options for running an LLM locally. A few common ones:

| Option | Best for |
|---|---|
| **llama.cpp** | Chasing inference speed; fine-grained control over GPU resources |
| **Ollama** | Convenience — one command and you're running; llama.cpp under the hood |
| **vLLM** | Plenty of VRAM; running the unquantized original model |

Ollama is convenient (`ollama run ...` and you're off) and it's llama.cpp underneath, but the extra layer of wrapping usually makes inference a touch slower than calling llama.cpp directly. vLLM, on the other hand, is Linux-only and doesn't support GGUF, so it's hungrier for VRAM — running a 35B model on a consumer card gets tight.

Weighing it all up, this guide goes with **llama.cpp**.

> llama.cpp is an LLM inference engine written in C/C++. It supports the GGUF quantization format and can run fairly large models on consumer hardware — even pure CPU. See the [official GitHub](https://github.com/ggml-org/llama.cpp).

### 2.2 Installing llama.cpp

- macOS

  For macOS users, Homebrew is the easy route:

  ```bash
  brew install llama.cpp
  ```

  You can also grab the latest prebuilt binaries from llama.cpp's [GitHub](https://github.com/ggml-org/llama.cpp) or [website](https://llama-cpp.com/download/).

- Windows

  Windows users can likewise download the official prebuilt binaries, or use WSL2 to install the Linux build.

- Linux

  Linux is the odd one out. Because CUDA driver installs and dependencies vary so much across distros, llama.cpp doesn't ship a prebuilt CUDA binary for Linux. Install via Homebrew and you'll get the Vulkan build — it runs, but it's slower than the CUDA build:

  ```bash
  # Vulkan build
  brew install llama.cpp
  ```
  
  If you want the best inference speed, build the CUDA version yourself (there's no official Linux CUDA prebuilt):

  ```bash
  # CUDA build (compile it yourself)

  # Install the build dependencies first (keep Vulkan around as a fallback)
  sudo apt-get install -y build-essential cmake git libvulkan-dev glslc spirv-headers

  # Clone llama.cpp and build the CUDA version
  git clone https://github.com/ggml-org/llama.cpp.git llama.cpp-cuda
  cd llama.cpp-cuda
  cmake -B build -DGGML_CUDA=ON -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
  cmake --build build --config Release -j $(nproc)
  ```

  > [!NOTE]
  > A self-built binary won't print `load_backend: loaded ...` on `llama-server --version` the way the Homebrew build does — a self-built binary links the backend in statically at link time. That's expected and doesn't mean CUDA was left out; just load a model to confirm.

### 2.3 Starting the Service

llama.cpp ships with `llama-server`, which can pull a model straight from Hugging Face and start serving — no need to download the GGUF by hand:

```bash
llama-server -hf deepreinforce-ai/Ornith-1.0-35B-GGUF --port 8000 -c 262144
```

Of course, if you want explicit control over every flag, here's the full command:

```bash
llama.cpp-cuda/build/bin/llama-server \
  --hf-repo deepreinforce-ai/Ornith-1.0-35B-GGUF \
  --hf-file ornith-1.0-35b-Q4_K_M.gguf \
  --host 127.0.0.1 --port 8002 \
  -c 65536 \
  --split-mode none --main-gpu 0 \
  --flash-attn on \
  --jinja
```

A few of the flags:

| Flag | Purpose |
|---|---|
| `-c 65536` | Context length; meets Hermes Agent's 64K floor |
| `--flash-attn on` | No measurable hit to speed or quality — just turn it on |
| `--jinja` | Enables the Jinja template so the chat template works correctly |

> [!NOTE]
> Every command and test below was decided on a single RTX 3090 (24 GB VRAM), with "force everything onto the GPU, maximize inference speed" as the guiding priority. `-c 65536` just happens to clear Hermes Agent's 64K floor while sitting near the largest context this card can still run fully on the GPU (see [§5.3](#53-context-size-ablation)) — it's neither the only nor the "best" value. If you have more VRAM to spare, or need a bigger context window, tune it to your needs; just note that once you exceed VRAM the system falls back to auto-offloading and decode speed drops noticeably. There's no one-size-fits-all answer to that trade-off.

> [!WARNING]
> `--host` defaults to `127.0.0.1` (local access only). If you need other machines to connect, you can switch it to `0.0.0.0` — but pair that with a firewall, VPN, or other access control, or the service will be exposed straight to the public internet.

Once it's up, a quick curl confirms it:

```bash
curl http://127.0.0.1:8002/v1/models
```

### 2.4 The Silent Downgrade: Don't Let Auto-Config Slow You Down

Once the service is running, don't rush ahead — scroll back through the startup log and you might spot these lines:

```
W tensor overrides to CPU are used with mmap enabled - consider using --no-mmap for better performance
W sched_reserve: layer 0 is assigned to device CPU but the fused Gated Delta Net tensor is assigned to device CUDA0
W sched_reserve: fused Gated Delta Net (chunked) not supported, set to disabled
```

This is an easy-to-miss behavior of llama.cpp's automatic memory allocation: **even if your command includes no CPU-offload flags at all, if it decides VRAM is tight it may still choose to keep a layer computing on the CPU.**

Usually that doesn't change the output — that layer just runs a bit slower. But if the layer happens to use a fused kernel like Gated Delta Net, which is currently only implemented for CUDA, the impact isn't just "this one layer got slower" — **the model's fused kernel gets disabled entirely**, falling back to an unoptimized compute path, and decode speed takes a measurable hit (see [the ablation data in §5.3](#53-context-size-ablation)).

The fix is simple — use `-ngl` to put every layer on the GPU explicitly, together with `--no-mmap`:

```bash
-ngl 999 --no-mmap
```

The number in `-ngl 999` just needs to exceed the actual layer count; llama.cpp clamps it, so the net effect is forcing all layers onto the GPU. Add these two flags back into the full command from 2.3 and restart the service:

```bash
llama.cpp-cuda/build/bin/llama-server \
  --hf-repo deepreinforce-ai/Ornith-1.0-35B-GGUF \
  --hf-file ornith-1.0-35b-Q4_K_M.gguf \
  --host 127.0.0.1 --port 8002 \
  -c 65536 \
  --split-mode none --main-gpu 0 \
  --flash-attn on \
  -ngl 999 --no-mmap \
  --jinja
```

Check the startup log once more and those warnings should be gone — a sign the Gated Delta Net fused kernel is now running properly on the GPU.

---

## 3. Wiring In Hermes Agent

With the model running, the next step is wiring it into Hermes Agent so the agent framework can call the local model directly.

[Hermes Agent](https://hermes-agent.nousresearch.com/) is a local-first agent framework from Nous Research, with tool calling, long-term memory, and more. One thing to note: Hermes Agent only enables tool calling when the model's context is at least 64K — which is where that `-c 65536` came from.

### 3.1 Configuring a Custom Provider

Hermes Agent doesn't take direct edits to `config.yaml`; you configure it through `hermes config set` (which supports dot notation):

```bash
hermes config set custom_providers.ornith-local.base_url "http://127.0.0.1:8002/v1"
hermes config set custom_providers.ornith-local.models."deepreinforce-ai/Ornith-1.0-35B-GGUF".context_length 65536
```

> [!TIP]
> Set `context_length` explicitly rather than relying on auto-detection. Hermes's own context-parsing logic has a known issue with non-standard error-message formats — hardcoding the value lets its built-in compaction (which kicks in once you're past half the budget) step in proactively, instead of waiting until it actually hits the wall.

Once that's set, switch to the new provider and you're good to go. At this point Ornith-1.0-35B is reliably serving inference to Hermes Agent.

> If you'd rather automate the steps above, just hand Hermes Agent this prompt and it'll run the `hermes config set` commands for you:
>
> ```
> I want to add a local llama.cpp service as a custom provider. Details:
> - API endpoint: http://127.0.0.1:8002/v1
> - Model name: deepreinforce-ai/Ornith-1.0-35B-GGUF
> - context_length: 65536
>
> Please use `hermes config set` to add this provider under custom_providers, and confirm that context_length was written correctly.
> ```

---

## 4. Going Further: Faster Inference with MTP

If you're still not happy with the inference speed, consider MTP.

> [!NOTE]
> MTP is an optional, advanced step — it means modifying the GGUF file and using third-party ported weights. If you'd rather stick with the official original, or you're wary of third-party ports, skipping this chapter won't affect anything you've set up so far.

### 4.1 What Is MTP

MTP (Multi-Token Prediction) lets the model predict several tokens at once — every hit saves a round of computation, making it essentially free speedup. Ornith doesn't yet ship an official build with an MTP head, so we have to port one from the community.

The MTP head used here comes from skinnyctax's cross-model port:

{{< github repo="skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF" showThumbnail=true >}}

{{< huggingface model="skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF" >}}

### 4.2 llama.cpp Version Requirements

MTP speculative decoding needs llama.cpp **b9180 or later** (PR #22673, merged into mainline on 2026-05-16). On an older build, `--spec-type` won't offer the `draft-mtp` option.

Check your current version:

```bash
llama-server --version
```

For a self-built binary, go back to the source dir, pull, and rebuild:

```bash
cd llama.cpp-cuda
git pull
cmake --build build --config Release -j $(nproc)
```

> [!NOTE]
> If the MTP head is already merged into the same GGUF file (as it is with the port used here), you only need `-m` pointing at that file plus `--spec-type draft-mtp` — no separate `-md` (that flag is only for when the MTP head is a standalone file).

### 4.3 GGUF Graft Surgery

skinnyctax provides a donor file containing only the MTP head (20 tensors, named `blk.40.*`); our job is to splice it onto the official Ornith GGUF.

The graft logic:

1. Parse the GGUF headers of the target (the Ornith model itself, 733 tensors) and the donor (MTP head-only, 20 tensors)
2. Append the donor's tensors to the end of the target (733 → 753)
3. Change two metadata fields: `block_count: 40 → 41`, and add `nextn_predict_layers=1`
4. Recompute tensor offsets and write out the merged file

The script and donor file are both in skinnyctax's Hugging Face repo:

```bash
hf download skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF \
  ornith-1.0-35b-Q4_K_M-MTP-donor-heads.gguf gguf_mtp_graft.py --local-dir .

python3 gguf_mtp_graft.py "$BASE_GGUF" \
  ornith-1.0-35b-Q4_K_M-MTP-donor-heads.gguf \
  ornith-1.0-35b-Q4_K_M-MTP-v3.gguf
```

#### A GGUF header bug worth watching for

The graft script has a subtle issue in how it handles the `general.architecture` KV pair: it decodes the value into a Python string, then re-encodes it on the way back out:

```python
if key == "general.architecture":
    arch = rstr(fp)
    kv_pairs.append((key, 8, arch.encode("utf-8")))
```

`arch.encode("utf-8")` only re-encodes the string content itself, but **the GGUF spec requires every string value to be preceded by an 8-byte length prefix** — and this step drops it. `general.architecture` is usually one of the very first KV pairs in a GGUF file, so those missing 8 bytes shift every subsequent KV pair out of position; when llama.cpp reads it, it reads back an absurdly large number and refuses to load:

```
E read: string length 8029132205683210097 exceeds maximum 1073741824
E gguf_init_from_reader: failed to read key-value pairs
```

The fix is to preserve the full raw bytes instead of decoding and re-encoding:

```python
if key == "general.architecture":
    arch = rstr(fp)
    val_end = fp.tell()
    fp.seek(val_start)
    val_raw = fp.read(val_end - val_start)
    fp.seek(val_end)
    kv_pairs.append((key, 8, val_raw))
```

> [!WARNING]
> What makes this bug nasty is that everything looks fine functionally: the KV-pair count matches, the tensor count matches, the metadata content matches — the misalignment only shows at the binary level. If you ever write or modify a GGUF editor script, any branch that special-cases a string KV pair should preserve the raw bytes rather than going down the decode → re-encode path.

After the fix, a small test (`-c 4096`) put draft acceptance at 0.87–0.96 — the cross-model MTP head is nicely compatible with the Ornith model.

### 4.4 Launching the MTP Build

Compared to the base setup, it's just two extra flags — `--spec-type draft-mtp` and `--spec-draft-n-max 2`:

```bash
llama.cpp-cuda/build/bin/llama-server \
  --model /path/to/ornith-1.0-35b-Q4_K_M-MTP-v3.gguf \
  --alias deepreinforce-ai/Ornith-1.0-35B-GGUF \
  --host 127.0.0.1 --port 8002 \
  -c 65536 \
  --split-mode none --main-gpu 0 \
  --spec-type draft-mtp --spec-draft-n-max 2 \
  --flash-attn on \
  -ngl 999 --no-mmap \
  --jinja
```

`--spec-draft-n-max 2` is the cap on how many tokens MTP drafts per step — the next section's experiments explain why 2 rather than 1 or 3.

---

## 5. Supporting Experiments

Every test below was run single-GPU, single-request, reading `eval time` and tokens per second straight from `llama-server`'s own output — not timed through a client app.

> [!NOTE]
> If a tool like Chatbox or Open WebUI reports lower tok/s, it's usually because those tools fold in network round-trips and queueing — that's not the same measurement basis as the raw decode speed here.

### 5.1 MTP Graft vs. Stock GGUF

Using the official original GGUF as the control. The base weights on both sides are identical (the port takes the official file as its target); the only difference is whether there's an MTP head. Test conditions: `-c 65536`, forced full-GPU.

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th></th><th>Stock (no MTP)</th><th>MTP graft (n-max 2)</th></tr>
</thead>
<tbody>
<tr><td><strong>decode tok/s</strong></td><td>172.948</td><td><strong>226.124</strong></td></tr>
<tr><td><strong>Std dev</strong></td><td>0.114</td><td>4.79</td></tr>
<tr><td><strong>draft acceptance</strong></td><td>—</td><td>0.805</td></tr>
</tbody>
</table>
</div>

<!-- prettier-ignore-start -->
{{< chart >}}
type: 'bar',
data: {
  labels: ['decode tok/s'],
  datasets: [
    {
      label: 'Stock (no MTP)',
      data: [172.948],
      backgroundColor: 'rgb(148, 163, 184)',
      borderColor: 'rgb(148, 163, 184)'
    },
    {
      label: 'MTP graft (n-max 2)',
      data: [226.124],
      backgroundColor: 'rgb(34, 197, 94)',
      borderColor: 'rgb(34, 197, 94)'
    }
  ]
},
options: {
  plugins: {
    legend: {
      display: true,
      position: 'bottom',
      labels: {
        generateLabels: (chart) => chart.data.datasets.map((ds, i) => ({
          text: ds.label,
          fillStyle: ds.backgroundColor,
          strokeStyle: ds.borderColor,
          fontColor: window.chartTextColor(),
          lineWidth: 1,
          hidden: false,
          datasetIndex: i
        }))
      }
    },
    title: { display: true, text: 'Decode throughput comparison' },
    subtitle: { display: true, text: 'MTP graft: ~30.7% faster' },
    tooltip: { callbacks: { label: (ctx) => ctx.dataset.label + ': ' + ctx.parsed.y + ' tok/s' } }
  },
  scales: {
    y: { beginAtZero: true, title: { display: true, text: 'tok/s', color: () => window.chartTextColor() }, ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } },
    x: { ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } }
  }
}
{{< /chart >}}
<!-- prettier-ignore-end -->

> [!SUCCESS]
> The MTP graft delivered roughly a **30.7%** decode-throughput gain.

### 5.2 Long-Context Quality Check

A full `-c 262144` exceeds what this card can run fully on the GPU, so this test ran with auto-offloading and the fused kernel disabled. Method: needle-in-a-haystack — bury a secret phrase in filler text, then ask the model to recall it at the very end.

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>Metric</th><th>Value</th></tr>
</thead>
<tbody>
<tr><td>Actual prompt tokens</td><td>114,051</td></tr>
<tr><td>prefill tok/s</td><td>1,085</td></tr>
<tr><td>decode tok/s</td><td>95.20</td></tr>
<tr><td>draft acceptance</td><td>0.924</td></tr>
</tbody>
</table>
</div>

> [!SUCCESS]
> The phrase was recalled correctly, and acceptance held up. Even in the degraded state with the fused kernel disabled, long-context quality stayed stable.

### 5.3 Context Size Ablation

Fixing `--spec-draft-n-max 1` and `-ngl 999 --no-mmap`, sweeping 5 values of `-c`, 5 repeats each.

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>-c size</th><th>GPU layer placement</th><th>decode tok/s</th><th>acceptance</th><th>VRAM</th></tr>
</thead>
<tbody>
<tr><td>16,384</td><td>Forced full-GPU</td><td>219.012</td><td>0.906</td><td>21.61 GB</td></tr>
<tr class="row-adopted"><td>65,536 (adopted)</td><td>Forced full-GPU</td><td><strong>218.948</strong></td><td>0.906</td><td>22.73 GB</td></tr>
<tr class="row-fail"><td>131,072</td><td>VRAM-limited → auto-offload</td><td>149.828</td><td>0.909</td><td>22.16 GB</td></tr>
<tr class="row-fail"><td>200,000</td><td>VRAM-limited → auto-offload</td><td>133.416</td><td>0.925</td><td>22.07 GB</td></tr>
<tr class="row-fail"><td>262,144</td><td>VRAM-limited → auto-offload</td><td>118.244</td><td>0.898</td><td>22.00 GB</td></tr>
</tbody>
</table>
</div>

<!-- prettier-ignore-start -->
{{< chart >}}
type: 'line',
data: {
  labels: ['16,384', ['65,536', '(adopted)'], '131,072', '200,000', '262,144'],
  datasets: [
    {
      label: 'Forced full-GPU',
      data: [219.012, 218.948, null, null, null],
      borderColor: 'rgb(34, 197, 94)',
      backgroundColor: 'rgb(34, 197, 94)',
      pointBackgroundColor: 'rgb(34, 197, 94)',
      pointRadius: [5, 8, 0, 0, 0],
      borderWidth: 3,
      tension: 0
    },
    {
      label: 'VRAM-limited, fell back to auto-offload',
      data: [null, null, 149.828, 133.416, 118.244],
      borderColor: 'rgb(249, 115, 22)',
      backgroundColor: 'rgb(249, 115, 22)',
      pointBackgroundColor: 'rgb(249, 115, 22)',
      pointRadius: 5,
      borderWidth: 3,
      borderDash: [6, 4],
      tension: 0.15
    }
  ]
},
options: {
  spanGaps: false,
  plugins: {
    legend: { display: true, position: 'bottom' },
    title: { display: true, text: 'How context size affects decode speed' },
    tooltip: { callbacks: { label: (ctx) => ctx.parsed.y + ' tok/s' } }
  },
  scales: {
    y: { beginAtZero: true, title: { display: true, text: 'tok/s', color: () => window.chartTextColor() }, ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } },
    x: { title: { display: true, text: '-c (context length)', color: () => window.chartTextColor() }, ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } }
  }
}
{{< /chart >}}
<!-- prettier-ignore-end -->

> [!IMPORTANT]
> The speed curve is really two different mechanisms stacked together. As long as you can stay forced-full-GPU (the ceiling lands somewhere between 65K and 131K), decode speed is essentially flat; only once context exceeds capacity — VRAM runs short, the system falls back to auto-offloading, and the fused kernel gets disabled — does speed fall off a cliff. 16K and 65K are nearly identical (219 → 218), but the moment you cross 131K it nosedives to 149.

### 5.4 spec-draft-n-max Ablation

Fixing `-c 65536` and `-ngl 999 --no-mmap`, sweeping n-max 1–4, 5 repeats each.

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>n-max</th><th>decode tok/s</th><th>Std dev</th><th>acceptance</th><th>VRAM</th><th>Status</th></tr>
</thead>
<tbody>
<tr><td>1</td><td>218.948</td><td>2.294</td><td>0.906</td><td>22.73 GB</td><td>Forced full-GPU</td></tr>
<tr class="row-adopted"><td>2 (adopted)</td><td><strong>226.124</strong></td><td>4.793</td><td>0.805</td><td>22.98 GB</td><td>Forced full-GPU</td></tr>
<tr><td>3</td><td>229.924</td><td>7.864</td><td>0.760</td><td>23.26 GB</td><td>Forced full-GPU (razor-thin headroom)</td></tr>
<tr class="row-fail"><td>4</td><td>151.932</td><td>3.846</td><td>0.675</td><td>21.47 GB</td><td>OOM mid-generation → auto-offload</td></tr>
</tbody>
</table>
</div>

> [!WARNING]
> n=3 has the highest mean (229.9 tok/s), but its std dev (7.86) is wide enough to clearly overlap n=2's range; with under 750 MB of VRAM headroom, it sits close to the n=4 danger zone of "starts fine, crashes mid-generation." Keep **n=2** as the production setting.

### 5.5 Backend / Flash Attention Comparison

Same ported GGUF, `-c 16384`, n-max 1, all forced `-ngl 999 --no-mmap`, a fixed prompt averaged over 5 runs.

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>Variant</th><th>decode tok/s</th><th>Std dev</th><th>acceptance</th><th>VRAM</th></tr>
</thead>
<tbody>
<tr class="row-adopted"><td>CUDA + FA on</td><td><strong>219.012</strong></td><td>1.371</td><td>0.906</td><td>21.61 GB</td></tr>
<tr><td>CUDA + FA off</td><td>217.412</td><td>1.640</td><td>0.898</td><td>21.61 GB</td></tr>
<tr><td>Vulkan</td><td>179.032</td><td>6.639</td><td>0.896</td><td>21.33 GB</td></tr>
</tbody>
</table>
</div>

The FA on/off gap falls within the std dev — no significant effect. CUDA is about 22% faster than Vulkan, thanks to native Tensor Core and cuBLAS optimizations.

> [!TIP]
> If your system has both an integrated GPU and a discrete card, Vulkan and CUDA device indices don't necessarily line up — confirm the device mapping before switching backends, so you don't accidentally land on the slower device.

### 5.6 KV Cache Quantization

Fixing `-c 65536` and n-max 2, all forced full-GPU, to test how quantizing the KV cache affects speed.

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>Variant</th><th>tok/s (mean ± std)</th><th>acceptance</th><th>VRAM</th></tr>
</thead>
<tbody>
<tr><td>No quantization (baseline)</td><td>226.124 ± 4.79</td><td>0.805 ± 0.032</td><td>22.98 GB</td></tr>
<tr><td><code>-ctk/-ctv q8_0</code></td><td>225.796 ± 1.35</td><td>0.827 ± 0.009</td><td>22.48 GB</td></tr>
<tr><td><code>-ctk/-ctv q4_0</code></td><td>227.224 ± 4.54</td><td>0.836 ± 0.028</td><td>22.17 GB</td></tr>
</tbody>
</table>
</div>

All three sit within noise — at this context length, the decode bottleneck is reading and computing the weight matrices, not KV-cache bandwidth.

Speed didn't improve meaningfully, but `q4_0` saved about 0.81 GB of VRAM — possibly enough to squeeze a 131K context into forced-full-GPU mode too, which is worth testing later.

---

## 6. Wiring the MTP Build into Hermes Agent

The MTP build serves on the same API endpoint and alias as the base build, so Hermes Agent needs no extra configuration. If you already did the setup in Chapter 3, just restart the service — Hermes still sees `deepreinforce-ai/Ornith-1.0-35B-GGUF`, but decode is now about 30% faster underneath.

The config commands are exactly the same as the base build:

```bash
hermes config set custom_providers.ornith-local.base_url "http://127.0.0.1:8002/v1"
hermes config set custom_providers.ornith-local.models."deepreinforce-ai/Ornith-1.0-35B-GGUF".context_length 65536
```

> Hindsight is the long-term memory system that pairs with Hermes Agent; it extracts and recalls structured memories from conversations, and it calls the local model through this same provider too.

---

## References

- [Ornith-1.0-35B official model page](https://huggingface.co/deepreinforce-ai/Ornith-1.0-35B-GGUF)
- [Ornith-1.0-35B MTP port](https://huggingface.co/skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF)
- [llama.cpp GitHub](https://github.com/ggml-org/llama.cpp)
- [llama.cpp build docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)
- [llama.cpp Speculative Decoding](https://github.com/ggml-org/llama.cpp/blob/master/docs/speculative.md)
- [GGUF format spec](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md)
- [Hermes Agent docs](https://hermes-agent.nousresearch.com/)

## Appendix: Gotchas Cheat Sheet

| Pitfall | Fix |
|---|---|
| **Dropped GGUF header length prefix** | When writing your own editor script, any branch that special-cases a string KV pair must preserve the raw bytes (including the 8-byte length prefix) — don't decode then re-encode. |
| **No CUDA from the package manager** | Homebrew's bottle model structurally can't ship CUDA; on Linux you have to build `-DGGML_CUDA=ON` yourself. |
| **Multi-GPU CUDA probe OOM** | `--main-gpu` only takes effect after device enumeration; use `CUDA_VISIBLE_DEVICES=N` to mask the busy card at the driver level. |
| **Vulkan device index ≠ CUDA** | The two orderings aren't guaranteed to match; confirm the device mapping before switching backends. |
| **Auto-config silently downgrades** | Under VRAM pressure, auto-config may offload a layer and disable the fused kernel; override it explicitly with `-ngl 999 --no-mmap`. |
| **Full-GPU still has a hard ceiling** | `-ngl 999` will still OOM once you exceed real VRAM capacity. |
| **OOM mid-generation** | A config that starts fine but leaves under ~1 GB of headroom can still crash while generating. |
| **High-variance "best" values** | When the top mean has a std dev wide enough to overlap the runner-up, that's not enough to justify switching your current setting. |
| **`brew upgrade` skips self-built binaries** | A self-compiled binary is standalone; update it by running `git pull` in the source dir and rebuilding, not through the package manager. |
