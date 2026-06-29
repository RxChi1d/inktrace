---
title: "使用 Fish Speech S2-Pro 架設本地 TTS 服務"
slug: "fish-speech-local-tts"
date: 2026-06-30T00:28:34+08:00
tags: ["tts", "fish-speech", "gpu", "self-hosted", "hermes-agent"]
categories: ["engineering"]
description: "在 RTX 3090 上以 Fish Speech S2-Pro 架設本地 TTS 服務，含顯存調校、固定聲音與 Hermes Agent 接入的完整教學。"
---

Fish Speech S2-Pro 是 Fish Audio 的 SOTA 開源 TTS 模型。本文記錄如何將它部署到 RTX 3090（24 GB VRAM）上，並整合進 Hermes Agent，打造一個完全 local、低延遲的語音合成服務。

<!--more-->

## Fish Speech S2-Pro 是什麼

{{< github repo="fishaudio/fish-speech" showThumbnail=true >}}

Fish Speech S2-Pro 是 Fish Audio 第四代 TTS 模型，採用自行研發的 **Dual-AR（Dual Autoregressive）架構**：由一個 4B 參數的 Slow AR 負責語意預測、搭配一個 400M 參數的 Fast AR 負責音訊細節，再透過 VQ-GAN codec 合成最終音檔。訓練資料橫跨 **80+ 語言、1000 萬小時以上**，並使用 GRPO 強化學習對齊人類偏好。

### 重點能力

- **自然語言風格控制**：在文字中插入 `[laugh]`、`[breath]` 或描述性指令（如「用低沉語氣說」），模型會即時調整韻律、情感
- **Voice cloning**：提供約 10 秒參考音檔即可鎖定特定聲音，不需要額外訓練
- **多語言混語句合成**：中英夾雜、台語等也能在單次請求中處理
- **Streaming 推理**：搭配 SGLang 支援 continuous batching、paged KV cache

### 效能（官方數據，NVIDIA H200）

| 指標 | 數值 |
|------|------|
| Real-Time Factor (RTF) | **0.195**（生成速度比即時快 5 倍） |
| Time-to-First-Audio (TTFA) | **~100 ms**（收音到出聲的延遲） |
| 最大吞吐 | **3000+ acoustic tokens/s**（併發负载下 RTF 仍可壓在 0.5 以下） |

### 客觀指標

| 基準 | S2-Pro | 备注 |
|------|--------|------|
| Seed-TTS Eval WER（中／英） | **0.54% / 0.99%** | 冠軍，擊敗所有閉源模型 |
| Audio Turing Test | **0.515** | 閉源 Seed-TTS 為 0.417，S2-Pro 高 24% |
| EmergentTTS-Eval Win Rate | **81.88%** | 韻律 91.61%、問句 84.41% 為最強項 |
| Fish Instruction Benchmark（TAR / Quality） | **93.3% / 4.51** | TAR = 指令遵循率，Quality 滿分 5.0 |
| 多語 WER（MiniMax 24 語） | **11 語第一** | 涵蓋最廣 |
| 多語 Speaker Sim（MiniMax 24 語） | **17 語第一** | 聲音相似度最佳 |

