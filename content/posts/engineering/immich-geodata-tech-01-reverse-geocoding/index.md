---
title: "Immich 繁體中文地理資料技術解析（一）：反向地理編碼是怎麼運作的"
slug: "immich-geodata-tech-01-reverse-geocoding"
aliases: ["/posts/engineering/immich-geodata-tech-01-pipeline/"]
date: 2025-12-11T12:00:00+08:00
lastmod: 2026-09-01T10:16:47+08:00
description: "拆解 Immich 的離線反向地理編碼：容器啟動時匯入哪些 GeoNames 檔案、earthdistance 如何用最近鄰查詢從座標找出地名，以及為什麼替換這些檔案就能讓相簿顯示精準的繁體中文地名。"
tags: ["immich", "geodata", "geonames", "reverse-geocoding"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 2
---

每當你上傳一張照片到 Immich，系統就會自動標註拍攝地點，例如「臺北市信義區」、「東京都澀谷區」。這背後並非雲端 API 的功勞，而是一套完全離線運行的反向地理編碼（Reverse Geocoding）系統。

也因為它是離線的，[immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw) 這個專案才有存在的空間（實際安裝步驟見系列首篇的[圖文安裝教學](/posts/container-platform/immich-geodata-zh-tw/)）：Immich 從幾個純文字檔讀取地名，那麼換掉那幾個檔案，顯示出來的地名就會跟著換。

這篇是系列的技術篇第一篇，先把地基講清楚：Immich 查到一個地名時到底發生了什麼事、它讀的是哪幾個檔案，以及這個機制留下了哪些可以動手腳的空間。後續幾篇談的各國處理策略、翻譯與驗證，全部建立在這篇的基礎上。

<!--more-->

## Immich 的反向地理編碼是怎麼運作的

要知道這個專案能做什麼，得先看 Immich 這套機制長什麼樣。整套系統**完全依賴本機的離線資料庫，不呼叫任何雲端 API**。

整個過程分成兩個階段，發生在不同的時間點：

- **容器啟動時**：把幾份純文字的地理資料檔匯入 PostgreSQL，並建立空間索引。這一步只在資料內容有變動時才會重跑。
- **照片上傳時**：拿照片的 GPS 座標去資料庫裡找**距離最近的那個點**，讀出它的欄位值，組合成地址字串。

沒有比對邊界，沒有查詢外部服務，也沒有任何驗證步驟，就是找最近的點，然後把它的欄位抄下來。

![Immich 反向地理編碼流程圖](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-01-reverse-geocoding/immich-reverse-geocoding-flow.png "Immich 的兩個階段：容器啟動時匯入資料，照片上傳時以最近鄰查詢取得地名")
{style="width:80%;"}

### 查詢：從座標到地名

當你上傳一張帶有 GPS 座標（例如 25.033, 121.565）的照片時，Immich 會使用 **最近鄰查詢（Nearest Neighbor Query）** 從 20 萬筆資料中找出「臺北市信義區」。簡單來說，Immich 會：

1. 將照片的經緯度轉換為 3D 球面座標
2. 在 `geodata_places` 表格中尋找距離最近的地點
3. 提取該地點的 Country、Admin1、City 欄位
4. 組合成最終的地址字串

這是 Immich 實際的查詢邏輯（簡化版）：

```typescript {title="server/src/repositories/map.repository.ts"}
// 簡化後的查詢邏輯
this.db
  .selectFrom('geodata_places')
  .selectAll()
  .where(
    sql`earth_box(ll_to_earth_public(${point.latitude}, ${point.longitude}), ${reverseGeocodeMaxDistance})`,
    '@>',
    sql`ll_to_earth_public(latitude, longitude)`,
  )
  .orderBy(
    sql`(earth_distance(ll_to_earth_public(${point.latitude}, ${point.longitude}), ll_to_earth_public(latitude, longitude)))`,
  )
  .limit(1)
```

> [!INFO] 原始碼
> 這段邏輯位於 Immich 官方倉庫的 [map.repository.ts](https://github.com/immich-app/immich/blob/main/server/src/repositories/map.repository.ts)。本文以 2025 年底的 `main` 分支為準；Immich 改版時實作可能調整，連結刻意不指定行號以免失效。

關鍵函式說明：
- `ll_to_earth_public(lat, lng)`：將經緯度轉換為 3D 球面座標（基於地球橢球模型）
- `earth_box(point, radius)`：建立以該點為中心、指定半徑的搜尋範圍
- `earth_distance()`：計算兩點間的實際球面距離
- `reverseGeocodeMaxDistance`：搜尋半徑上限。超出這個距離內沒有任何地點時查詢會落空，照片就不會有地點資訊。這也是為什麼「增加資料密度」有意義

這個查詢會先用 `earth_box` 縮小搜尋範圍，再用 `earth_distance` 精確排序，最後返回距離最近的那一筆資料。

### 掌握了查詢邏輯，就能「動手腳」

看完 Immich 的查詢邏輯，你會發現一個關鍵：**整個反向地理編碼系統完全依賴 `cities500.txt` 和相關檔案的內容**。Immich 不會去驗證地名是否正確，也不會聯網查證資料，它只是單純地「找最近的點，讀取欄位值」。

這意味著，我們可以通過修改這份檔案的內容，做到：
- **增加資料密度**：在 `cities500.txt` 中加入更細緻的地點（如臺灣的村里、日本的市區町村）
- **改善地名品質**：將 `name` 欄位從英文替換為精準的繁體中文
- **優化翻譯邏輯**：處理簡繁轉換、異體字統一等問題

這正是 immich-geodata-zh-tw 的核心策略：**用各國的官方圖資重建這些檔案的內容，再替換掉 Immich 預設的版本**。

---

## Immich 讀的是哪幾個檔案

前面提到啟動時會匯入地理資料，實際上總共是四個檔案，主要來自 [GeoNames](https://www.geonames.org/) 這個開放地理資料庫（官方宣稱收錄超過 1100 萬個地理點位）。

| 檔案 | 用途 | 本專案怎麼處理 |
| :--- | :--- | :--- |
| `cities500.txt` | 地點座標與名稱的主資料 | 併入各國官方圖資產生的點位，並改寫地名 |
| `admin1CodesASCII.txt` | 一級行政區代碼對照名稱 | 同步替換為在地化名稱 |
| `i18n-iso-countries/langs/en.json` | 國碼對照國家名稱 | 內容整份換成繁體中文（見後文） |
| `geodata-date.txt` | 判斷要不要重新匯入 | 每次發布更新內容 |

以下逐一說明。

### admin1CodesASCII.txt：一級行政區名稱對照

格式：`國家代碼.行政區代碼 TAB 名稱 TAB ASCII名稱 TAB geoname_id`

例如：
```
TW.03    Taiwan Province    Taiwan Province    1668284
```

這個檔案用於將 `cities500.txt` 中的 `admin1_code` 轉換為實際的行政區名稱。

### cities500.txt：核心的地理座標資料庫

這是 Immich 反向地理編碼的「核心」，也就是 GeoNames 的 `cities500` 資料集，收錄人口 500 以上的聚落與行政中心，約 20 萬筆（數量隨 GeoNames 更新變動）。檔案採用 Tab 分隔格式（TSV），每一行代表一個地理位置點，包含 19 個欄位：

```
geoname_id  name  asciiname  alternatenames  latitude  longitude  feature_class  feature_code  country_code  cc2  admin1_code  admin2_code  admin3_code  admin4_code  population  elevation  dem  timezone  modification_date
```

Immich 會將這些資料匯入 PostgreSQL 的 `geodata_places` 表格。查詢時，系統依賴 `latitude`、`longitude` 定位最近的地點，然後從 `name`、`country_code`、`admin1_code` 等欄位組合出完整的地址。

### i18n-iso-countries/langs/en.json：國家名稱對照

Immich 使用這個檔案將國家代碼（如 `TW`）轉換為國家名稱。此外，Immich **固定讀取 `en.json`**，因此國家名稱的語言不會受介面語言的影響。

immich-geodata-zh-tw 利用這個特性，將 `en.json` 的內容替換為繁體中文（但 locale 仍保持 "en"），這樣 Immich 讀取時就會顯示「臺灣」而非「Taiwan」。詳細處理方式請見後文「國家名稱：一個繞過 Immich 限制的做法」章節。

### geodata-date.txt：判斷要不要重新匯入

這是一個單行文字檔，只包含一個時間戳。Immich 會把這個檔案的**內容**與資料庫中的 `reverse-geocoding-state` 紀錄比對，**兩者不同**時才重新匯入資料。

注意它比的是「內容是否相同」，不是檔案的修改時間，也不是日期的先後。因此要強制 Immich 重新匯入時，把內容改成任何不一樣的值都有效，改成更早的日期一樣會觸發。

> [!NOTE] 關於 `admin2Codes.txt`
> `admin2Codes.txt` 是二級行政區資料。本專案不對它做任何處理，只保留原檔以維持相同的檔案結構。實務上這樣就足夠，因為 Immich 顯示的地名欄位來自 `cities500.txt` 本身，並不使用 `admin2Codes.txt` 這份檔案。

![GeoNames 資料檔案關係圖](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-01-reverse-geocoding/geonames-file-relationships.png "GeoNames 核心檔案之間的關係：cities500.txt 透過 admin1_code 參照一級行政區對照表，國碼另外對應 en.json")
{style="width:80%;"}

## 國家名稱：一個繞過 Immich 限制的做法

地名（城市、行政區）的來源已經講完了，剩下國家名稱（`TW` → 「臺灣」）還沒交代。它完全不經過地理資料的處理流程，而是一個獨立的靜態檔案替換。

### Immich 的限制

前面介紹檔案清單時提過，Immich **固定讀取 `i18n-iso-countries/langs/en.json`** 來顯示國家名稱，即使使用者介面語言設為繁體中文也一樣。這是 Immich 的架構設計，我們無法從外部改變這個行為。

理論上，這意味著國家名稱永遠只會顯示英文：`Taiwan`、`Japan`、`South Korea`。

### 繞過的做法：改寫 en.json

但我們可以「騙過」Immich：**將 `en.json` 的內容替換為繁體中文**。

```json {title="i18n-iso-countries/langs/en.json"}
{
  "locale": "en",     // ← locale 仍是 "en"，Immich 看到這個就會讀取此檔
  "countries": {
    "TW": "臺灣",     // ← 但內容已經是繁體中文了！
    "CN": "中國",
    "JP": "日本",
    "KR": "南韓",
    "US": "美國",
    "GB": "英國"
    // ... 約 250 個國家與地區的繁體中文名稱
  }
}
```

這樣一來，Immich 讀取 `en.json` 時，實際上會得到繁體中文的國家名稱。使用者在相簿介面看到的位置資訊就會是「臺灣 · 臺北市 · 信義區」而非「Taiwan · Taipei City · Xinyi District」。

### 翻譯來源的權威性

為了保持翻譯名稱的正確性，這些繁體中文譯名參考臺灣政府公布的資料：

- 中華民國外交部公布的國家與地區名稱
- 經濟部國際貿易署的國家/地區名稱對照

完整的來源與授權聲明列在專案的 [NOTICE.md](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/NOTICE.md)。

並經過微調優化，以確保符合臺灣慣用的稱呼。例如：
- 使用「臺灣」而非「台灣」（遵循政府正式用字）
- 使用「南韓」而非「韓國」（臺灣媒體與日常的慣用說法）
- 使用「阿拉伯聯合大公國」而非「阿聯酋」（經貿署正式名稱）

> [!NOTE]
> 我們仍保留 `zh-tw.json` 作為國家名稱的繁體中文參考基準。

---

## 這些檔案是怎麼生出來的

看到這裡，機制的部分已經完整了：Immich 讀那幾個檔案、用最近鄰查詢找地名、把欄位組合成地址。剩下的問題只有一個：**那些檔案裡的內容從哪來**。

這些內容出自一支 Rust CLI，處理流程分成兩條線：

- **`extract`**：把某一個國家的官方圖資（Shapefile、GeoJSON 或官方 API 回應）轉成中介 CSV，內容是行政區名稱與計算好的代表座標。每個有專屬處理邏輯的國家各跑一次。
- **`release`**：把中介 CSV 併回 GeoNames 的原始檔，處理 ID 配發與翻譯，最後打包成 `release.tar.gz`。這條線由六個階段組成：`cleanup`、`prepare`、`enhance`、`locationiq`、`translate`、`pack`。

[下一篇](/posts/engineering/immich-geodata-tech-02-pipeline/)會完整拆解這兩條線：六個階段各自做什麼、為什麼每個都要能單獨執行、ID 怎麼配發才不會撞號，以及一條依賴付費 API 的流程要怎麼驗證。

---

## 參考資源

- [immich-geodata-cn README](https://github.com/ZingLix/immich-geodata-cn/tree/main/geodata#readme) - 詳細的 GeoNames 檔案格式說明
- [Immich Reverse Geocoding 原理分析](https://zinglix.xyz/2025/01/23/immich-reverse-geocoding/) - 同類專案作者對查詢機制的分析
- [GeoNames Documentation](https://www.geonames.org/export/) - 官方檔案格式文件
- [immich-geodata-zh-tw 專案文件](https://github.com/RxChi1d/immich-geodata-zh-tw/tree/main/docs) - 各地區處理方式與開發說明
