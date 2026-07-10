---
title: "幫 Ornith-1.0-35B 移植 MTP：從 GGUF 手術到 Hermes Agent 接入"
date: 2026-07-06T21:15:09+08:00
lastmod: 2026-07-11T02:06:20+08:00
slug: ornith-1-0-35b-mtp-deployment-notes
tags: ["llm", "ornith", "qwen", "mtp", "gguf", "llama-cpp", "cuda", "self-hosted", "hermes-agent"]
categories: ["ai-technical"]
description: "介紹如何用 llama.cpp 在本地端部署 Ornith-1.0-35B 並接入 Hermes Agent，再透過移植 MTP head 進一步提升推理速度，附消融實驗數據供實際應用參考。"
---

本文帶你用 llama.cpp 在本地端部署 Ornith-1.0-35B、接入 Hermes Agent，最後再透過移植 MTP head 進一步提升推理速度。

<!--more-->

## 1. Ornith-1.0-35B 是什麼

{{< huggingface model="deepreinforce-ai/Ornith-1.0-35B-GGUF" >}}

Ornith-1.0-35B 是 DeepReinforce AI 釋出的研究模型，以 Qwen3.5-35B-A3B 為基底、用自研的強化學習框架續訓而成，目前涵蓋 9B / 31B / 35B / 397B 四種規模。與其他模型不同的是，它在訓練過程中不只學會解題，還學會**自己生成驅動解題的鷹架（scaffold）**，同時優化鷹架與最終解答，因此相較於 Qwen3.5-35B-A3B，Ornith-1.0-35B 在 Terminal-Bench、SWE-bench 這類需要多輪工具呼叫的長流程任務上有明顯優勢：

- **長程 agentic coding**：官方定位在 Terminal-Bench、SWE-bench 這類需要多輪工具呼叫的長流程任務
- **262K context window**：得益於 Gated Delta Net 混合線性注意力架構，多數層的狀態大小固定、不隨 context 線性增長
- **MIT 授權**：可自由本地部署與微調

以下是官方公佈的效能數據，作為參考：

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>基準</th><th>Ornith-1.0-35B</th><th>Qwen3.6-35B</th></tr>
</thead>
<tbody>
<tr><td>Terminal-Bench 2.1</td><td class="cell-win">64.2</td><td class="cell-dim">52.5</td></tr>
<tr><td>SWE-bench Verified</td><td class="cell-win">75.6</td><td class="cell-dim">73.4</td></tr>
<tr><td>SWE-bench Pro</td><td class="cell-win">50.4</td><td class="cell-dim">49.5</td></tr>
<tr><td>NL2Repo</td><td class="cell-win">34.6</td><td class="cell-dim">29.4</td></tr>
</tbody>
</table>
</div>

