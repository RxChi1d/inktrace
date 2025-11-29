---
title: "n8n 容器部署教學 - Docker Compose 配置、Redis 快取與反向代理設定"
slug: "n8n-deployment"
date: 2025-11-29T21:46:47+08:00
tags: ["docker", "n8n", "redis", "nginx-proxy-manager"]
categories: ["container-platform"]
---

本文介紹如何使用 Docker Compose 部署 n8n 工作流程自動化平台，包含基礎配置、Redis 快取整合，以及透過 Nginx Proxy Manager 設定反向代理實現 HTTPS 安全存取。

<!--more-->

## 前言

[n8n](https://n8n.io/) 是一個開源的工作流程自動化平台，提供視覺化介面讓使用者透過拖曳方式建立自動化工作流程，類似 Zapier 或 Make（原 Integromat）。n8n 支援超過 400 種整合服務，且可自行部署，完全掌控資料隱私與安全性。

使用 Docker 部署 n8n 具有以下優勢：

- **環境隔離**：避免與系統其他服務衝突
- **易於維護**：一鍵更新與備份
- **跨平台支援**：在任何支援 Docker 的系統上運行
- **資源管理**：可限制容器資源使用

本文將涵蓋以下內容：

1. 基礎 n8n 容器部署與初始化
2. 整合 Redis 快取提升效能
3. 使用 Nginx Proxy Manager 設定反向代理
4. 常見問題排查

### 前置需求

開始之前，請確認您已具備：

- ✅ 已安裝 Docker 與 Docker Compose（[安裝教學](https://docs.docker.com/engine/install/)）
- ✅ 基本終端機操作能力
- ✅ （可選）網域名稱與已部署的 Nginx Proxy Manager

> [!TIP]
> 本教學適合具備 Docker 基礎知識的使用者。如果您是 Docker 新手，建議先熟悉 `docker compose up`、`docker compose down` 等基本指令。

## 基礎部署：n8n 容器

### 建立目錄結構

首先，建立用於儲存 n8n 資料的目錄。資料持久化能確保容器重啟後工作流程、憑證等資料不會遺失。

```bash
# Create data directories
sudo mkdir -p /appdata/n8n/data
sudo mkdir -p /appdata/n8n/files

# Change owner to 1000:1000 (n8n container default user) to avoid permission errors
sudo chown -R 1000:1000 /appdata/n8n
```

目錄說明：

- `/appdata/n8n/data`：儲存 n8n 的資料庫、工作流程、憑證等核心資料
- `/appdata/n8n/files`：儲存工作流程中處理的檔案

> [!NOTE]
> 您可以根據需求調整路徑，但需確保 Docker 有讀寫權限。若使用非 root 使用者，建議將目錄放在家目錄下（如 `~/appdata/n8n`）。

### 撰寫 docker-compose.yml

建立一個名為 `docker-compose.yml` 的檔案，內容如下：

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    volumes:
      - /appdata/n8n/data:/home/node/.n8n
      - /appdata/n8n/files:/files
    environment:
      - N8N_PORT=5678
      - NODE_ENV=production
      - GENERIC_TIMEZONE=Asia/Taipei
      - TZ=Asia/Taipei
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
```

#### 關鍵環境變數說明

| 環境變數 | 說明 | 預設值 |
|---------|------|--------|
| `N8N_PORT` | n8n Web 介面監聽的埠號 | `5678` |
| `NODE_ENV` | Node.js 執行環境（`production` 或 `development`） | `production` |
| `GENERIC_TIMEZONE` | n8n 內部使用的時區 | `America/New_York` |
| `TZ` | 容器系統時區 | `UTC` |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | 強制檢查設定檔權限，提升安全性 | `false` |

> [!IMPORTANT]
> 時區設定對於排程工作流程非常重要。`GENERIC_TIMEZONE` 影響工作流程中的時間邏輯，`TZ` 影響容器系統時間。兩者應設定一致。

### 啟動容器

在 `docker-compose.yml` 所在目錄執行：

```bash
# Start n8n container in detached mode
docker compose up -d
```

驗證容器狀態：

```bash
# Check container status
docker compose ps
```

您應該會看到類似以下的輸出：

```
NAME      IMAGE            COMMAND                  SERVICE   CREATED         STATUS         PORTS
n8n       n8nio/n8n:latest "tini -- /docker-ent…"   n8n       10 seconds ago  Up 9 seconds   0.0.0.0:5678->5678/tcp
```

### 存取 n8n 介面

開啟瀏覽器，訪問 `http://localhost:5678`。  
如果您在遠端伺服器上部署，請將 `localhost` 替換為伺服器的 IP 位址。

> [!WARNING]
> 目前 n8n 尚未啟用任何身份驗證機制。若在公開網路環境，請務必設定反向代理並啟用身份驗證（詳見後續章節）。

### 初始化設定

首次訪問時，n8n 會要求建立管理員帳號：

1. **填寫帳號資訊**：
   - Email：您的電子郵件地址
   - 名稱：顯示名稱
   - 密碼：建議使用強密碼

2. **完成設定**：
   - 點擊「Get Started」進入主介面

3. **基本介面導覽**：
   - **Workflows**：管理與建立工作流程
   - **Credentials**：儲存第三方服務的認證資訊
   - **Executions**：查看工作流程執行歷史
   - **Settings**：系統設定

恭喜！您已成功部署基礎版 n8n。接下來我們將整合 Redis 快取以提升效能。

## Redis 快取整合

### 為什麼需要 Redis？

Redis 是一個高效能的記憶體資料庫。在 n8n 中，你可以透過**工作流程中的 Redis 節點**來使用 Redis 進行快取操作：

- **暫存 API 回應資料**：避免重複呼叫外部 API，減少延遲與成本
- **儲存臨時變數**：在不同工作流程間共享資料
- **實作速率限制**：追蹤 API 呼叫次數
- **快取運算結果**：避免重複執行耗時的資料處理

**適用場景**：

- ✅ 頻繁呼叫相同的外部 API
- ✅ 需要在多個工作流程間共享資料
- ✅ 實作自定義的快取邏輯

> [!NOTE]
> **關於 Queue Mode**：n8n 也支援將 Redis 作為訊息佇列的 **Queue Mode**，用於大量並發場景。此功能需要額外配置（包含設定環境變數與新增 worker 容器），超出本文範圍。如有需求請參考[n8n Queue Mode 文件](https://docs.n8n.io/hosting/scaling/queue-mode/)。

### 更新 docker-compose.yml

停止現有容器：

```bash
docker compose down
```

編輯 `docker-compose.yml`，新增 Redis 服務與網路設定：

```yaml
services:
  n8n:
    # ... 其他配置保持不變
    depends_on:
      - redis  # 新增：確保 Redis 先啟動
    networks:
      - n8n-network

  redis:
    image: redis:alpine
    container_name: n8n-redis
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - /appdata/n8n/redis/data:/data
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

networks:
  n8n-network:
    # ... 網路配置保持不變
```

#### 配置說明

**Redis 映像選擇**：
- 使用 `redis:alpine` 而非 `redis:<version>`（如 `redis:8`）
- Alpine 版本僅包含 Redis 核心功能，移除了 bash、git 等額外工具
- 適合單純作為快取資料庫使用，無需在容器內執行額外操作
- 映像大小更小（約 30MB vs 120MB），節省儲存空間與加快部署速度

**重要參數**：
- `--appendonly yes`：啟用 AOF（Append-Only File）持久化機制，確保資料不會因容器重啟而遺失（因此需要掛載資料卷）
- `healthcheck`：定期檢查 Redis 服務健康狀態，確保可用性

**網路設定**：
- `networks`：將 n8n 與 Redis 放在同一網路，使其能互相通訊
- `depends_on`：確保 Redis 在 n8n 之前啟動

### 建立 Redis 資料目錄

```bash
sudo mkdir -p /appdata/n8n/redis/data
```

### 啟動服務

```bash
docker compose up -d
```

### 驗證 Redis 運作（選用）

雖然可以直接在 n8n 工作流程中使用 Redis 節點來測試連線，但你也可以透過指令驗證 Redis 是否正常運作。

**1. 檢查容器日誌**：

```bash
# Check Redis logs
docker compose logs redis
```

您應該會看到類似以下的輸出：

```
n8n-redis  | 1:C 29 Nov 2025 06:30:00.123 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
n8n-redis  | 1:C 29 Nov 2025 06:30:00.123 # Redis version=8.x.x, bits=64, pid=1, just started
n8n-redis  | 1:M 29 Nov 2025 06:30:00.124 * Ready to accept connections
```

**2. 測試 Redis 連線**：

```bash
# Test Redis connection
docker exec -it n8n-redis redis-cli ping
```

預期回應：

```
PONG
```

### 如何在工作流程中使用 Redis

Redis 容器已準備就緒！要在 n8n 工作流程中使用 Redis，請按照以下步驟：

**1. 在工作流程中新增 Redis 節點**：

在 n8n 編輯器中搜尋並新增「Redis」節點。

**2. 設定 Redis 連線**：

建立新的 Redis 憑證，填入以下資訊：

- **主機名 (Host)**：`n8n-redis`（Docker 網路中的容器名稱）
- **埠號 (Port)**：`6379`
- **密碼 (Password)**：留空（基礎配置未設定密碼）
- **資料庫 (Database)**：`0`（預設值）

**3. 選擇 Redis 操作**：

Redis 節點支援多種操作，例如：
- `Set`：儲存資料
- `Get`：讀取資料
- `Delete`：刪除資料
- `Incr`/`Decr`：遞增/遞減計數器

> [!IMPORTANT]
> n8n **不會自動**使用 Redis 進行快取或 Session 管理。你必須在工作流程中**主動添加 Redis 節點**並設定相應的邏輯才能使用 Redis 功能。

**範例使用情境**：

假設你需要快取外部 API 的回應以避免重複呼叫：

1. 使用 Redis `Get` 節點檢查快取是否存在
2. 如果不存在，呼叫 API 並使用 Redis `Set` 節點儲存結果（可設定過期時間）
3. 如果存在，直接使用快取資料

恭喜！Redis 容器已成功部署並可供使用。接下來我們將設定反向代理實現 HTTPS 存取。

## Nginx Proxy Manager 反向代理設定

### 前置準備

在開始之前，請確認：

1. ✅ 已部署 Nginx Proxy Manager（NPM）
2. ✅ 擁有網域名稱（如 `n8n.example.com`）
3. ✅ DNS A 記錄已指向伺服器 IP

> [!NOTE]
> 如果您尚未部署 NPM，可以參考 [Nginx Proxy Manager 官方文件](https://nginxproxymanager.com/guide/)或相關教學文章。

### n8n 環境變數調整

停止容器並編輯 `docker-compose.yml`，更新 n8n 的環境變數：

```yaml
services:
  n8n:
    # ... 其他配置保持不變
    environment:
      - N8N_PORT=5678
      - NODE_ENV=production
      - GENERIC_TIMEZONE=Asia/Taipei
      - TZ=Asia/Taipei
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
      # 新增：反向代理配置
      - N8N_HOST=n8n.example.com          # 替換為您的網域
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.example.com
    # ... 其他配置保持不變
```

#### 關鍵環境變數說明

| 環境變數 | 說明 | 範例值 |
|---------|------|--------|
| `N8N_HOST` | n8n 的網域名稱 | `n8n.example.com` |
| `N8N_PROTOCOL` | 存取協定 | `https` |
| `WEBHOOK_URL` | Webhook 的 URL（務必正確設定） | `https://n8n.example.com` |

> [!WARNING]
> `WEBHOOK_URL` 設定錯誤會導致工作流程中的 Webhook 節點無法正常運作。請確保設定為正確的外部存取網址。

重啟容器以套用變更：

```bash
# Restart containers
docker compose down && docker compose up -d
```

### NPM 設定步驟

登入 Nginx Proxy Manager 管理介面，新增 Proxy Host：

#### 1. Details 頁籤

- **Domain Names**: `n8n.example.com`（您的網域）
- **Scheme**: `http`
- **Forward Hostname / IP**:
  - 如果 NPM 與 n8n 在同一 Docker 網路：填入容器名稱 `n8n`
  - 如果不在同一網路：填入伺服器 IP（如 `192.168.1.100`）
- **Forward Port**: `5678`
- **Cache Assets**: ✅ 啟用（可選）
- **Block Common Exploits**: ✅ 啟用（建議）
- **Websockets Support**: ✅ **務必啟用**（n8n 需要 WebSocket 支援）

> [!IMPORTANT]
> 必須啟用 **Websockets Support**，否則 n8n 的即時功能（如工作流程執行狀態更新）將無法正常運作。

#### 2. Custom Locations 頁籤

此頁籤用於設定特定路徑的轉發規則（如 `/api` 轉發到不同的後端）。對於 n8n 的基礎配置，**無需進行任何設定**，保持空白即可。

#### 3. SSL 頁籤

- **SSL Certificate**: 選擇「Request a new SSL Certificate」或選擇已有的憑證（如果有的話）
- **Force SSL**: ✅ 啟用（強制使用 HTTPS）
- **HTTP/2 Support**: ✅ 啟用（建議）
- **HSTS Enabled**: ✅ 啟用（提升安全性，建議）
- **HSTS Subdomains**: ✅ 啟用（建議）

#### 4. Advanced 頁籤（可選但建議）

為了避免長時間執行的工作流程被 Timeout，建議新增以下自訂 Nginx 配置：

```nginx
proxy_buffering off;
proxy_read_timeout 3600s;
proxy_send_timeout 3600s;
proxy_connect_timeout 3600s;
```

配置說明：
- `proxy_buffering off`：停用緩衝，即時傳輸資料
- `proxy_read_timeout`：讀取 timeout 設為 1 小時
- `proxy_send_timeout`：發送 timeout 設為 1 小時
- `proxy_connect_timeout`：連線 timeout 設為 1 小時

> [!TIP]
> 如果您的工作流程執行時間可能超過 1 小時，請適當調整 timeout 數值（單位：秒）。

### 驗證反向代理

**1. 存取 n8n**：

開啟瀏覽器，訪問：

```
https://n8n.example.com
```

您應該會看到 n8n 登入介面，且瀏覽器位址列顯示安全鎖頭圖示（表示 HTTPS 有效）。

**2. 測試 Webhook 功能**（可選）：

1. 在 n8n 中建立新工作流程
2. 新增「Webhook」節點
3. 設定 Webhook 觸發條件
4. 複製 Webhook URL（應為 `https://n8n.example.com/webhook/...`）
5. 使用 `curl` 或 Postman 測試 Webhook

```bash
# Test webhook
curl -X POST https://n8n.example.com/webhook/your-webhook-path
```

如果 Webhook 正常觸發，表示反向代理設定成功。

> [!NOTE]
> 若 Webhook 無法觸發，請檢查：
> 1. NPM 的 Websockets Support 是否已啟用
> 2. `WEBHOOK_URL` 環境變數是否正確
> 3. SSL 憑證是否有效

## 完整配置範例

以下是整合所有功能的完整 `docker-compose.yml` 配置：

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    depends_on:
      - redis
    volumes:
      - /appdata/n8n/data:/home/node/.n8n
      - /appdata/n8n/files:/files
    environment:
      # Domain and protocol configuration
      - N8N_HOST=n8n.example.com
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.example.com

      # Environment settings
      - NODE_ENV=production
      - GENERIC_TIMEZONE=Asia/Taipei
      - TZ=Asia/Taipei

      # Security settings
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
    networks:
      - n8n-network

  redis:
    image: redis:alpine
    container_name: n8n-redis
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - /appdata/n8n/redis/data:/data
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

networks:
  n8n-network:
    name: n8n-network
```

### 環境變數完整清單

| 類別 | 環境變數 | 說明 | 必要性 |
|------|---------|------|--------|
| **網域設定** | `N8N_HOST` | n8n 網域名稱 | 使用反向代理時必要 |
| | `N8N_PROTOCOL` | 存取協定（http/https） | 使用 HTTPS 時必要 |
| | `WEBHOOK_URL` | Webhook URL | 使用 Webhook 時必要 |
| **基本設定** | `N8N_PORT` | Web 介面埠號 | 選用（預設 5678） |
| | `NODE_ENV` | Node.js 環境 | 建議設為 production |
| | `GENERIC_TIMEZONE` | n8n 時區 | 建議設定 |
| | `TZ` | 容器系統時區 | 建議設定 |
| **安全性** | `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | 強制檢查設定檔權限 | 建議啟用 |

### 建議的目錄結構

```
/appdata/n8n/
├── data/                    # n8n 核心資料
├── files/                   # 工作流程處理的檔案
└── redis/
    └── data/                # Redis 持久化資料
```

## 常見問題

### Q: 容器啟動後無法存取介面？

**可能原因與解決方法**：

1. **防火牆阻擋**：
   ```bash
   # Check firewall rules (Ubuntu/Debian)
   sudo ufw allow 5678/tcp

   # Check firewall rules (CentOS/RHEL)
   sudo firewall-cmd --add-port=5678/tcp --permanent
   sudo firewall-cmd --reload
   ```

2. **埠號被佔用**：
   ```bash
   # Check if port 5678 is in use
   sudo lsof -i :5678

   # Or use netstat
   sudo netstat -tuln | grep 5678
   ```
   如果埠號被佔用，可在 `docker-compose.yml` 中修改為其他埠號（如 `"5679:5678"`）

3. **容器異常**：
   ```bash
   # Check container logs
   docker compose logs n8n
   ```
   根據錯誤訊息進行排查

### Q: Webhook 無法正常運作？

**檢查清單**：

1. ✅ 確認 `WEBHOOK_URL` 環境變數設定正確
   ```bash
   # Check environment variables
   docker exec n8n env | grep WEBHOOK_URL
   ```

2. ✅ NPM 的 Websockets Support 已啟用
   - 登入 NPM → Proxy Hosts → 編輯 n8n 的 Proxy Host
   - 確認 Details 頁籤中「Websockets Support」已勾選

3. ✅ SSL 憑證有效
   ```bash
   # Check SSL certificate
   curl -I https://n8n.example.com
   ```

4. ✅ 防火牆規則正確
   - 確認 443 埠號（HTTPS）已開放

### Q: Redis 連線失敗？

**排查步驟**：

1. **確認容器在同一網路**：
   ```bash
   # Check network configuration
   docker network inspect n8n-network
   ```
   確認 `n8n` 和 `n8n-redis` 都在清單中

2. **檢查 Redis 健康狀態**：
   ```bash
   # Check Redis health
   docker compose ps
   ```
   確認 Redis 容器狀態為 `healthy`

3. **測試連線**：
   ```bash
   # Test connection from n8n container
   docker exec n8n ping n8n-redis
   ```

4. **查看 Redis 日誌**：
   ```bash
   # Check Redis logs
   docker compose logs redis
   ```

### Q: 如何更新 n8n 版本？

**更新步驟**：

1. **檢查目前版本**：
   ```bash
   # Check current version
   docker exec n8n n8n --version
   ```

2. **備份資料**

3. **更新映像並重啟**：
   ```bash
   # Pull latest image
   docker compose pull n8n

   # Recreate container
   docker compose up -d
   ```

4. **指定特定版本**（可選）：

   編輯 `docker-compose.yml`，修改映像 tag：
   ```yaml
   services:
     n8n:
       image: n8nio/n8n:1.x.x  # 替換為目標版本
   ```

   然後執行：
   ```bash
   docker compose up -d
   ```

> [!WARNING]
> 更新前請務必備份資料。某些版本更新可能包含資料庫遷移，無法降級。建議查看 [n8n Release Notes](https://github.com/n8n-io/n8n/releases) 了解變更內容。

## 參考資源

### 官方文件

- [n8n 官方文件](https://docs.n8n.io/) - 完整功能說明與 API 參考
- [n8n Docker 部署指南](https://docs.n8n.io/hosting/installation/docker/) - 官方 Docker 部署文件
- [Docker Compose 文件](https://docs.docker.com/compose/) - Docker Compose 使用指南
- [Redis 官方文件](https://redis.io/docs/) - Redis 配置與最佳實踐
- [Nginx Proxy Manager 官方文件](https://nginxproxymanager.com/guide/) - NPM 使用教學

### 社群資源

- [n8n GitHub Repository](https://github.com/n8n-io/n8n) - 原始碼與 Issue 追蹤
- [n8n Community Forum](https://community.n8n.io/) - 官方社群論壇
- [n8n Workflows](https://n8n.io/workflows/) - 工作流程範例庫

### 相關文章

- Nginx Proxy Manager 部署教學（建議先閱讀）
- Docker Container Monitor（容器監控）
- n8n-ffmpeg 專案介紹（需要影音處理功能時參考）

---

## 結語

透過本文的步驟，您已成功部署一個具備 Redis 快取、HTTPS 安全存取的 n8n 工作流程自動化平台。現在您可以開始探索 n8n 的強大功能，建立各種自動化工作流程來提升工作效率。

如果在部署過程中遇到問題，歡迎參考「常見問題」章節或在 [n8n 社群論壇](https://community.n8n.io/)尋求協助。

祝您使用愉快！
