---
title: "Immich 地理編碼臺灣特化 - immich-geodata-zh-tw 專案介紹與使用教學"
slug: "immich-geodata-zh-tw"
date: 2025-10-05T13:35:00+08:00
tags: ["docker", "immich"]
categories: ["container-platform"]
---

本文介紹 immich-geodata-zh-tw 專案，針對臺灣優化 Immich 的反向地理編碼：將地名中文化、補齊行政區層級並提升精準度。內容包含整合式（entrypoint）與手動部署教學、安裝驗證與更新方式、版本指定與常見問題，並說明如何重新提取元數據以讓舊照片套用新地理資訊。

<!--more-->

在「[Immich 部署、設定與反向代理 - Google 相簿的最佳開源替代方案](/posts/container-platform/immich-deployment/)」中，我們完成了 Immich 的基本部署。但你可能會發現幾個個問題：  
- 照片的地理資訊都是 **英文**，常常只看得到 "Sanzhi, Taipei, Taiwan, Province of China"。
- **不夠精確的資訊**，無法定位到鄉鎮市區，有時候甚至會顯示為錯誤的地點。

為了解決這些問題，我開發了 **[immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw)** 這個專案，專門針對臺灣使用者優化 Immich 的反向地理編碼功能。

{{< github repo="rxchi1d/immich-geodata-zh-tw" showThumbnail=true >}}

## 為什麼需要這個專案？

Immich 原生的反向地理編碼主要依賴 GeoNames 全球資料庫，對臺灣使用者來說，臺灣的地名有幾個明顯問題：

1. **英文地名**：缺乏繁體中文翻譯
2. **行政區顯示不完整**：只有縣市名稱，看不到更細緻的鄉鎮市區層級
3. **地名解析不夠精準**：缺乏在地化的邊界資料，導致有時候會顯示錯誤的地點

簡單來說，你在臺北 101 拍的照片可能只會顯示 "Taipei, Taiwan, Province of China"，而不是更精確的 "臺灣 臺北市 信義區"。

## 主要特性

- **中文化處理**：將全球地名轉為臺灣慣用繁體中文
- **行政區優化**：補足臺灣 → 直轄市/縣市 → 鄉鎮市區等完整層級
- **臺灣資料更準**：採用國土測繪中心（NLSC）村里界做為權威資料源
- **自動更新**：支援容器啟動時自動抓取最新資料

## 使用前後對比

{{< figure
    src="https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/comparison.png"
    alt="使用前後對比"
    >}}

不僅地名更精確，中文搜尋體驗也大幅提升！

---

## 快速開始

在這個專案中，我們設計了兩種部署方式：**整合式部署**（推薦）或**手動部署**。你可以根據自己的需求選擇適合的方式。

### 方法 A：整合式部署 🚀（推薦）

若你的 Immich 是用 Docker Compose 或 Portainer 部署的，就可以用這個方法，快速且簡單地完成設定。  

