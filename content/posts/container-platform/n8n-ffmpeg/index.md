---
title: "n8n-ffmpeg：整合 FFmpeg 的 n8n Docker 映像檔與自動化構建實作"
slug: "n8n-ffmpeg"
date: 2025-11-19T20:30:00+08:00
lastmod: 2025-12-26T17:22:36+08:00
tags: ["n8n", "docker", "ffmpeg", "github-actions"]
categories: ["container-platform"]
---

本文介紹 n8n-ffmpeg 開源專案，提供預裝 FFmpeg 且自動同步官方最新版本的 n8n Docker 映像檔。文章內容包含專案運作原理、GitHub Actions 自動化構建流程解析，以及如何透過 Docker Compose 快速部署或手動建構客製化環境。

<!--more-->

## 前言：關於 n8n 的多媒體處理需求

對於許多 n8n 使用者來說，利用 `Execute Command` 節點呼叫外部 CLI 工具來處理資料是常見的應用場景。其中，`ffmpeg` 是處理音訊與影片轉檔、壓縮或提取資訊的標準工具。

然而，為了維持映像檔的輕量化與安全性，n8n 的官方 Docker Image 預設並未包含 `ffmpeg`。雖然我們可以在容器啟動後手動安裝，或者自行撰寫 Dockerfile 進行擴充，但這帶來了一個長期的維運問題：**n8n 的更新頻率較高，若採用手動構建，每次官方發布新版本時，我們都需要重複執行構建與部署流程，否則將面臨版本落後或功能缺失的風險。**

為了優化這個流程，消除重複性的維護工作，我建立了一個開源專案 **n8n-ffmpeg**，透過自動化 CI/CD 流程來解決這個問題。

## 🚀 專案介紹：RxChi1d/n8n-ffmpeg

這個專案旨在提供一個**與官方版本實時同步**且**預載 FFmpeg** 的 Docker Image。

透過自動化的追蹤機制，此專案確保使用者無需自行維護 Dockerfile 或監控官方更新，即可直接使用具備完整多媒體處理能力的 n8n 環境。

- **GitHub Repository**: [https://github.com/RxChi1d/n8n-ffmpeg](https://github.com/RxChi1d/n8n-ffmpeg)
    
- **Docker Hub**: [https://hub.docker.com/r/rxchi1d/n8n-ffmpeg](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg)
    

### 如何使用？

本專案的 Image 設計完全相容於官方版本。若您使用 Docker Compose 進行部署，僅需替換 `image` 欄位即可：

YAML

```yaml
version: "3"
services:
  n8n:
    # 將原本的 n8nio/n8n 替換為 rxchi1d/n8n-ffmpeg
    image: rxchi1d/n8n-ffmpeg:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
    volumes:
      - ./n8n_data:/home/node/.n8n
```

替換並重啟容器後，您即可在 Workflow 中直接調用 `ffmpeg` 指令，無需進行額外的安裝步驟。

---

## ⚙️ 實作原理：構建邏輯與自動化流程

本專案的技術實現主要包含兩個部分：底層的 Dockerfile 擴充邏輯，以及上層基於 GitHub Actions 的自動化發布流程。

### 1. 核心設計：Dockerfile 的擴充策略

在映像檔的構建上，為了確保環境的穩定性並最大限度地保留官方功能，我採用了 `FROM` 繼承官方映像檔的策略，僅在最上層添加必要的依賴包。

以下是專案中使用的 `Dockerfile` 核心邏輯：

Dockerfile

```dockerfile
ARG N8N_VERSION=latest

# 1. 以官方版本為基底，確保環境一致性
FROM n8nio/n8n:${N8N_VERSION}

# 2. 切換為 root 權限以執行套件管理指令
USER root

# 3. 安裝 ffmpeg
RUN apk add --no-cache ffmpeg

# 4. 切換回 node 使用者，符合最小權限原則 (PoLP)
USER node
```

這種實作方式既單純又透明，確保了使用者獲得的是一個乾淨、僅擴充了 ffmpeg 功能的標準 n8n 環境。

### 2. 自動化維護：GitHub Actions CI/CD

為了達成「版本同步」的目標，專案引入了 GitHub Actions 來託管整個發布週期。這是一套典型的 Cron-based CI 流程：

- 上游追蹤 (Upstream Monitor)：
    
    透過 check-updates.yml 工作流，系統每 6 小時會自動執行一次檢查。腳本會透過 API 獲取 n8n 官方 Docker Hub 的最新 Tag，並與本專案已發布的版本進行比對。
    
- 自動構建與發布 (Auto Build & Push)：
    
    一旦偵測到版本差異（例如官方發布了新版），系統即自動觸發構建流程。利用 Docker Buildx 技術，我們會同時編譯 linux/amd64 與 linux/arm64 兩種架構的映像檔，並將其推送至 Docker Hub。
    

這套流程確保了本專案的映像檔能夠在官方更新後的最短時間內跟進，使用者無需擔心相容性問題。

> [!INFO]
>
> 本專案僅提供官方支援的架構 (amd64/arm64)。若您的硬體環境為其他架構（如 RISC-V），則需要參考上述 Dockerfile 進行手動構建。

---

## 🛠️ 自定義構建指南

雖然本專案已能滿足大多數需求，但若您有更進階的客製化需求（例如需要整合 `yt-dlp`、`Python` 環境，或是基於內部資安規範需自行控管映像檔來源），您可以參考上述的原理自行構建。

只需在本地建立 `Dockerfile`，並執行標準的 Docker 建構指令：

Bash

```bash
# 建立自定義映像檔
docker build -t my-custom-n8n .
```

完成後，將部署設定指向您本地構建的 Image 名稱即可。

---

## 結語

**n8n-ffmpeg** 專案展示了如何透過簡單的 CI/CD 配置，有效解決開源工具使用中的維運痛點。

透過這個自動化方案，我們不僅省去了重複構建的時間成本，更確保了生產環境中的 n8n 始終具備最新的功能與安全性修復，同時擁有完整的影音處理能力。希望這個專案的實作思路能為同樣需要客製化 Docker 環境的開發者提供參考。

- **GitHub Repository**: [RxChi1d/n8n-ffmpeg](https://github.com/RxChi1d/n8n-ffmpeg)
    
- **Docker Hub**: [rxchi1d/n8n-ffmpeg](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg)
    