如果你只想試效果，可以先上 [fish.audio](https://fish.audio) 用網頁版體驗，再決定要不要自己架。

---

## 部署環境

開始之前，先取得源碼。官方倉庫在 [fishaudio/fish-speech](https://github.com/fishaudio/fish-speech)，clone 下來即可：

```bash
git clone https://github.com/fishaudio/fish-speech.git
cd fish-speech
```

安裝方式可以參考 [Fish Speech 官方文件](https://speech.fish.audio/install/)，本文選擇官方提供的 UV 安裝方式，一鍵搞定 Python 環境與 CUDA 依賴：

```bash
uv sync --extra cu129   # CUDA 12.9 torch
```

> UV 是 Astral 推出的 Python 套件與專案管理器，詳細見 [官方文件](https://docs.astral.sh/uv/)。

| 項目 | 規格 |
|------|------|
| GPU | NVIDIA RTX 3090（24 GB） |
| 模型權重 | S2-Pro，約 11 GB |
| 服務端口 | `127.0.0.1:8080`（預設 localhost） |
| 服務位置 | `http://127.0.0.1:8080` |

## 啟動服務

用以下指令啟動 API server：

```bash
cd fish-speech
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
  uv run tools/api_server.py --listen 127.0.0.1:8080 --compile
```

`--compile` 觸發 `torch.compile`，生成速度會有感提升（後面 benchmark 會看到）。`PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True` 可降低 allocator 碎片，避免記憶體晃動造成 OOM。

> [!NOTE]
> 預設監聽 `127.0.0.1` 只接受本機連線。如果需要從其他裝置存取（例如透過 Tailscale 等 VPN），可以改成 `--listen 0.0.0.0:8080` 開放所有介面，但**請務必確認你有額外的存取控制**（防火牆、VPN 等），否則服務會直接暴露在公網上。

## 顯存調校

預設配置下 S2-Pro 約吃掉 19.8 GB VRAM，如果你的顯卡顯存較少、或想騰出空間給其他用途，可以透過縮小 `max_seq_len` 大幅降低佔用。

來看根因。讀 `fish_speech/models/text2semantic/llama.py` 與 `checkpoints/s2-pro/config.json` 後發現，`text_config.max_seq_len` 預設為 `32768`，撐起以下兩塊預分配 buffer：

| Buffer | 公式 | @ 32768 | @ 4096 |
|--------|------|---------|--------|
| KV cache | 2(k+v) × 36 × 8 × max_seq_len × 128 × 2B | 4.8 GB | 0.6 GB |
| causal_mask | max_seq_len² × 1B (bool) | 1.07 GB | 0.016 GB |

兩者皆**依 max_seq_len 預先配置，與實際文字長度無關**。32768 對 TTS 嚴重過大——權重本身（bf16 約 10 GB + codec 1.87 GB）才是無法壓縮的底線。

### 解法：縮 max_seq_len

```jsonc
// checkpoints/s2-pro/config.json（備份為 config.json.bak）
"text_config": {
  "max_seq_len": 4096,   // 原 32768
  ...
}
```

**為什麼是 4096**：TTS 文字會依 `chunk_length` 自動分塊，`max_seq_len` 是**每個 chunk 的上限**，而非整段請求長度。單 chunk 典型約 1500–1900 token，遠低於 4096，留有足夠餘裕，卻省掉大量預佔空間。

### Benchmark

固定文字約 277 字元、固定 seed、5 次平均：

| 設定 | 生成時間 | RTF | VRAM |
|------|---------|-----|------|
| `--compile`, seq 32768（原始） | 15.47s | 1.05× | 19.8 GB |
| no-compile, seq 32768 | 83.14s | 0.19× | 19.8 GB |
| **`--compile`, seq 4096** | **8.94s** | **1.81×** | **14.7 GB** |

縮 `max_seq_len` 從 32768 到 4096：**省下 5.1 GB，且速度快 1.7 倍**。KV cache 縮小後整體資料吞吐量大幅下降，cache miss 減少；加上 `torch.compile` 加速，一舉兩得。

## 固定聲音

S2-Pro 是 voice-cloning 架構，未提供參考音檔時，每次請求都會用到隨機音色。如果想讓所有產出聽起來一致（例如影片旁白或客服語音），固定聲音是必要的步驟。

> [!TIP]
> 一般合成（story、audiobook）可以維持 `use_memory_cache: off`，讓音色自然切換；固定聲音情境才需要開啟。

### 做法

1. **生成候選**：不提供 reference，用不同 seed 試聽，挑一個最喜歡的（本例選 seed 5）。
2. **凍結參考音**：將選定的音訊存成 `references/default/voice.wav`，並準備對應逐字稿 `voice.lab`（內容必須與音檔一字不差）。
3. **帶上 reference_id**：後續請求加 `"reference_id": "default"` 即可。

### 透過 request 參數指定

最標準的方式是在每次請求中帶上 `reference_id`：

```bash
curl -X POST http://127.0.0.1:8080/v1/tts \
  -H "content-type: application/json" \
  -d '{"text":"要合成的文字","reference_id":"default"}' --output out.wav
```

這種方式不修改程式碼，呼叫方自行控制，是最乾淨的做法。

### 設為全域預設（改 code）

如果想讓不指定 `reference_id` 的請求自動使用固定聲音，可以改 `fish_speech/utils/schema.py` 的預設值：

```python
# fish_speech/utils/schema.py

class ServeTTSRequest(BaseModel):
    reference_id: str | None = "default"             # 原 None
    use_memory_cache: Literal["on", "off"] = "on"    # 原 "off"
```

之後請求只給 `text`，服務端會自動套用 `default` 聲音（`use_memory_cache: "on"` 讓相似請求複用快取加速）。呼叫方若想用其他聲音，仍可在請求中帶自己的 `reference_id` 覆蓋。

> [!WARNING]
> 這個方法是直接修改 fish-speech 的原始碼，git pull 或更新後會被覆蓋，需要重新套用。

## 本地改動清單

Git pull 或更新 fish-speech 後，下列改動必須重新套用：

1. `checkpoints/s2-pro/config.json`：`max_seq_len` 32768 → 4096（備份為 `config.json.bak`）
2. `fish_speech/utils/schema.py`：`ServeTTSRequest` 的 `reference_id` 預設填 `"default"`、`use_memory_cache` 預設 `"on"`
3. `references/default/`：放入固定聲音 wav + lab（例如 seed 5 的選取結果）

> [!TIP]
> 建議把這三步寫進一個 patch script，每次 update 後一鍵重套，避免漏改。

## 輸出格式限制

libsndfile 1.2.2 **不支援 opus**，使用 `"format": "opus"` 會收到 500 錯誤。可用格式：

| 格式 | 說明 |
|------|------|
| `wav` | 預設，全適用 |
| `mp3` | 直出，體積適中 |
| `ogg-opus` | 需經本地 ffmpeg 轉換 |

如果用於 Telegram 語音泡泡（需要 ogg-opus），可以先在 server 端拿 wav，再用本地 ffmpeg 轉成 ogg/opus。

> [!WARNING]
> Server 端直接請求 `format: "opus"` 會 500，請用 `format: "wav"` + 本地 ffmpeg 轉換。

## 開機自啟

確保服務在 reboot 後自動恢復，建議用 tmux + `@reboot` cron。`start.sh` 需要自己建立，內容大致是等 GPU driver 就緒以後再啟動 server，並且設計成 idempotent（重複執行不會開兩份）：

```bash
# crontab -e
@reboot /path/to/fish-speech/start.sh
```

## Hermes Agent 接入

最後一步是讓 [Hermes Agent](https://hermes-agent.nousresearch.com/) 的 TTS 機制能使用這個 Fish Speech 服務——不需進 plugin、不必寫自定義程式碼。

我們透過 **custom command provider** 接入，在 `~/.hermes/config.yaml` 的 `tts` 區段加入 fish-speech provider。

### 一鍵讓 Hermes Agent 自動配置

最簡單的方式：把以下 prompt 直接丟給 Hermes Agent，它會幫你生成 wrapper script、透過 `hermes config set` 寫好 config、並完成切換：

```
我想用本機 Fish Speech 服務當作 TTS provider，資訊如下：
- API 位址：http://127.0.0.1:8080/v1/tts
- 支援格式：wav、mp3（無 opus，需本地 ffmpeg 轉檔）
- 產出格式需求：ogg（給 Telegram 語音泡泡用）
- 需要 wrapper script 處理「拿 wav → ffmpeg 轉 ogg/opus」
- 參考指令：python3 ~/.hermes/scripts/fish_speech_tts.py --input {input_path} --output {output_path} --format {format}

請幫我：
1. 在 ~/.hermes/scripts/ 建立 fish_speech_tts.py wrapper script
2. 用 hermes config set 指令在 config.yaml 的 tts 區段加入 fish-speech provider 設定
3. 將 tts.provider 設為 fish-speech
```

Hermes Agent 的 `hermes config set` 支援 dot notation（如 `tts.providers.fish-speech.command`），會自動寫入 `config.yaml`，不需要手動編輯 YAML。

### 手動設定

如果想自己來，先建立 wrapper script `~/.hermes/scripts/fish_speech_tts.py`（負責從 server 拿 wav → ffmpeg 轉 ogg/opus），然後用 `hermes config set` 逐項設定：

```bash
hermes config set tts.providers.fish-speech.type command
hermes config set tts.providers.fish-speech.command "python3 ~/.hermes/scripts/fish_speech_tts.py --input {input_path} --output {output_path} --format {format}"
hermes config set tts.providers.fish-speech.output_format ogg
hermes config set tts.providers.fish-speech.voice_compatible true
hermes config set tts.providers.fish-speech.timeout 240
hermes config set tts.providers.fish-speech.max_text_length 5000
hermes config set tts.provider fish-speech
```

也可以跑 `hermes config edit` 直接編輯 `config.yaml`，加入以下區段：

```yaml
# ~/.hermes/config.yaml（tts 區段）
tts:
  provider: fish-speech              # 啟用 fish-speech
  providers:
    fish-speech:
      type: command
      command: "python3 ~/.hermes/scripts/fish_speech_tts.py --input {input_path} --output {output_path} --format {format}"
      output_format: ogg
      voice_compatible: true
      timeout: 240
      max_text_length: 5000
```

### 手動測試

如果只想快速測試，用最簡請求即可：

```bash
curl -X POST http://127.0.0.1:8080/v1/tts \
  -H "content-type: application/json" \
  -d '{"text":"要合成的文字"}' --output out.wav
```

只給 `text`，其餘走服務端預設（default 聲音、wav 格式）。需要時再指定 `format: "mp3"` 或 `reference_id`。

### 切換 Provider

```bash
# 啟用 fish-speech
hermes config set tts.provider fish-speech

# 切回其他 TTS（如 gemini）
hermes config set tts.provider gemini
```

切換後**立即生效**，無需重啟 session。

## 小結

Fish Speech S2-Pro 在 RTX 3090 上完全能跑，關調校後是優秀的 local TTS 方案——對比雲端 TTS API，延遲更低、完全離線。顯存調校是最關鍵的一環，省下 5.1 GB 對多服務共卡而言是質的差異。固定聲音與切換 provider 的機制則讓整體體驗 production-ready。

下一步可以考慮把 wrapper script 正式整合進 Hermes 的工具鏈，或進一步微調 `use_memory_cache` 在批次情境下的表現。

## 參考資料

- [Fish Speech 官方文件](https://speech.fish.audio/install/)
- [fishaudio/fish-speech GitHub Repository](https://github.com/fishaudio/fish-speech)
- [Hermes Agent TTS 文件](https://hermes-agent.nousresearch.com/docs/user-guide/features/tts)
