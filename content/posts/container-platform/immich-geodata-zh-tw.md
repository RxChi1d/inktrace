---
title: "Immich 地理編碼臺灣特化 - immich-geodata-zh-tw 專案介紹與使用教學"
slug: "immich-geodata-zh-tw"
date: 2025-10-05T13:35:00+08:00
lastmod: 2025-12-30T14:34:35+08:00
tags: ["docker", "immich"]
categories: ["container-platform"]
series: ["immich-geodata-zh-tw"]
series_order: 1
---

本文介紹 immich-geodata-zh-tw 專案，這是一個專為繁體中文使用者打造的 Immich 反向地理編碼優化方案。除了針對臺灣進行深度的在地化處理（中文化、行政區層級補齊），v2.0 版本起更將支援範圍擴展至日本與南韓，並提供更穩定的自動化更新機制。

<!--more-->

在「[Immich 部署、設定與反向代理 - Google 相簿的最佳開源替代方案](/posts/container-platform/immich-deployment/)」中，我們完成了 Immich 的基本部署。但你可能會發現幾個問題：  
- 照片的地理資訊都是 **英文**，例如 "Sanzhi, Taipei, Taiwan, Province of China"。
- **行政區顯示不完整**，無法定位到鄉鎮市區，甚至顯示錯誤的地點。
- **東亞地名顯示不友善**，日本與南韓的地名往往只顯示羅馬拼音。

為了解決這些問題，我開發了 **[immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw)** 專案，透過優化 Immich 的反向地理編碼資料庫，提供符合臺灣使用者習慣的地理資訊體驗。

{{< github repo="rxchi1d/immich-geodata-zh-tw" showThumbnail=true >}}

## 為什麼需要這個專案？

Immich 原生的反向地理編碼主要依賴 GeoNames 全球資料庫，這對繁體中文使用者造成了幾個主要問題：

1. **英文地名**：缺乏繁體中文翻譯。
2. **行政區顯示不完整**：只有縣市名稱，看不到更細緻的鄉鎮市區層級。
3. **地名解析不夠精準**：缺乏在地化的邊界資料，導致有時候會顯示錯誤的地點。

例如，在臺北 101 拍攝的照片可能只顯示 "Taipei, Taiwan, Province of China"，而非「臺灣 臺北市 信義區」。同樣地，日本的「東京都千代田区」也會變成羅馬拼音的 "Chiyoda, Tokyo, Japan"。

本專案透過引入各國官方或開源的高精確度圖資，並結合自動化翻譯引擎，解決上述問題。

## 主要特性

- **🇹🇼 臺灣深度優化**：
  - 採用 **國土測繪中心 (NLSC)** 官方圖資，確保邊界權威性。
  - 修正「中國臺灣省」顯示問題，並補齊 直轄市/縣市 → 鄉鎮市區 的完整層級。
- **🇯🇵 日本旅遊友善**：
  - 採用 **国土数値情報 (KSJ)** 官方圖資。
  - 保留日文漢字與假名（如「東京都」、「千代田区」），符合臺灣人前往日本旅遊的閱讀習慣，避免奇怪的機器翻譯。
- **🇰🇷 南韓繁中翻譯**：
  - 引入官方行政區邊界資料，並透過 Wikidata 翻譯引擎將韓文地名自動翻譯為繁體中文。
- **🌏 全球地名中文化**：
  - 針對其他地區，透過 LocationIQ 與 GeoNames 資料庫進行輔助翻譯，盡量提供繁體中文名稱。

## 使用前後對比

![使用前後對比](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/comparison.png)
{style="width:80%;"}

不僅地名更精確，中文搜尋體驗也大幅提升！

---

## 快速開始

本專案支援 **整合式部署**（推薦）與 **手動部署** 兩種方式。

### 方法 A：整合式部署 🚀（推薦）

若使用 Docker Compose 部署 Immich，這是最簡單且能自動保持更新的方法。

