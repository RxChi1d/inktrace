---
title: "Immich 地理編碼臺灣特化 - immich-geodata-zh-tw 專案介紹與使用教學"
slug: "immich-geodata-zh-tw"
date: 2025-10-05T13:35:00+08:00
lastmod: 2026-08-31T22:04:33+08:00
description: "immich-geodata-zh-tw 安裝教學：在 Docker Compose 加一行 entrypoint，讓 Immich 的相片地點顯示臺灣、日本、南韓、泰國、印尼的在地化中文地名。含手動與非容器部署。"
tags: ["docker", "immich"]
categories: ["container-platform"]
series: ["immich-geodata-zh-tw"]
series_order: 1
---

本文介紹 immich-geodata-zh-tw 專案，這是一個專為繁體中文使用者打造的 Immich 反向地理編碼優化方案。除了針對臺灣進行深度的在地化處理（中文化、行政區層級補齊），支援範圍目前也涵蓋日本、南韓、泰國與印尼，其餘地區則補上臺灣慣用的中文譯名，並提供穩定的自動化更新機制。

<!--more-->

在「[Immich 部署、設定與反向代理 - Google 相簿的最佳開源替代方案](/posts/container-platform/immich-deployment/)」中，我們完成了 Immich 的基本部署。但你可能會發現幾個問題：  
- 照片的地理資訊都是 **英文**，例如 Immich 的原始輸出會顯示 "Sanzhi, Taipei, Taiwan, Province of China"。
- **行政區顯示不完整**，無法定位到鄉鎮市區，甚至顯示錯誤的地點。
- **亞洲地名顯示不友善**，日本、南韓、泰國與印尼的地名往往只顯示羅馬拼音。

為了解決這些問題，我開發了 **[immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw)** 專案，透過優化 Immich 的反向地理編碼資料庫，提供符合臺灣使用者習慣的地理資訊體驗。

{{< github repo="rxchi1d/immich-geodata-zh-tw" showThumbnail=true >}}

## 為什麼 Immich 的相片地點會顯示英文？

Immich 原生的反向地理編碼主要依賴 GeoNames 全球資料庫，這對繁體中文使用者造成了幾個主要問題：

1. **英文地名**：缺乏繁體中文翻譯。
2. **行政區顯示不完整**：只有縣市名稱，看不到更細緻的鄉鎮市區層級。
3. **地名解析不夠精準**：缺乏在地化的邊界資料，導致有時候會顯示錯誤的地點。

例如，在臺北 101 拍攝的照片可能只顯示 "Taipei, Taiwan, Province of China"，而非「臺灣 臺北市 信義區」。同樣地，日本的「東京都千代田区」也會變成羅馬拼音的 "Chiyoda, Tokyo, Japan"。

本專案透過引入各國官方或開源的高精確度圖資，並結合自動化翻譯引擎，解決上述問題。

想知道為什麼替換幾個純文字檔就能改變 Immich 顯示的地名，可以參考系列技術篇的[反向地理編碼是怎麼運作的](/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)。

## immich-geodata-zh-tw 支援哪些地區

| 地區 | 顯示語言 | 圖資來源 |
| :--- | :--- | :--- |
| 🇹🇼 臺灣 | 繁體中文官方名稱 | 國土測繪中心（NLSC）村里界 |
| 🇯🇵 日本 | 日文原名（漢字與假名） | 国土数値情報（KSJ） |
| 🇰🇷 南韓 | 一級行政區繁體中文，縣市為韓國官方漢字 | admdongkor 行政洞界 |
| 🇹🇭 泰國 | 繁體中文，官方英文與泰文備用 | COD-AB（OCHA） |
| 🇮🇩 印尼 | 繁體中文，BIG 官方印尼文備用 | 印尼地理空間資訊局（BIG）村級圖資 |
| 🌏 其他地區 | 國教院官方譯名 → GeoNames 中文 → 保留原文 | GeoNames |

臺灣的部分除了中文化，還修正了國家名稱顯示不正確、多數縣市名稱從缺的問題，並補齊直轄市/縣市 → 鄉鎮市區的完整層級。

> [!NOTE]
> 南韓的縣市會顯示韓國官方漢字，例如「淸州市」而不是「清州市」。韓國地名本來就是漢字詞，漢字是原名而非翻譯，這點與日本保留日文漢字同理，字形與臺灣慣用寫法略有出入是正常的。
>
> 各地區為什麼採用不同策略，詳見系列技術篇的[五個地區，五種答案](/posts/engineering/immich-geodata-tech-03-strategies/)。