> 如果是使用 Synology Docker 套件，請參考 Chiyuan Chien 的 [Immich 相簿地理位置如何改以中文顯示？](https://cychien.tw/wordpress/2025/04/05/immich%E7%9B%B8%E7%B0%BF%E5%9C%B0%E7%90%86%E4%BD%8D%E7%BD%AE%E5%A6%82%E4%BD%95%E6%94%B9%E4%BB%A5%E4%B8%AD%E6%96%87%E9%A1%AF%E7%A4%BA%EF%BC%9F/)。

這種方式只要在 compose file 中 (如下方範例的 `immich_server`) 加入一段 `entrypoint` 配置，就能在啟動 Immich Server 容器時自動下載並導入最新的臺灣特化地理資料。

**1. 修改 docker-compose.yml**

```yaml
services:
  immich_server:
    container_name: immich_server
    # ...其餘設定省略
    entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://raw.githubusercontent.com/RxChi1d/immich-geodata-zh-tw/refs/heads/main/update_data.sh) --install && exec start.sh" ]
```

以 Immich 官方的 [docker-compose.yml 範例](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml) 為例，完整內容如下圖：

{{< figure
  src="https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/docker-compose-example.png"
  alt="docker-compose.yml 範例"
  caption="docker-compose.yml 範例"
  >}}

**2. 重啟 Immich**

在修改完 `docker-compose.yml` 後，重啟 Immich 容器：

```bash
docker compose down && docker compose up -d
```

<a id="tag:check-install-status"></a>
**3. 確認安裝成功**

首先，在終端機中使用命令印出 Immich Server 的日誌：

```bash
docker logs immich_server
```

> 如果是使用 Docker Desktop 或 Portainer 等 GUI 工具，也可以在介面中查看日誌。

接著我們需要分別檢查 `immich-geodata-zh-tw` 腳本和 Immich 本身是否成功載入資料：  
1. `immich-geodata-zh-tw` 腳本是否成功執行 (包含下載與導入資料)  
    若看到類似以下訊息，表示腳本執行成功：  
    {{< figure
      src="https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-script.png"
      alt="檢查 immich-geodata-zh-tw 腳本執行結果"
      caption="檢查 immich-geodata-zh-tw 腳本執行結果"
      >}}
2. Immich 是否成功載入這些資料  
    檢查日誌中是否有 `10000 geodata records imported` 類似訊息，表示 Immich 成功載入資料：
    {{< figure
        src="https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-import.png"
        alt="檢查 Immich 載入地理資料結果"
        caption="檢查 Immich 載入地理資料結果"
        >}}

    <a id="tag:fix-import-failed"></a>
    > [!TIP] **沒看到導入訊息？**  
    > 如果腳本有成功執行，但 Immich 日誌中沒有看到導入訊息，可以改以「[方法 B：手動部署](#方法-b手動部署-️)」部署，並修改 `geodata/geodata-date.txt` 中的時間戳為更加新的日期。例如：`2025-09-19` 改為 `2025-09-20`。（超過當天日期也沒關係）  
    > 經過測試後沒問題再改回來用整合式部署。

如果兩個步驟都沒問題，就代表安裝成功了！接著請繼續下面的「[重新提取照片元數據](#重新提取照片元數據-)」步驟。

### 方法 B：手動部署 🛠️

如果你需要進階操作，如有特別的檔案擺放需求、權限考量或是除錯，就可以用這個方法。

**1. 修改 docker-compose.yml volumes**

```yaml
volumes:
  - /mnt/user/appdata/immich/geodata:/build/geodata:ro
  - /mnt/user/appdata/immich/i18n-iso-countries/langs:/usr/src/app/server/node_modules/i18n-iso-countries/langs:ro
```

> [!TIP] **版本提醒**  
> 如果使用 Immich < 1.136.0，因為 Immich 容器內部結構不同，因此需要將第二行要改成：  
> `/mnt/user/appdata/immich/i18n-iso-countries/langs:/usr/src/app/node_modules/i18n-iso-countries/langs:ro`

**2. 下載臺灣特化資料**

有兩種方式：

**(a) 自動下載腳本**
```bash
curl -sSL https://raw.githubusercontent.com/RxChi1d/immich-geodata-zh-tw/refs/heads/main/update_data.sh -o update_data.sh
chmod +x update_data.sh
./update_data.sh
```

該腳本會自動下載並解壓縮最新的 release 版本到當前目錄中的 temp 資料夾，主要流程如下：
1. 下載最新版本資料
   - 從 GitHub releases 下載 latest 版本的 [release.tar.gz](https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/release.tar.gz)
2. 解壓縮到本地目錄
   - 目標目錄：`./temp`
   - 如果目錄已存在且包含舊版本，會先清理 `geodata` 和 `i18n-iso-countries` 子資料夾
   - 解壓縮後會保留原始的 `release.tar.gz` 檔案
3. 完成提示

**(b) 手動下載**  
到 [Releases 頁面](https://github.com/RxChi1d/immich-geodata-zh-tw/releases) 下載最新的 `release.tar.gz` 並解壓縮。

**3. 移動到對應資料夾**

將解壓縮後的 `geodata` 和 `i18n-iso-countries` 資料夾，移動到你在 `docker-compose.yml` 中指定的路徑：

```bash
mv ./temp/geodata /mnt/user/appdata/immich/geodata
mv ./temp/i18n-iso-countries /mnt/user/appdata/immich/i18n-iso-countries
```

**4. 重啟服務**

```bash
docker compose down && docker compose up -d
```

完成後，參考上面的「[3. 確認安裝成功](#tag:check-install-status)」步驟，檢查日誌是否有成功導入資料。成功導入後，請繼續下面的「[重新提取照片元數據](#重新提取照片元數據-)」步驟。

### 重新提取照片元數據 📸

無論用哪種方式，在成功導入後，都需要重新提取照片的元數據，才能讓 Immich 重新套用新的地理資訊。
> [!TIP]
> 如果你的 Immich 中沒有任何的照片，例如剛部署完，這個步驟可以跳過。

1. **登入 Immich 後台**
   {{< figure
        src="https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-1.png"
        alt="登入 Immich 後台"
        caption="登入 Immich 後台"
        >}}
2. **系統管理** → **任務**
    {{< figure
          src="https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-2.png"
          alt="進入系統管理的任務頁面"
          caption="進入系統管理的任務頁面"
          >}}
3. **提取元數據** → **全部**
    {{< figure
          src="https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-3.png"
          alt="選擇提取元數據並點擊全部"
          caption="選擇提取元數據並點擊全部"
          >}}

這時，舊照片的地理資訊就會被更新成新的中文地名，而新上傳的照片則會直接套用！

---

## 進階功能

### 指定特定版本

有時你可能需要使用特定版本，可以用 `--tag` 參數指定：

**整合式部署**：
```yaml
entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://raw.githubusercontent.com/RxChi1d/immich-geodata-zh-tw/refs/heads/main/update_data.sh) --install --tag v1.0.0 && exec start.sh" ]
```

**手動部署**：
```bash
./update_data.sh --tag v1.0.0
```

可用版本請查看 [Releases 頁面](https://github.com/RxChi1d/immich-geodata-zh-tw/releases)。

---

## 常見問題 🔧

**Q: 如何更新資料？**  
A: 整合式部署直接重啟 docker compose；手動部署需要重新下載最新的資料。

**Q: 導入訊息看不到，中文沒套用？**  
A: 檢查日誌是否有 `geodata records imported`；若沒有，請參考「[沒看到導入訊息？](#tag:fix-import-failed)」調整 `geodata-date.txt` 時間戳再重啟。別忘了重新提取元數據。

**Q: 縣市名稱已經更新為繁體中文了，但國家名稱卻還是英文？**  
A: 可能原因為您使用的 Immich 版本為 1.136.0 以後的新版本，但使用的 immich-geodata-zh-tw 版本小於 v1.2.0。只要使用最新發布（預設）或 v1.2.0 以上版本即可解決此問題。  
> 相關連結：[Issue #8](https://github.com/RxChi1d/immich-geodata-zh-tw/issues/8)

**Q: 容器一直重啟，報 `main.js not found`？**  
A: 你可能在 Immich 1.142.0+ ，但還用舊的啟動方式。請根據「[方法 A：整合式部署 🚀（推薦）](#方法-a整合式部署-推薦)」，更新 docker-compose.yml 中的 entrypoint 配置即可。

> 相關連結：[Issue #13](https://github.com/RxChi1d/immich-geodata-zh-tw/issues/13)

---

## 總結

**immich-geodata-zh-tw** 的目標很單純：提供符合臺灣使用者使用習慣的地理資訊優化，讓用戶可以更順手的使用 Immich，不僅看得到正確的行政區層級，也能用熟悉的繁體中文搜尋照片。

如果這個專案對你有幫助，歡迎到 [GitHub 專案倉庫](https://github.com/RxChi1d/immich-geodata-zh-tw) 給個 Star 支持，或分享你的使用心得！

---

## 參考資源

- [專案 GitHub](https://github.com/RxChi1d/immich-geodata-zh-tw)
- [前文：Immich 部署教學](https://inktrace.rxchi1d.me/posts/container-platform/immich-deployment/)
- [國土測繪中心開放資料](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)