> 如果是使用 Synology Docker 套件，請參考 Chiyuan Chien 的 [Immich 相簿地理位置如何改以中文顯示？](https://cychien.tw/wordpress/2025/04/05/immich%E7%9B%B8%E7%B0%BF%E5%9C%B0%E7%90%86%E4%BD%8D%E7%BD%AE%E5%A6%82%E4%BD%95%E6%94%B9%E4%BB%A5%E4%B8%AD%E6%96%87%E9%A1%AF%E7%A4%BA%EF%BC%9F/)。

**1. 修改 docker-compose.yml**

在 `immich_server` 服務中加入 `entrypoint` 設定：

```yaml
services:
  immich_server:
    container_name: immich_server
    # ...其餘設定省略
    # 注意：這裡使用 releases/latest/download 確保下載到穩定的釋出版本
    entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh) --install && exec start.sh" ]
```

以 Immich 官方的 [docker-compose.yml 範例](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml) 為例，完整內容如下圖：

![docker-compose.yml 範例](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/docker-compose-example.png "docker-compose.yml 範例")

**2. 重啟 Immich**

```bash
docker compose down && docker compose up -d
```

<a id="tag:check-install-status"></a>
**3. 確認安裝成功**

查看容器日誌：
```bash
docker logs immich_server
```

檢查重點：
1. 是否有看到 `immich-geodata-zh-tw` 的執行與下載訊息。  
  若看到類似以下訊息，表示腳本執行成功：  
  ![檢查 immich-geodata-zh-tw 腳本執行結果](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-script.png "檢查 immich-geodata-zh-tw 腳本執行結果")
2. Immich 啟動後是否顯示 `10000 geodata records imported`（表示成功載入資料）。  
  ![檢查 Immich 載入地理資料結果](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-import.png "檢查 Immich 載入地理資料結果")

<a id="tag:fix-import-failed"></a>
> [!QUESTION] 沒看到導入訊息？
> 若腳本執行成功但 Immich 未導入資料，請參考「[方法 B](#方法-b手動部署-️)」手動部署，並修改 `geodata-date.txt` 的時間戳，使其晚於當前時間，例如：`2025-09-19` 改為 `2025-09-20`。（超過當天日期也沒關係），以強制 Immich 重新載入地理資料。測試完成後可再改回整合式部署。    

---

### 方法 B：手動部署 🛠️

適用於有特殊掛載需求或無法連外網的環境。

**1. 修改 docker-compose.yml volumes**

```yaml
volumes:
  - /path/to/your/immich/geodata:/build/geodata:ro
  - /path/to/your/immich/i18n-iso-countries/langs:/usr/src/app/server/node_modules/i18n-iso-countries/langs:ro
```

> [!IMPORTANT]
> Immich v1.136.0 以前的版本，因為 Immich 容器內部結構不同，第二行的路徑請改為 `/path/to/your/immich/i18n-iso-countries/langs:/usr/src/app/node_modules/i18n-iso-countries/langs:ro`。

**2. 下載資料**

使用提供的腳本自動下載最新 Release：

```bash
# 下載腳本
curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh -o update_data.sh

# 賦予執行權限
chmod +x update_data.sh

# 執行下載（檔案會存放在 ./temp 目錄）
./update_data.sh
```

或直接到 [GitHub Releases](https://github.com/RxChi1d/immich-geodata-zh-tw/releases) 頁面下載 `release.tar.gz` 或 `release.zip` 並自行解壓縮。

**3. 部署檔案**

將下載/解壓後的 `geodata` 與 `i18n-iso-countries` 資料夾移動到 `docker-compose.yml` 設定的對應路徑。

```bash
mv ./temp/geodata /path/to/your/immich/
mv ./temp/i18n-iso-countries /path/to/your/immich/
```

**4. 重啟服務**

```bash
docker compose down && docker compose up -d
```

完成後，參考「[3. 確認安裝成功](#tag:check-install-status)」驗證是否導入成功。

---

### 重新提取照片元數據 📸

資料導入後，必須**重新提取元數據**，舊照片才會套用新的地理資訊（新上傳照片會自動套用）。

> [!TIP]
> 如果你的 Immich 中還沒有任何的照片，例如剛部署完，這個步驟可以跳過。

1. **登入 Immich 後台**
  ![登入 Immich 後台](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-1.png "登入 Immich 後台")
2. 進入 **系統管理 (Administration)** → **任務 (Jobs)**
  ![進入系統管理的任務頁面](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-2.png "進入系統管理的任務頁面")
3. 找到 **提取元數據 (Extract Metadata)**，點擊 **全部 (All)**
  ![選擇提取元數據並點擊全部](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-3.png "選擇提取元數據並點擊全部")

這時，舊照片的地理資訊就會被更新成中文地名，而新上傳的照片則會直接套用！

> [!QUESTION] 提取元數據後，名稱卻沒有更新？
> 請參考「[方法 B](#方法-b手動部署-️)」手動部署，並修改 `geodata-date.txt` 的時間戳，使其晚於當前時間，例如：`2025-09-19` 改為 `2025-09-20`。（超過當天日期也沒關係），以強制 Immich 重新載入地理資料。測試完成後可再改回整合式部署。   
---

## 進階功能

### 指定特定版本

若最新的 Release 有問題，或想固定使用特定版本（例如 `v2.2.0`），可以使用 `--tag` 參數。

**整合式部署：**
修改 `entrypoint` 中的指令：
```yaml
entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/download/latest/update_data.sh) --install --tag v2.2.0 && exec start.sh" ]
```

**手動部署：**
```bash
./update_data.sh --tag v2.2.0
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
A: 這通常發生在 Immich v1.142.0+ 版本。因為 Immich 更改了啟動檔名，如果您使用了舊版的 `entrypoint` 指令（包含 `exec node dist/main` 之類的），請根據「[方法 A：整合式部署 🚀（推薦）](#方法-a整合式部署-推薦)」，更新 docker-compose.yml 中的 entrypoint 配置。

> 相關連結：[Issue #13](https://github.com/RxChi1d/immich-geodata-zh-tw/issues/13)

---

## 總結

**immich-geodata-zh-tw** 致力於解決繁體中文使用者的痛點。從 v2.0 開始，我們引入了更穩定的架構與官方圖資，不僅讓臺灣地名更精準，也照顧到了日韓旅遊照片的整理需求。

如果您覺得這個專案有幫助，歡迎到 [GitHub](https://github.com/RxChi1d/immich-geodata-zh-tw) 給我一顆星星 ⭐ 支持！

---

## 參考資源

- [專案 GitHub 倉庫](https://github.com/RxChi1d/immich-geodata-zh-tw)
- [GeoNames (全球基礎資料)](https://www.geonames.org/)
- [國土測繪中心開放資料 (臺灣)](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)
- [国土数値情報ダウンロード (日本)](https://nlftp.mlit.go.jp/ksj/)
- [admdongkor (南韓)](https://github.com/vuski/admdongkor)
- [OpenStreetMap (全球輔助資料)](https://www.openstreetmap.org/)