## 使用前後對比

![使用前後對比](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/comparison.png)
{style="width:80%;"}

不僅地名更精確，中文搜尋體驗也大幅提升！

---

## 安裝步驟

### 開始之前

請先確認以下條件：

- **Immich 已經部署完成且可正常啟動**（尚未部署請先參考「[Immich 部署、設定與反向代理](/posts/container-platform/immich-deployment/)」）
- 你有權限修改 `docker-compose.yml` 並重啟容器
- **整合式部署需要容器啟動時能連到 `github.com`**；環境無法對外連線請改用手動部署
- 知道自己的 Immich 版本（本專案支援 v2 與 v3。只有停留在 v1 舊版的環境才需要留意文中標註的路徑差異）
- 照片本身含有 GPS 資訊，否則 Immich 無從判斷地點

多數人適用方法 A：用 Docker Compose 部署、容器啟動時連得到 GitHub，在 `docker-compose.yml` 加一行就結束，之後也會自動保持更新。如果有特殊的掛載需求，或環境本來就連不到外網，就走方法 B 自己下載資料。Immich 沒有跑在容器裡的話（例如 macOS 原生安裝、LXC 或裸機），直接看「[其他部署方式](#其他部署方式macos-原生-workerlxc-與裸機-)」那一節。

### 方法 A：整合式部署 🚀（推薦）

若使用 Docker Compose 部署 Immich，這是最簡單且能自動保持更新的方法。

> 如果是使用 Synology Docker 套件，請參考 Chiyuan Chien 的 [Immich 相簿地理位置如何改以中文顯示？](https://cychien.tw/wordpress/2025/04/05/immich%E7%9B%B8%E7%B0%BF%E5%9C%B0%E7%90%86%E4%BD%8D%E7%BD%AE%E5%A6%82%E4%BD%95%E6%94%B9%E4%BB%A5%E4%B8%AD%E6%96%87%E9%A1%AF%E7%A4%BA%EF%BC%9F/)。

#### 1. 修改 docker-compose.yml

在 `immich_server` 服務中加入 `entrypoint` 設定：

```yaml
services:
  immich_server:
    container_name: immich_server
    # ...其餘設定省略
    # 注意：這裡使用 releases/latest/download 確保下載到穩定的釋出版本
    entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh) --install && exec start.sh" ]
```

> [!IMPORTANT]
> 指令結尾必須是 `exec start.sh`。寫成 `exec /bin/bash start.sh` 會讓 Immich v1.142.0 以後的版本無法判斷自身路徑，導致容器不斷重啟。

> [!WARNING] 連不到 GitHub 時，Immich 會起不來
> `&&` 是短路運算：腳本在下載失敗時會以非 0 結束，`exec start.sh` 就不會執行，容器隨即退出。這是為了避免沒有正確獲取中文圖資時，Immich 仍然啟動，導致使用者以為已經套用中文地名。

以 Immich 官方的 [docker-compose.yml 範例](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml) 為例，完整內容如下圖：

![docker-compose.yml 範例](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/docker-compose-example.png "docker-compose.yml 範例")

#### 2. 重啟 Immich

```bash
docker compose down && docker compose up -d
```

#### 3. 確認安裝成功 {#check-install-status}

查看容器日誌：
```bash
docker logs immich_server
```

檢查重點：
1. 是否有看到 `immich-geodata-zh-tw` 的執行與下載訊息。  
  若看到類似以下訊息，表示腳本執行成功：  
  ![檢查 immich-geodata-zh-tw 腳本執行結果](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-script.png "檢查 immich-geodata-zh-tw 腳本執行結果")
  腳本最後若輸出 `驗證通過`，代表資料確實寫入 Immich 會讀取的位置（含決定國家名稱顯示的 `en.json`），這是比日誌關鍵字更可靠的判斷依據。
2. Immich 啟動後是否顯示 `10000 geodata records imported`（表示成功載入資料）。  
  ![檢查 Immich 載入地理資料結果](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-import.png "檢查 Immich 載入地理資料結果")

<a id="fix-import-failed"></a>
> [!QUESTION] 沒看到導入訊息？
> Immich 會比對 `geodata/geodata-date.txt` 的內容與資料庫中的紀錄，兩者**內容不同**時才會重新匯入，比的是內容而不是日期新舊。  
> 整合式部署每次啟動都會重新安裝資料，因此日期沒變就代表已經匯入過同一份資料，這時請改為確認「提取元數據」是否選擇「全部」，以及照片本身是否含有 GPS 資訊。  
> 手動部署與其他部署方式則可以把 `geodata/geodata-date.txt` 改成與現值**不同**的內容（例如今天的日期），再重啟 Immich 強制重新匯入。

到這裡整合式部署就完成了。**如果你的 Immich 裡已經有照片，還需要執行最後一步**：「[重新提取照片元數據](#extract-metadata)」，舊照片才會套用新的地理資訊。

---

### 方法 B：手動部署 🛠️

適用於有特殊掛載需求或無法連外網的環境。

#### 1. 修改 docker-compose.yml volumes

```yaml
volumes:
  - /path/to/your/immich/geodata:/build/geodata:ro
  - /path/to/your/immich/i18n-iso-countries/langs:/usr/src/app/server/node_modules/i18n-iso-countries/langs:ro
```

> [!IMPORTANT]
> Immich v1.136.0 以前的版本，因為 Immich 容器內部結構不同，第二行的路徑請改為 `/path/to/your/immich/i18n-iso-countries/langs:/usr/src/app/node_modules/i18n-iso-countries/langs:ro`。

#### 2. 下載資料

先取得下載腳本：

```bash
curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh -o update_data.sh
```

接著編輯腳本開頭的 `DOWNLOAD_DIR` 變數（在檔案前段的設定區，搜尋 `DOWNLOAD_DIR=` 即可找到），填入上方兩個掛載路徑的**共同上層目錄**（以上面的範例來說就是 `/path/to/your/immich`），然後執行：

```bash
bash update_data.sh
```

完成後會得到這樣的結構，不需要再手動搬移檔案：

```text
/path/to/your/immich/geodata/
/path/to/your/immich/i18n-iso-countries/langs/
```

也可以直接到 [GitHub Releases](https://github.com/RxChi1d/immich-geodata-zh-tw/releases) 頁面下載 `release.tar.gz` 或 `release.zip`，解壓縮後把 `geodata` 與 `i18n-iso-countries` 兩個資料夾放到相同位置。

> [!NOTE]
> UnRAID 使用者可以透過 User Scripts 外掛執行腳本。

#### 3. 重啟服務

```bash
docker compose down && docker compose up -d
```

完成後，參考「[3. 確認安裝成功](#check-install-status)」驗證是否導入成功。

---

### 其他部署方式（macOS 原生 worker、LXC 與裸機） 🖥️

Immich 沒有跑在 Docker 容器裡時也能安裝，例如 [immich-apple-silicon](https://github.com/epheterson/immich-apple-silicon) 或 LXC，只是指令要在**執行 microservices worker 的那台機器**上操作，因為地理資料只會在該服務啟動時匯入。

安裝前建議先讓腳本印出它打算安裝的位置：

```bash
bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh) --print-paths
```

確認無誤後把 `--print-paths` 換成 `--install` 即可安裝；路徑不正確時可用 `IMMICH_SERVER_ROOT` 與 `IMMICH_BUILD_DATA` 指定。macOS 加速器的重啟方式、LXC 與裸機的 `sudo` 注意事項等細節，請參考專案的 [README「非容器部署」](https://github.com/RxChi1d/immich-geodata-zh-tw#非容器部署) 章節。

---

## 最後一步（所有部署方式共通）：重新提取照片元數據 📸 {#extract-metadata}

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
> 請參考「[沒看到導入訊息？](#fix-import-failed)」確認 Immich 是否真的重新匯入了地理資料。
---

## 進階功能

### 指定特定版本

若最新的 Release 有問題，或想固定使用特定版本（例如 `v3.2.0`），可以使用 `--tag` 參數。**腳本本身一律從最新版本取得，只有資料版本由 `--tag` 決定。**

**整合式部署：**
修改 `entrypoint` 中的指令：
```yaml
entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh) --install --tag v3.2.0 && exec start.sh" ]
```

**手動部署：**
```bash
bash update_data.sh --install --tag v3.2.0
```

> [!IMPORTANT]
> 不要把腳本網址改成 `releases/download/<tag_name>/update_data.sh`。`nightly` 這類自動發布的版本不包含 `update_data.sh`，該網址會回傳 404，整合式部署會因此無法啟動。

可用版本請查看 [Releases 頁面](https://github.com/RxChi1d/immich-geodata-zh-tw/releases)。若環境無法連外網，也可以先下載 `release.tar.gz`，再用 `--archive` 安裝，詳細參數說明見專案的 [update_data.sh 使用說明](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/update-script.md)。

---

## 常見問題 🔧

**Q: 如何更新資料？**  
A: 整合式部署直接重啟 docker compose 即可自動更新；手動部署重新執行一次 `bash update_data.sh` 後重啟容器；其他部署方式則重新執行同一條 `--install` 指令後重啟 Immich 服務。更新後別忘了視情況重新提取元數據。

**Q: 導入訊息看不到，中文沒套用？**  
A: 檢查日誌是否有 `geodata records imported`；若沒有，請參考「[沒看到導入訊息？](#fix-import-failed)」確認匯入條件。別忘了重新提取元數據。

**Q: 縣市名稱已經更新為繁體中文了，但國家名稱卻還是英文？**  
A: 可能原因為您使用的 Immich 版本為 1.136.0 以後的新版本，但使用的 immich-geodata-zh-tw 版本小於 v1.2.0。只要使用最新發布（預設）或 v1.2.0 以上版本即可解決此問題。  
> 相關連結：[Issue #8](https://github.com/RxChi1d/immich-geodata-zh-tw/issues/8)

**Q: 容器一直重啟，報 `main.js not found`？**  
A: 這通常發生在 Immich v1.142.0+ 版本。因為 Immich 更改了啟動檔名，如果您使用了舊版的 `entrypoint` 指令（包含 `exec node dist/main` 或 `exec /bin/bash start.sh` 之類的），請根據「[方法 A：整合式部署 🚀（推薦）](#方法-a整合式部署-推薦)」，更新 docker-compose.yml 中的 entrypoint 配置。

> 相關連結：[Issue #13](https://github.com/RxChi1d/immich-geodata-zh-tw/issues/13)

**Q: 有些照片的地點跟實際位置有落差？**  
A: Immich 依照最近距離原則比對地名，靠近行政區邊界的座標可能被歸到鄰近的行政區，小型島嶼或特殊地形也可能無法精確對應。這是 Immich 的解析方式所致，並非資料錯誤。這套最近鄰查詢的運作方式詳見[反向地理編碼是怎麼運作的](/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)。

**Q: 如何移除或還原成原本的地名？**  
A: 整合式部署刪掉 `docker-compose.yml` 裡的 `entrypoint` 那一行；手動部署則移除兩條 volume 掛載。重啟容器後 Immich 會改用官方預設的 GeoNames 資料（若沒有立即生效，同樣是 `geodata/geodata-date.txt` 的比對問題），最後再重新提取一次元數據即可。

---

## 總結

**immich-geodata-zh-tw** 從 v3 開始，除了臺灣、日本與南韓，也加入了泰國與印尼的官方圖資，並導入國教院的官方臺灣譯名優化全球地名，讓亞洲旅遊照片的地點整理更貼近臺灣使用者的閱讀習慣。

如果你想知道這些地理資料是怎麼做出來的，包括 Immich 到底讀哪幾個檔案、各國圖資怎麼處理、地名怎麼翻譯與驗證，系列技術篇拆解了完整流程，可以從[反向地理編碼是怎麼運作的](/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)開始。

如果您覺得這個專案有幫助，歡迎到 [GitHub](https://github.com/RxChi1d/immich-geodata-zh-tw) 給我一顆星星 ⭐ 支持！

---

## 參考資源

- [專案 GitHub 倉庫](https://github.com/RxChi1d/immich-geodata-zh-tw)
- [GeoNames (全球基礎資料)](https://www.geonames.org/)
- [國土測繪中心開放資料 (臺灣)](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)
- [国土数値情報ダウンロード (日本)](https://nlftp.mlit.go.jp/ksj/)
- [admdongkor (南韓)](https://github.com/vuski/admdongkor)
- [COD-AB Thailand (泰國)](https://data.humdata.org/dataset/cod-ab-tha)
- [印尼地理空間資訊局 BIG (印尼)](https://www.big.go.id/)
- [國家教育研究院《外國地名譯名》](https://data.gov.tw/dataset/15211)
- [OpenStreetMap (全球輔助資料)](https://www.openstreetmap.org/)
