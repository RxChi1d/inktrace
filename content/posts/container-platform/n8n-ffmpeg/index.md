---
title: "n8n-ffmpeg：整合 FFmpeg 的 n8n Docker 映像檔與自動化構建實作"
slug: "n8n-ffmpeg"
date: 2025-11-19T20:30:00+08:00
lastmod: 2025-12-27T10:43:49+08:00
tags: ["n8n", "docker", "ffmpeg", "github-actions"]
categories: ["container-platform"]
---

本文介紹 **n8n-ffmpeg** 開源專案，這是一個針對 n8n 官方映像檔進行功能擴充的解決方案，提供預裝 FFmpeg 且自動同步最新版本的 Docker Image。本文將解析其背後的自動化構建流程、因應官方版本變更的技術調整，以及如何應用於生產環境。

<!--more-->

> [!IMPORTANT]
> **[2025-12-26 更新 v1.0.0]**：由於 n8n 官方映像檔 (v2.1.0+) 移除了 `apk` 套件管理工具，導致原有的構建方式失效。本專案已更新至 v1.0.0，採用 Multi-stage build 恢復套件安裝能力。此架構調整將應用於本專案產出的所有新版映像檔（對應 n8n v2.1.0+），確保使用者能持續獲得一致且可擴充的環境。

## 前言：關於 n8n 的多媒體處理需求

對於 n8n 的使用者而言，透過 `Execute Command` 節點呼叫外部 CLI 工具（如 `ffmpeg`）處理影音轉檔或壓縮，是極為常見的需求。然而，官方 Docker Image 為了維持輕量化與安全性，預設並未包含這些工具。

雖然可以在容器啟動後手動安裝，但面對 n8n 頻繁的更新週期，重複的手動維運不僅低效，更可能導致生產環境的版本碎片化。

**RxChi1d/n8n-ffmpeg** 專案旨在解決此問題，提供一個與官方版本實時同步且開箱即用的環境：