> 本文使用的量化版本為 Q4_K_M，官方 GGUF 模型頁面見 [deepreinforce-ai/Ornith-1.0-35B-GGUF](https://huggingface.co/deepreinforce-ai/Ornith-1.0-35B-GGUF)。

---

## 2. 部署 Ornith-1.0-35B

在對 Ornith-1.0-35B 模型有了初步理解後，我們接下來將了解如何在本地端把模型跑起來。

### 2.1 選擇推理引擎

本地部署 LLM 的選項不少，幾個常見的選擇：

| 方案 | 適合情境 |
|---|---|
| **llama.cpp** | 追求推理速度、需要細粒度控制 GPU 資源 |
| **Ollama** | 追求方便、一行指令就能啟動，底層也是 llama.cpp |
| **vLLM** | VRAM 充裕、想跑未量化原始模型 |

Ollama 雖然方便（`ollama run ...` 一行就能動），並且底層同樣是 llama.cpp，但其中間多了一層封裝，推理速度通常會略低於直接使用 llama.cpp；另一方面，vLLM 僅能在 Linux 系統中使用，且不支援 GGUF 格式，因此對顯存的需求較高，要在消費級顯卡上跑 35B 規模的模型會比較吃力。

綜合考量下來，本文選擇 **llama.cpp** 作為推理引擎。

> llama.cpp 是一個用 C/C++ 寫成的 LLM 推理引擎，支援 GGUF 量化格式，能在消費級硬體甚至純 CPU 上跑起相對大型的模型。詳見 [官方 GitHub](https://github.com/ggml-org/llama.cpp)。

### 2.2 安裝 llama.cpp

- MacOS

  對於使用 MacOS 的用戶，Homebrew 提供了方便的安裝方式：

  ```bash
  brew install llama.cpp
  ```

  也可以至 llama.cpp 的[官方 GitHub](https://github.com/ggml-org/llama.cpp) 或[官網](https://llama-cpp.com/download/)直接下載最新的編譯版本。

- Windows

  Windows 用戶同樣可以直接下載官方提供的預編譯版本，或是使用 WSL2 來安裝 Linux 版本。

- Linux

  在 Linux 上，比較特殊一點。由於 CUDA 驅動在 Linux 上的安裝方式與依賴多樣，llama.cpp 官方目前沒有提供 Linux 的 CUDA 預編譯檔。如果直接通過 Homebrew 安裝，會得到 Vulkan 版本，雖然能跑，但推理速度會比 CUDA 版慢一些：

  ```bash
  # 安裝 Vulkan 版
  brew install llama.cpp
  ```
  
  如果想要最好的推理速度，建議自行編譯 CUDA 版本（官方目前沒有提供 Linux 的 CUDA 預編譯檔）:

  ```bash
  # CUDA 版（需要自行編譯）

  # 編譯前需要先裝好必要套件（保留 Vulkan 當備援）
  sudo apt-get install -y build-essential cmake git libvulkan-dev glslc spirv-headers

  # Clone llama.cpp 並編譯 CUDA 版本
  git clone https://github.com/ggml-org/llama.cpp.git llama.cpp-cuda
  cd llama.cpp-cuda
  cmake -B build -DGGML_CUDA=ON -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
  cmake --build build --config Release -j $(nproc)
  ```

  > [!NOTE]
  > 自編版本執行 `llama-server --version` 不會像 Homebrew 版那樣印出 `load_backend: loaded ...`——自編版在連結階段就把 backend 靜態連結進執行檔，不代表 CUDA 沒編進去，實際載入模型觀察即可確認。

### 2.3 啟動服務

llama.cpp 內建了 `llama-server`，可以直接從 Hugging Face 下載模型並啟動服務，不需要手動下載 GGUF 檔案：

```bash
llama-server -hf deepreinforce-ai/Ornith-1.0-35B-GGUF --port 8000 -c 262144
```

當然，如果你想明確控制每個參數，也可以用完整的指令：

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

幾個參數的說明：

| 參數 | 用途 |
|---|---|
| `-c 65536` | context 長度，滿足 Hermes Agent 要求的 64K 下限 |
| `--flash-attn on` | 實測對速度與品質無負面影響，直接開啟 |
| `--jinja` | 啟用 Jinja 模板，讓 chat template 正確運作 |

> [!NOTE]
> 本文以下所有指令與測試，都是在單卡 RTX 3090（24GB VRAM）、且以「強制全 GPU、最大化推理速度」為優先前提下決定的。`-c 65536` 只是剛好同時滿足 Hermes Agent 的 64K 下限、又落在這張卡能強制全 GPU 運行的容量上限附近（見 [5.3 節](#53-context-size-消融)）——不是唯一或最佳的值。如果你的顯存更充裕、或需要更大的 context window，可以依自己的需求調整，只是超出 VRAM 容量後系統會退回自動分層，推理速度會明顯下降，這之間如何取捨沒有標準答案。

> [!WARNING]
> `--host` 預設設為 `127.0.0.1`（僅本機可存取）。如果你需要讓其他裝置連線，可以改成 `0.0.0.0`，但請務必搭配防火牆或 VPN 等額外的存取控制，否則服務會直接暴露在公網上。

啟動後可以用 curl 簡單驗證：

```bash
curl http://127.0.0.1:8002/v1/models
```

### 2.4 隱性降級：別讓自動配置拖慢你

服務跑起來後，先別急著往下走——回頭看一下剛才的啟動 log，可能會看到這幾行：

```
W tensor overrides to CPU are used with mmap enabled - consider using --no-mmap for better performance
W sched_reserve: layer 0 is assigned to device CPU but the fused Gated Delta Net tensor is assigned to device CUDA0
W sched_reserve: fused Gated Delta Net (chunked) not supported, set to disabled
```

這是 llama.cpp 自動記憶體配置機制的一個容易被忽略的行為：**就算指令裡完全沒有加任何要求 CPU 卸載的參數，只要它判斷 VRAM 偏緊，仍可能自行決定把某一層留在 CPU 上運算。**

通常這不影響輸出結果，只是那一層算得慢一點。但如果那一層剛好用到 Gated Delta Net 這種目前只有 CUDA 有實作的融合運算核心，影響就不只是「這一層變慢」——**整個模型的融合核心會被直接停用**，退回沒有優化的計算路徑，實測 decode 速度會有明顯落差（見 [5.3 節消融數據](#53-context-size-消融)）。

解法很簡單——用 `-ngl` 明確指定全部層數放上 GPU，搭配 `--no-mmap`：

```bash
-ngl 999 --no-mmap
```

`-ngl 999` 的數字只要大於實際層數即可，llama.cpp 會自動截斷，效果等於強制全部層數放上 GPU。把這兩個參數補回 2.3 的完整指令中，重新啟動服務：

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

再檢查一次啟動 log，前述的警告訊息就會消失，代表 Gated Delta Net 的融合核心已正常運作在 GPU 上。

---

## 3. 接入 Hermes Agent

模型跑起來之後，接下來把它接入 Hermes Agent，讓 agent 框架能直接調用本地模型。

[Hermes Agent](https://hermes-agent.nousresearch.com/) 是 Nous Research 推出的本地優先 agent 框架，支援工具呼叫、長期記憶等功能。需要注意的是，Hermes Agent 要求模型的 context 至少要有 64K 才會啟用工具呼叫——這也是前面 `-c 65536` 這個值的由來。

### 3.1 設定自訂 provider

Hermes Agent 不接受直接修改 `config.yaml`，需透過 `hermes config set` 指令來設定（支援 dot notation）：

```bash
hermes config set custom_providers.ornith-local.base_url "http://127.0.0.1:8002/v1"
hermes config set custom_providers.ornith-local.models."deepreinforce-ai/Ornith-1.0-35B-GGUF".context_length 65536
```

> [!TIP]
> 建議明確寫死 `context_length`，不要依賴自動偵測。Hermes 自身的 context 解析邏輯對非標準錯誤訊息格式有已知的 parsing 問題——寫死可以讓它的內建壓縮機制（用量過半即開始壓縮）提早主動介入，而不是等真的撞牆才處理。

設定完成後，可以切換到新的 provider 開始使用。到這裡，Ornith-1.0-35B 已經可以穩定地為 Hermes Agent 提供推理服務。

> 如果你想把上述設定步驟自動化，可以直接把以下 prompt 丟給 Hermes Agent，它會幫你執行 `hermes config set` 完成所有設定：
>
> ```
> 我想接一個本地 llama.cpp 服務當作自訂 provider，資訊如下：
> - API 位址：http://127.0.0.1:8002/v1
> - 模型名稱：deepreinforce-ai/Ornith-1.0-35B-GGUF
> - context_length：65536
>
> 請幫我用 hermes config set 指令在 custom_providers 區段加入這個 provider，並確認 context_length 有正確寫入。
> ```

---

## 4. 進階：透過 MTP 加速推理

如果你對目前的推理速度還不滿意，可以考慮 MTP。

> [!NOTE]
> MTP 是一個可選的進階功能，需要對 GGUF 檔案進行修改、使用第三方移植的權重。如果你偏好使用官方原版、或對第三方移植有疑慮，跳過本章節也不會影響前面已完成的所有設定。

### 4.1 MTP 是什麼

MTP（Multi-Token Prediction）讓模型一次預測多個 token——預測命中就省下一輪運算，本質上是近乎免費的加速。Ornith 官方目前還沒有推出自帶 MTP head 的版本，所以需要從社群移植。

本文使用的 MTP head 來源是 skinnyctax 跨模型移植的版本：

{{< github repo="skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF" showThumbnail=true >}}

{{< huggingface model="skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF" >}}

### 4.2 llama.cpp 版本需求

MTP speculative decoding 需要 llama.cpp **b9180 以上**的版本（PR #22673，2026-05-16 合併進 mainline）。如果你的版本較舊，`--spec-type` 不會有 `draft-mtp` 這個選項。

確認目前版本：

```bash
llama-server --version
```

自編版本需要回到原始碼目錄重新拉取並編譯：

```bash
cd llama.cpp-cuda
git pull
cmake --build build --config Release -j $(nproc)
```

> [!NOTE]
> MTP head 已經合併進同一個 GGUF 檔案的話（本文的移植版即是如此），只需要 `-m` 指向該檔案並加上 `--spec-type draft-mtp`，不需要額外的 `-md` 參數（`-md` 只用在 MTP head 是獨立檔案的情況）。

### 4.3 GGUF 移植手術

skinnyctax 提供了只有 MTP head 的 donor 檔案（20 個 tensor，命名為 `blk.40.*`），我們的工作是把它接到官方 Ornith GGUF 上：

移植的邏輯是：

1. 解析 target（Ornith 本體，733 個 tensor）與 donor（MTP head-only，20 個 tensor）的 GGUF header
2. 把 donor 的 tensor 接到 target 尾端（733 → 753）
3. 修改兩個 metadata：`block_count: 40 → 41`、新增 `nextn_predict_layers=1`
4. 重新計算 tensor offset 後寫出合併檔案

腳本與 donor 檔案都在 skinnyctax 的 Hugging Face repo 中：

```bash
hf download skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF \
  ornith-1.0-35b-Q4_K_M-MTP-donor-heads.gguf gguf_mtp_graft.py --local-dir .

python3 gguf_mtp_graft.py "$BASE_GGUF" \
  ornith-1.0-35b-Q4_K_M-MTP-donor-heads.gguf \
  ornith-1.0-35b-Q4_K_M-MTP-v3.gguf
```

#### 一個值得留意的 GGUF header bug

移植腳本在處理 `general.architecture` 這個 KV pair 時有一個細節問題：它先把值解碼成 Python 字串，再重新編碼寫回去：

```python
if key == "general.architecture":
    arch = rstr(fp)
    kv_pairs.append((key, 8, arch.encode("utf-8")))
```

`arch.encode("utf-8")` 只重新編碼了字串內容本身，但 **GGUF 規格要求每個字串值前面都要有一個 8-byte 的長度前綴**——這一步把前綴漏掉了。`general.architecture` 通常是 GGUF 檔案最前面的 KV pair 之一，少了這 8 bytes，後續所有 KV pair 的位置會整體錯位，llama.cpp 讀到時會讀出一個異常巨大的數字並拒絕載入：

```
E read: string length 8029132205683210097 exceeds maximum 1073741824
E gguf_init_from_reader: failed to read key-value pairs
```

修正方式是保留完整的原始 bytes，不要解碼再重新編碼：

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
> 這個 bug 的麻煩之處在於從功能角度看一切正常：KV pair 數量對、tensor 數量對、metadata 內容也對，只有二進位層級才看得出錯位。如果你往後自己寫或修改 GGUF 編輯腳本，凡是特殊處理某個字串 KV pair 的分支，建議一律保留原始 bytes，不要走 decode → re-encode 這條路。

修正後，小規模測試（`-c 4096`）的 draft acceptance 落在 0.87–0.96，跨模型移植的 MTP head 與 Ornith 本體相容性良好。

### 4.4 啟動 MTP 版服務

比起基礎版本，只多了 `--spec-type draft-mtp` 和 `--spec-draft-n-max 2` 兩個參數：

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

其中 `--spec-draft-n-max 2` 是 MTP 每次預測的 token 數量上限——下一節的實驗會說明為什麼設 2 而不是 1 或 3。

---

## 5. 補充：實驗佐證

以下測試全部在單一 GPU、單一請求的條件下進行，數據直接讀取 `llama-server` 輸出的 `eval time` 與 tokens per second，不是透過用戶端軟體計時。

> [!NOTE]
> 如果你用 Chatbox、Open WebUI 等工具測到的 tok/s 比較低，通常是因為這些工具把網路往返和排隊等待也一併算進去了，跟這裡的 decode 運算速度不是同一個量測基準。

### 5.1 MTP 移植 vs 官方 GGUF

用官方原始 GGUF 當對照組。兩邊的本體權重完全相同（移植版就是拿官方檔案當 target），差異只在有沒有 MTP head。測試條件：`-c 65536`、強制全 GPU。

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th></th><th>官方原始（無 MTP）</th><th>MTP 移植版（n-max 2）</th></tr>
</thead>
<tbody>
<tr><td><strong>decode tok/s</strong></td><td>172.948</td><td><strong>226.124</strong></td></tr>
<tr><td><strong>標準差</strong></td><td>0.114</td><td>4.79</td></tr>
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
      label: '官方原始（無 MTP）',
      data: [172.948],
      backgroundColor: 'rgb(148, 163, 184)',
      borderColor: 'rgb(148, 163, 184)'
    },
    {
      label: 'MTP 移植版（n-max 2）',
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
    title: { display: true, text: 'Decode 吞吐量比較' },
    subtitle: { display: true, text: 'MTP 移植版提升約 30.7%' },
    tooltip: { callbacks: { label: (ctx) => ctx.dataset.label + '：' + ctx.parsed.y + ' tok/s' } }
  },
  scales: {
    y: { beginAtZero: true, title: { display: true, text: 'tok/s', color: () => window.chartTextColor() }, ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } },
    x: { ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } }
  }
}
{{< /chart >}}
<!-- prettier-ignore-end -->

> [!SUCCESS]
> MTP 移植帶來了約 **30.7%** 的 decode 吞吐提升。

### 5.2 長文脈品質驗證

滿血 `-c 262144` 已超出這張卡強制全 GPU 的容量，本測試在自動分層、融合核心停用的狀態下進行。用 needle-in-haystack 方法——在填充文字中埋入一句密語，於文本末端要求模型回憶。

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>指標</th><th>數值</th></tr>
</thead>
<tbody>
<tr><td>實際 prompt token 數</td><td>114,051</td></tr>
<tr><td>prefill tok/s</td><td>1,085</td></tr>
<tr><td>decode tok/s</td><td>95.20</td></tr>
<tr><td>draft acceptance</td><td>0.924</td></tr>
</tbody>
</table>
</div>

> [!SUCCESS]
> 密語正確回憶，acceptance 沒有下滑。即使在融合核心被停用的降級狀態下，長文脈品質依然穩定。

### 5.3 Context Size 消融

固定 `--spec-draft-n-max 1`、`-ngl 999 --no-mmap`，掃描 5 個 `-c` 值，每點 5 次重複。

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>-c 大小</th><th>GPU 分層狀態</th><th>decode tok/s</th><th>acceptance</th><th>VRAM</th></tr>
</thead>
<tbody>
<tr><td>16,384</td><td>強制全 GPU</td><td>219.012</td><td>0.906</td><td>21.61 GB</td></tr>
<tr class="row-adopted"><td>65,536（採用）</td><td>強制全 GPU</td><td><strong>218.948</strong></td><td>0.906</td><td>22.73 GB</td></tr>
<tr class="row-fail"><td>131,072</td><td>VRAM 不足，退回自動分層</td><td>149.828</td><td>0.909</td><td>22.16 GB</td></tr>
<tr class="row-fail"><td>200,000</td><td>VRAM 不足，退回自動分層</td><td>133.416</td><td>0.925</td><td>22.07 GB</td></tr>
<tr class="row-fail"><td>262,144</td><td>VRAM 不足，退回自動分層</td><td>118.244</td><td>0.898</td><td>22.00 GB</td></tr>
</tbody>
</table>
</div>

<!-- prettier-ignore-start -->
{{< chart >}}
type: 'line',
data: {
  labels: ['16,384', ['65,536', '（採用）'], '131,072', '200,000', '262,144'],
  datasets: [
    {
      label: '強制全 GPU',
      data: [219.012, 218.948, null, null, null],
      borderColor: 'rgb(34, 197, 94)',
      backgroundColor: 'rgb(34, 197, 94)',
      pointBackgroundColor: 'rgb(34, 197, 94)',
      pointRadius: [5, 8, 0, 0, 0],
      borderWidth: 3,
      tension: 0
    },
    {
      label: 'VRAM 不足，退回自動分層',
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
    title: { display: true, text: 'Context Size 對 Decode 速度的影響' },
    tooltip: { callbacks: { label: (ctx) => ctx.parsed.y + ' tok/s' } }
  },
  scales: {
    y: { beginAtZero: true, title: { display: true, text: 'tok/s', color: () => window.chartTextColor() }, ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } },
    x: { title: { display: true, text: '-c（context 長度）', color: () => window.chartTextColor() }, ticks: { color: () => window.chartTextColor() }, grid: { color: () => window.chartGridColor() } }
  }
}
{{< /chart >}}
<!-- prettier-ignore-end -->

> [!IMPORTANT]
> 速度曲線是兩段不同機制疊出來的。只要能維持強制全 GPU（上限落在 65K–131K 之間），decode 速度幾乎打平；一旦 context 超過容量、VRAM 不足迫使系統退回自動分層，融合核心隨之停用，速度才會大幅下滑。16K 和 65K 速度幾乎一致（219 → 218），但一超過 131K 就直接跳水到 149。

### 5.4 spec-draft-n-max 消融

固定 `-c 65536`、`-ngl 999 --no-mmap`，掃描 n-max 1–4，每點 5 次重複。

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>n-max</th><th>decode tok/s</th><th>標準差</th><th>acceptance</th><th>VRAM</th><th>狀態</th></tr>
</thead>
<tbody>
<tr><td>1</td><td>218.948</td><td>2.294</td><td>0.906</td><td>22.73 GB</td><td>強制全 GPU</td></tr>
<tr class="row-adopted"><td>2（採用）</td><td><strong>226.124</strong></td><td>4.793</td><td>0.805</td><td>22.98 GB</td><td>強制全 GPU</td></tr>
<tr><td>3</td><td>229.924</td><td>7.864</td><td>0.760</td><td>23.26 GB</td><td>強制全 GPU（餘裕極小）</td></tr>
<tr class="row-fail"><td>4</td><td>151.932</td><td>3.846</td><td>0.675</td><td>21.47 GB</td><td>生成期 OOM，退回自動分層</td></tr>
</tbody>
</table>
</div>

> [!WARNING]
> n=3 的平均值（229.9 tok/s）雖然最高，但標準差（7.86）大到跟 n=2 的區間明顯重疊；VRAM 餘裕不到 750MB，接近 n=4 那種「啟動成功、生成中才崩潰」的危險區。維持 **n=2** 為生產設定。

### 5.5 Backend / Flash Attention 對照

同一份移植後的 GGUF、`-c 16384`、n-max 1，全部強制 `-ngl 999 --no-mmap`，固定 prompt 重複 5 次取平均。

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>變體</th><th>decode tok/s</th><th>標準差</th><th>acceptance</th><th>VRAM</th></tr>
</thead>
<tbody>
<tr class="row-adopted"><td>CUDA + FA on</td><td><strong>219.012</strong></td><td>1.371</td><td>0.906</td><td>21.61 GB</td></tr>
<tr><td>CUDA + FA off</td><td>217.412</td><td>1.640</td><td>0.898</td><td>21.61 GB</td></tr>
<tr><td>Vulkan</td><td>179.032</td><td>6.639</td><td>0.896</td><td>21.33 GB</td></tr>
</tbody>
</table>
</div>

FA 的開關差距落在標準差內，沒有顯著影響。CUDA 相較 Vulkan 快了約 22%，來自於 Tensor Core 與 cuBLAS 的原生優化。

> [!TIP]
> 如果系統上同時有內顯和獨立顯卡，Vulkan 和 CUDA 的裝置編號順序不一定一致——換 backend 測試前先確認裝置對應，避免不小心用到效能較差的裝置。

### 5.6 KV Cache 量化實驗

固定 `-c 65536`、n-max 2，全部強制全 GPU，測試量化 KV cache 對速度的影響。

<div class="table-frame">
<table class="data-table">
<thead>
<tr><th>變體</th><th>tok/s（mean ± std）</th><th>acceptance</th><th>VRAM</th></tr>
</thead>
<tbody>
<tr><td>無量化（基準）</td><td>226.124 ± 4.79</td><td>0.805 ± 0.032</td><td>22.98 GB</td></tr>
<tr><td><code>-ctk/-ctv q8_0</code></td><td>225.796 ± 1.35</td><td>0.827 ± 0.009</td><td>22.48 GB</td></tr>
<tr><td><code>-ctk/-ctv q4_0</code></td><td>227.224 ± 4.54</td><td>0.836 ± 0.028</td><td>22.17 GB</td></tr>
</tbody>
</table>
</div>

三組差距落在雜訊範圍內——在這個 context 長度下，decode 的瓶頸在權重矩陣的讀取與運算，不在 KV cache 頻寬。

雖然速度沒有明顯提升，但 `q4_0` 省下了約 0.81GB 的 VRAM——這或許足以讓 131K context 也能塞進強制全 GPU 模式，值得後續測試。

---

## 6. MTP 版接入 Hermes Agent

MTP 版服務跟基礎版使用相同的 API 位址與 alias，Hermes Agent 不需要任何額外設定。如果你已經完成第 3 章的設定，直接重啟服務即可——Hermes 看到的還是 `deepreinforce-ai/Ornith-1.0-35B-GGUF`，但背後的 decode 速度已經提升了約 30%。

設定指令跟基礎版一模一樣：

```bash
hermes config set custom_providers.ornith-local.base_url "http://127.0.0.1:8002/v1"
hermes config set custom_providers.ornith-local.models."deepreinforce-ai/Ornith-1.0-35B-GGUF".context_length 65536
```

> Hindsight 是搭配 Hermes Agent 的長期記憶系統，負責從對話中萃取與回憶結構化記憶，同樣透過這個 provider 呼叫本地模型。

---

## 參考資料

- [Ornith-1.0-35B 官方模型頁面](https://huggingface.co/deepreinforce-ai/Ornith-1.0-35B-GGUF)
- [Ornith-1.0-35B MTP 移植版](https://huggingface.co/skinnyctax/Ornith-1.0-35B-Q6_K-Frankenstein-MTP-GGUF)
- [llama.cpp GitHub](https://github.com/ggml-org/llama.cpp)
- [llama.cpp 編譯文件](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)
- [llama.cpp Speculative Decoding](https://github.com/ggml-org/llama.cpp/blob/master/docs/speculative.md)
- [GGUF 格式規格](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md)
- [Hermes Agent 文件](https://hermes-agent.nousresearch.com/)

## 附錄：踩雷速查表

| 陷阱 | 解法 |
|---|---|
| **GGUF header 長度前綴遺漏** | 自製編輯腳本時，特殊處理字串 KV pair 的分支要保留原始 bytes（含 8-byte 長度前綴），不要 decode 再 re-encode |
| **套件管理器無 CUDA** | Homebrew 的 bottle 機制結構性不支援 CUDA；Linux 需自行編譯 `-DGGML_CUDA=ON` |
| **多 GPU CUDA 探測 OOM** | `--main-gpu` 在裝置列舉之後才生效；用 `CUDA_VISIBLE_DEVICES=N` 在驅動層遮蔽忙碌的卡 |
| **Vulkan 裝置編號 ≠ CUDA** | 兩者排序不保證一致，換 backend 測試前先確認裝置對應 |
| **自動配置悄悄降級** | VRAM 緊繃時自動配置可能卸載層級並停用融合核心；用 `-ngl 999 --no-mmap` 明確覆蓋 |
| **強制全 GPU 也有硬上限** | `-ngl 999` 超過真實 VRAM 容量一樣會 OOM |
| **生成期 OOM** | 啟動成功但餘裕低於 1GB 的設定，仍可能在生成過程中崩潰 |
| **高標準差的最佳值** | 平均值最高但標準差大到跟次高選項重疊時，不足以支持換掉現有設定 |
| **brew upgrade 不影響自編版** | 自行編譯的執行檔是獨立檔案，回到原始碼目錄 `git pull` 後重新編譯才會更新 |