- **GitHub Repository**: [RxChi1d/n8n-ffmpeg](https://github.com/RxChi1d/n8n-ffmpeg)
- **Docker Hub**: [rxchi1d/n8n-ffmpeg](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg)

### 快速部署

本專案的映像檔設計完全相容於官方版本。若使用 Docker Compose 進行部署，僅需替換 `image` 欄位：

```yaml {title="docker-compose.yml" lineNos=inline hl_lines=[4,5,10]}
version: "3"
services:
  n8n:
    # 將原本的 n8nio/n8n 替換為 rxchi1d/n8n-ffmpeg
    image: rxchi1d/n8n-ffmpeg:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - NODES_EXCLUDE=[]
    volumes:
      - ./n8n_data:/home/node/.n8n
```

> [!IMPORTANT]
> **關於 Execute Command 節點**：從 n8n@2.0.0 開始，官方基於安全性考量，預設停用了包含 `Execute Command` 在內的數個節點。若需使用 `ffmpeg` 等指令，必須在環境變數中添加 `NODES_EXCLUDE=[]` 來解除所有節點的停用狀態。詳細資訊請參閱 [n8n 官方文件](https://docs.n8n.io/hosting/configuration/environment-variables/nodes/)。

替換並重啟容器後，即可在 Workflow 中直接調用 `ffmpeg` 指令，無需進行額外的安裝步驟。

---

## 實作原理：構建策略與挑戰

本專案的核心挑戰在於：**如何在不破壞官方映像檔穩定性的前提下，注入額外的系統級依賴？**

### 挑戰：n8n v2.1.0 的架構變革

在早期版本中，我們可以直接在 Dockerfile 中使用 `apk add` 安裝軟體。然而，自 [n8n v2.1.0](https://github.com/n8n-io/n8n/releases/tag/n8n%402.1.0) 版本開始（參見 [PR #23149](https://github.com/n8n-io/n8n/pull/23149)），官方為了縮減映像檔體積並減少攻擊面，在構建的最後階段移除了 `apk` 套件管理工具（`apk-tools`）。

這意味著下游的衍生映像檔無法再直接執行 `apk` 指令，導致舊有的構建方式失效。

> [!NOTE]- 舊版 v0.1.0 實作方式（已失效，僅供參考）
> 在 n8n v2.1.0 之前，官方映像檔保留了 `apk`，因此可以使用以下簡單的 Dockerfile（[原始碼](https://github.com/RxChi1d/n8n-ffmpeg/blob/v0.1.0/Dockerfile)）：
>
> ```dockerfile {title="Dockerfile (Legacy)"}
> ARG N8N_VERSION=latest
> FROM n8nio/n8n:${N8N_VERSION}
> USER root
> RUN apk add --no-cache ffmpeg
> USER node
> ```
>
> 此方法在 n8n v2.1.0+ 會因找不到 `apk` 指令而構建失敗。

### 1. 方案一：標準版（Standard Variant） —— 兼顧擴充性

為了適應上述改變，v1.0.0 版本採用了 **Multi-stage builds** 策略。我們先從 Alpine 官方映像檔中提取 `apk-tools` 的靜態執行檔與簽章金鑰，再將其注入到 n8n 環境中，從而「恢復」安裝套件的能力。

**Dockerfile 核心邏輯：**

```dockerfile {title="Dockerfile"}
ARG N8N_VERSION=latest
ARG ALPINE_VERSION=3.22

# 1. 準備 apk-tools
FROM alpine:${ALPINE_VERSION} AS apktools
RUN apk add --no-cache apk-tools-static

# 2. 以官方版本為基底
FROM n8nio/n8n:${N8N_VERSION}

ARG ALPINE_VERSION
USER root

# 3. 恢復 apk-tools (從 apktools stage 複製)
COPY --from=apktools /sbin/apk.static /sbin/apk.static
COPY --from=apktools /etc/apk/keys /tmp/apk-keys
RUN mkdir -p /etc/apk /etc/apk/keys \
    && cp -n /tmp/apk-keys/* /etc/apk/keys/ || true \
    && printf 'https://dl-cdn.alpinelinux.org/alpine/v%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/v%s/community\n' "$ALPINE_VERSION" "$ALPINE_VERSION" > /etc/apk/repositories \
    && /sbin/apk.static -X "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" -U add apk-tools \
    && rm -f /sbin/apk.static \
    && rm -rf /tmp/apk-keys

# 4. 安裝 ffmpeg
RUN apk add --no-cache ffmpeg ffmpeg-dev \
    && rm -rf /var/cache/apk/*

USER node
```

**設計考量：**

*   **為什麼不直接下載？**  
    或許有人會好奇，為何不直接用 `wget` 下載 `apk-tools-static`？
    選擇從官方 Alpine Image 複製，是為了避免額外依賴並確保版本穩定性。
*   **金鑰保護**  
    在恢復 `apk` 功能時，代碼中使用了 `cp -n` (no-clobber) 指令來合併金鑰。這是為了確保**不覆蓋** n8n 映像檔中原有的任何金鑰檔案，避免破壞基礎映像檔的信任鏈。

### 2. 方案二：輕量版 (Minimal Variant)

如果生產環境對安全性或映像檔體積有嚴格要求，且確認無需使用 `apk` 安裝額外軟體，本專案提供了另一種選擇：`Dockerfile.no-apk-tools`。

此版本採用 **Builder Pattern**，在第一階段安裝 ffmpeg，接著僅將執行檔（ffmpeg, ffprobe）與必要的動態函式庫（Shared Libraries）複製到最終映像檔中。最終產出的 Image 完全不包含 `apk` 或 `apk-tools`，保持了與官方原始映像檔最小的差異。

**核心邏輯：**

```dockerfile {title="Dockerfile.no-apk-tools"}
# ... (Builder Stage 省略) ...

# Final Stage
FROM n8nio/n8n:${N8N_VERSION}
USER root

# 僅複製必要檔案，不帶入 apk
COPY --from=ffmpeg /out/bin/ /opt/ffmpeg/bin/
COPY --from=ffmpeg /out/lib/ /opt/ffmpeg/lib/

# 透過 Wrapper 設定 LD_LIBRARY_PATH，僅在執行 ffmpeg 時生效
RUN printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/ffmpeg/lib exec /opt/ffmpeg/bin/ffmpeg "$@"\n' > /usr/local/bin/ffmpeg \
    && chmod +x /usr/local/bin/ffmpeg \
# ... (省略部分設定) ...

USER node
```

**構建方式：**
```bash {title="Terminal"}
docker build -f Dockerfile.no-apk-tools -t n8n-ffmpeg:clean .
```

---

## 自動化維護：GitHub Actions CI/CD

為了達成「版本實時同步」，本專案引入了 GitHub Actions 託管發布週期：

1.  **上游追蹤 (Upstream Monitor)**：  
    透過 `check-updates.yml` 工作流，系統每 6 小時自動檢查 n8n 官方 Docker Hub 的最新 Tag。
2.  **自動構建與發布 (Auto Build & Push)**：  
    一旦偵測到新版本，系統即自動觸發構建流程。利用 Docker Buildx ，同時編譯 `linux/amd64` 與 `linux/arm64` 兩種架構的映像檔並推送至 Docker Hub。

> [!INFO]
> 本專案僅提供官方支援的架構 (amd64/arm64)。若硬體環境為其他架構（如 RISC-V），則需要參考上述 Dockerfile 進行手動構建。

---

## 結語

**n8n-ffmpeg** 專案展示了如何透過 CI/CD 與 Dockerfile 的靈活運用，解決開源工具在特定場景下的功能缺口。

透過這個自動化方案，我們不僅省去了重複構建的時間成本，更確保了生產環境中的 n8n 始終具備最新的功能與安全性修復，同時擁有完整的影音處理能力。無論是選擇標準版還是極致輕量版，都能滿足不同場景下的部署需求。

如果您覺得這個專案有幫助，歡迎前往 [**GitHub Repository**](https://github.com/RxChi1d/n8n-ffmpeg) 給予 Star 支持，或直接從 [**Docker Hub**](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg) 下載映像檔使用。
