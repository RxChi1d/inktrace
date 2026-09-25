---
title: "Immich 繁體中文地理資料技術解析（二）：資料處理流程"
slug: "immich-geodata-tech-02-pipeline"
date: 2026-08-25T10:00:00+08:00
lastmod: 2026-09-25T12:42:09+08:00
description: "拆解 immich-geodata-zh-tw 的資料處理流程：extract 把各國官方圖資轉成中介 CSV，release 七階段併回 GeoNames、剪枝並打包成 release.tar.gz，並用 dry-run 與 fixture 驗證。"
tags: ["immich", "geodata", "geonames", "etl", "rust"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 3
---

[系列上一篇：反向地理編碼是怎麼運作的](/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)拆解了 Immich 怎麼讀地理資料：啟動時把幾個純文字檔匯入 PostgreSQL，照片上傳時用最近鄰查詢找出地名。既然換掉檔案就能換掉顯示結果，剩下的問題就落在那份「更好的檔案」本身。

這篇拆解 immich-geodata-zh-tw 的資料處理流程：從各國官方圖資，到使用者下載的那包 `release.tar.gz`。

<!--more-->

## 兩條線

整套流程分成兩條線，各自負責不同的事：

- **`extract`**：把某一個國家的官方圖資轉成中介 CSV。每個有專屬處理邏輯的國家各跑一次，彼此獨立。
- **`release`**：把所有中介 CSV 併回 GeoNames 的資料，翻譯、剪枝、打包成 release。七個階段依序執行。

`extract` 只服務有專屬處理器（handler）的國家，而要成為這種國家得同時滿足兩個條件：該國有可用的官方行政區圖資，而且專案裡寫了對應的處理邏輯去讀它。

其餘國家沒有 `extract` 這一步。但「沒有 `extract`」不等於「什麼都沒做」。發布出來的資料其實有三種精準度，差別在於該國經過了多少道處理。

**最精準是走 `extract` 的那五個國家。** 行政區名稱與代表點座標都由官方圖資重建，點位密度也跟著提高（臺灣細到村里層級）。代價是這個國家要有可用的官方圖資，而且得為它的資料格式寫一支處理器。

**中間一層是經過 `locationiq` 反查的國家。** 座標沿用 GeoNames 原本的點位，但每個點都會拿去反查一次，回傳的行政區層級會覆蓋掉原本的欄位。這一層的作用除了獲取中文的地名翻譯之外，也會用於修正「點的位置沒錯，但上游把它歸到錯的行政區、或名稱本身就寫錯」的情況。GeoNames 是全球資料庫，這類偏差並不少見。要走這一層，執行時得以 `--country-code` 指定該國並提供 API key。

**基準層是其餘所有國家。** 沒有被指定的國家就停在這裡，行政區歸屬與點位密度都維持 GeoNames 原樣，只有地名會在 `translate` 階段換成中文譯名。

換句話說，**要更準的資料就得付出更多處理**：什麼都不做就是基準層；願意花 API 額度反查，可以修掉上游的行政區錯誤；要再往上，就得找到該國的官方圖資，並為它寫專屬的處理邏輯。

`release` 執行時會檢查 `data/handler/` 底下有沒有該國的中介 CSV，據此決定它走哪一條路。`extract` 的產物直接進版控，而官方圖資不常更新，所以發布時只要讀現成的 CSV，不必每次重跑各國的圖資處理。

> [!NOTE] 資料目錄結構劃分
> 專案將中介產物依來源清楚分類，避免資料流向混淆：
> - `data/handler/`：由各國官方圖資經 `extract` 萃取的中介 CSV。
> - `data/locationiq/`：非 handler 國家的 LocationIQ API 查詢快取與取值設定。
> - `data/vendor/`：外部靜態相依資料（如國家代碼與名稱對照庫）。

![immich-geodata-zh-tw 的資料處理流程：extract 把五個地區的官方圖資轉成中介 CSV，release 階段將其併回 GeoNames、剪枝並打包成 release.tar.gz](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1790309029196_release-pipeline-stages.svg "兩條線：extract 產生中介 CSV，release 七階段併回 GeoNames、剪枝並打包")
{style="width:90%;"}

## 第一條線：`extract`

輸入是各國官方圖資，輸出是一份中介且固定格式的 CSV：

```bash
cargo run --release -- extract --country TW \
  --shapefile <NLSC 村里界圖資路徑>
```

輸出的 CSV 每一列是一個行政區單位，包含各層級名稱與計算好的代表座標。以臺灣為例，7,986 列，每列是一個村里。如此可以在 `release` 階段把它併回 GeoNames 的 `cities500.txt`，取代原本的點位與行政區欄位。

**各國的差異全部集中在這一步**：臺灣直接讀 [NLSC 村里界圖資](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)的三個欄位；日本要判斷普通市、政令指定都市與郡轄町村；南韓要取韓文維基的漢字表記；泰國與印尼要跑 Wikidata 查詢與 P131 隸屬驗證。這些處理邏輯是系列後續幾篇的主題，這裡先當作黑箱。

座標計算則是共通的：先投影到適合該國的座標系統算幾何中心，再轉回 WGS84。理由是經緯度上算中心點會失真，這點在[臺灣篇](/posts/engineering/immich-geodata-tech-05-taiwan/)會細講。

### 一個 handler 實際負責什麼

雖然各國差異很大，`extract` 內部其實是一條固定的管線，各國專屬的處理器只需要在管線中的特定位置提供對應的資料處理邏輯：

- **`load_context`**：載入該國需要的對照表與快取。臺灣不需要，泰國與印尼要準備 Wikidata 查詢的環境。
- **`apply_country_centroids`**：依該國指定的 `centroid_pipeline` 投影後計算中心點。臺灣走固定的 EPSG:3826，日韓走 dynamic UTM，泰國與印尼各自使用 Albers 投影。
- **`rows_from_features`**：欄位對應與名稱決定。臺灣只讀 `COUNTYNAME`、`TOWNNAME`、`VILLNAME` 三個欄位。

其餘部分，包含讀檔、解析 feature、排序、座標四捨五入、寫出統一欄位的 CSV，為所有國家共用。另外還有一個條件性的 `split_parts`（multipart 逐 part 拆列），目前只有印尼啟用。

![extract 的內部管線：輸入圖資、讀檔解析 feature、load_context、split_parts、apply_country_centroids、rows_from_features、sort round write，最後輸出統一欄位的中介 CSV；其中 load_context、apply_country_centroids、rows_from_features 三個階段是各國專屬，split_parts 為條件性階段目前僅印尼啟用](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1789126746154_extract-handler-architecture.png "灰色階段所有國家共用，珊瑚色階段是新增一個國家時要實作的部分")
{style="width:90%;"}

至於「哪些國家有 handler」，則寫在 `Country` enum 裡。`Country::ALL` 是唯一的事實來源，CLI 的清單由它導出，新增國家時不需要、也不能另外同步一份。

如果想要了解一個完整的 handler 長什麼樣子，可以參考[臺灣篇](/posts/engineering/immich-geodata-tech-05-taiwan/)從頭到尾走過一次。

## 第二條線：`release` 的七個階段

```bash
cargo run --release -- release \
  --locationiq-api-key "YOUR_API_KEY" \
  --country-code "MY"
```

這一條指令會依序跑完七個階段：

| 階段 | 做的事 |
| :--- | :--- |
| `cleanup` | 清空並重建 `output/` 目錄 |
| `prepare` | 從 GeoNames 下載 `cities500.txt`、`admin1CodesASCII.txt` 等原始檔 |
| `enhance` | 依地點類別白名單收錄，併入各國中介 CSV，配發 `geoname_id`，輸出 `*_optimized.txt` |
| `locationiq` | 為指定國家擴充中文譯名，並透過反向地理編碼校正交界處標錯的行政區 |
| `translate` | 套用官方譯名與中文別名，產出翻譯後的檔案 |
| `prune` | 發布前剪除多餘地名點，透過幾何證明在保證查詢結果完全不變的前提下精簡點位 |
| `pack` | 打包成 `release.tar.gz` 與 `release.zip` |

每個階段都可以單獨執行，也可以用 `--pass-<stage>` 跳過。

### `cleanup`：冪等性的起點

這個步驟的作用很單純，即清空並重建 `output/` 目錄，以確保每次執行都從乾淨狀態開始。

### `prepare`：下載原料

從 [GeoNames](https://www.geonames.org/export/) 抓三份原始檔：`cities500.txt`（聚落與行政中心原始檔）、`admin1CodesASCII.txt`（一級行政區代碼對照名稱），以及 `admin2Codes.txt`（二級行政區，本專案不處理，只是保持檔案結構完整）。

已存在的檔案預設跳過，不重複下載。`cities500.txt` 解壓後有數百 MB，重跑流程時這一步的快取相當有感。

在收錄條件上，專案全面改依 **GeoNames feature class 白名單**（P 類聚落點、AU PPLX、A 類行政區）收錄，取代早期以人口門檻過濾的做法，避免許多人口欄位為 0 或空白的真實聚落被誤殺，同時將已廢棄、已毀與歷史地點（如 PPLH、PPLQ、PPLW）排除。

### `enhance`：核心階段

這一步把兩件事併在一起：

1. **併入各國資料**：讀取 `data/handler/` 底下的中介 CSV，把有專屬處理邏輯的國家（handler）資料寫進 `admin1CodesASCII.txt` 與 `cities500.txt`，取代 GeoNames 原本那些點位。
2. **配發 ID**：新增的資料列不能跟既有的 `geoname_id` 撞號。

實際上，Immich 內部並不會驗證 `geoname_id` 的正確性亦不會記錄（只會記錄反解後的地名名稱），但是內部查詢時，城市需要與對應的 admin 1 配對，因此需要確保 ID 不會重複，並且正確配對。

為了做到這點，程式先算出目前資料中的**全域最大 ID**，再從最大值加一往後配發，`admin1CodesASCII.txt` 先取一段，`cities500.txt` 接著往下取。不寫死號碼區段的好處是，GeoNames 之後擴充資料時，新增的列也不會覆蓋到官方既有的點位。

此外，針對 GeoNames 既有多筆資料共用完全相同座標的情況，去重邏輯採用**單一 tie-break：固定保留最小 `geoname_id` 者**，徹底解決以往人口與 ID 雙條件同時落空導致「整組地名被丟棄」的缺陷，成功復原了 50 個原本消失的地名。

![geoname_id 配發示意：GeoNames 既有資料佔用到全域最大值，admin1CodesASCII 的新增列從最大值加一開始配發，cities500 的新增列接續其後，右側留白表示 GeoNames 之後擴充也不會撞號](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1789126745601_geoname-id-allocation.png "新增列從當下的全域最大值往後配發，不寫死號碼區段")
{style="width:70%;"}

輸出是 `cities500_optimized.txt` 與 `admin1CodesASCII_optimized.txt`。

### `locationiq`：擴充中文譯名與校正邊界行政區

這一階段**只處理執行時明確指定的國家**，不是對全球資料通用。要納入的國家得在指令裡以 `--country-code` 列出（可以給多個），而且會自動排除掉已經有專屬處理器的那五個，因為它們的資料在 `extract` 就處理完了，沒必要再花 API 額度。若指定的國家清單全部為 handler 國家，流程會自動跳過此階段。

指定之後，該國每個地點的座標都會送去 LocationIQ 進行逆地理編碼（Reverse Geocoding），回傳的資料會覆蓋原本 GeoNames 的欄位。表面上看這只是一次外部 API 查詢，但實際上它承擔了兩項最關鍵的任務：

1. **大幅擴充中文地名來源（更多的中文化）**  
   GeoNames 雖然收錄了龐大的全球點位，但其附帶的中文別名資料庫（`alternateNamesV2.txt`）其實非常有限，大量二、三級城鎮或景點只有英文或拼音。由於請求 LocationIQ 時會帶上 `accept-language: zh,en` 標頭，能直接借力 OpenStreetMap（OSM）背後龐大且持續維護的全球在地化社群資料，一口氣取得大量上游原本欠缺的高品質中文地名與行政區譯名，為後續的 `translate` 階段注入最優先採用的中文候選原料。

2. **校正交界處的行政區歸屬（解決標記錯誤）**  
   GeoNames 原生資料主要由離散的點狀聚落構成，**當點位座標剛好位於兩個行政區的交界或模糊地帶時，上游資料庫容易出現行政區標記錯誤**（例如將 A 縣市邊界的景點誤歸為鄰近的 B 縣市）。透過 LocationIQ 重新做反向地理編碼，能利用外部地理資料庫的空間解析能力重新判定該座標的歸屬：
   - **自動修正邊界上的一級行政區（`admin1_correct`）**：當 GeoNames 記載的一級行政區與 Natural Earth、LocationIQ 兩者共識指向另一個行政區時，程式會自動更正，並於 `data/locationiq/{國碼}_admin1_fixes.csv` 留下審核紀錄。
   - **城市名可依國家自訂取值層級**：透過 `data/locationiq/address_fields.json` 配置（亦可透過 `--locationiq-address-fields` 指定），各國能精準對應最適合顯示的層級。例如馬來西亞改為固定取 `district`（daerah 縣級），徹底解決原本同一區域內村莊、小鎮、英里樁或建案名稱混雜跳躍的問題。

這裡是整條流程唯一會被外部服務卡住的地方。LocationIQ 有每日請求上限，而一個國家可能有上萬個地點要查，所以流程設計成可以中斷後續跑：

- 查詢進度記錄在 `data/locationiq/<國碼>.csv`，已查過的座標會自動跳過。
- 查詢速率改以服務的每分鐘上限進行嚴格節流；若撞到每日上限，會保存已查結果並正常結束，容許後續步驟繼續打包。
- 超過當日限制時，換 API key 或隔天重跑同一條指令即可。
- 加上 `--pass-cleanup` 保留 `output/` 既有的中間產物，省去重新下載與前處理。

### `translate`：決定每個地名最後顯示什麼

有專屬處理器的國家在 `extract` 階段就定案了，不走這裡。其餘地名的中文可能來自好幾個地方，這一階段的工作是決定採用哪一個。

候選來源依序是：

1. **LocationIQ 反查回來的名稱**。前一階段送出請求時就帶了 `accept-language: zh,en`，所以拿回來的行政區名稱本身可能已經是中文。
2. **從 GeoNames 別名檔篩出的中文名**。`prepare` 下載的 `alternateNamesV2.txt` 收錄各語言別名，程式篩出中文條目並依 `zh-Hant` → `zh-TW` → `zh-HK` → `zh` → `zh-Hans` → `zh-CN` → `zh-SG` 排定優先序，產生 `alternate_chinese_name.csv` 供查表。這是每次執行重新產生的中間產物，不是人工維護的清單。
3. **`cities500.txt` 自帶的 `alternatenames` 欄位**。上一項沒命中時的最後一道中文來源；同一個地點常有數十個別名，程式從中挑出中文的那個。

拿到候選之後，再由 **[國家教育研究院《外國地名譯名》](https://data.gov.tw/dataset/15211)** 做最後一層裁決：信心足夠時直接覆寫既有名稱，信心不足就只在原本沒有中文名時補洞，遇到有疑慮的匹配則保留既有結果。三種情況在日誌裡分別統計，方便發布前檢查這一層改了多少東西。

全部落空的話就保留原文。冷門地點在 Immich 裡仍然可能顯示英文，這是刻意的。

![translate 階段的決策流程：依序嘗試 LocationIQ 名稱、alternateNamesV2 篩出的中文、cities500 的 alternatenames 欄位，候選經 OpenCC 判定是否需要轉繁，再由國教院譯名裁決覆寫、補洞或保留既有，全部落空則保留原文](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1789126762163_translate-decision-flow.png "三個候選來源、OpenCC 判定與國教院裁決的先後關係")
{style="width:90%;"}

輸出是 `cities500_translated.txt` 與 `admin1CodesASCII_translated.txt`。

#### OpenCC 不是拿來無腦轉繁的

由於在前面的步驟中所查詢得到的中文名稱可能包含簡體中文，因此我們會在這個步驟中儘量將中文都轉換成繁體中文。然而 **不是拿到中文就轉**，轉換前會先判定。程式同時準備了簡轉繁（s2t）與繁轉簡（t2s）兩個方向，靠來回轉換的結果比對來判斷一個字串目前是什麼：

- `text == t2s(text)` → 這串字已經是簡體，才呼叫 s2t 轉成繁體
- `text == s2t(text)` → 這串字已經是繁體，原樣保留、不動它

從 `alternatenames` 挑候選時也照這個規則：**已經是繁體的優先直接採用**，只有簡體候選才需要轉換。

之所以要在轉換之前先進行檢查，是因為無條件套用簡轉繁會改壞本來就正確的字。由於有些簡體中文可以同字但表示不同的意思，但繁體中文會使用兩個不同的字來表示不同的意思，這就會導致當這個詞被判斷成簡體字，無條件轉換時，會誤改一些本來就正確譯名（「里」變「裏」、「占」變「佔」這類過度轉換）。

### `prune`：發布前剪除多餘地名點

這是發布管線中的關鍵階段，位於 `translate` 之後、`pack` 之前。

#### 為什麼需要剪枝

隨著專案引入各國高精度官方圖資，`cities500.txt` 迅速膨脹至將近 49 萬列（僅日本與印尼就佔了超過 23 萬列）。這帶來了三個沉重負擔：
1. **資料庫體積**：PostgreSQL 的 `geodata_places` 表與空間索引膨脹至 220 MB 以上。
2. **查詢延遲**：Immich 對每張照片都要查一次最近鄰。在日本等密集區，平均每次查詢都要在 25 公里半徑內掃描 242 列，而這些點大多是「同一個行政區內的不同代表點」——無論選到哪一個，回傳的縣市名稱完全一樣。
3. **下載體積**：解壓縮後的純文字檔達 64 MB。

**剪枝的目標就是在保證所有查詢結果 100% 不變的前提下，刪除多餘的重複點位。**

#### 證明不了就保留

Immich 的反向查詢底層使用的是 PostgreSQL 的 `earth_box(ll_to_earth_public(lat, lng), 25000)`。**`earth_box` 建立的是地心直角座標系下的軸對齊立方體，而不是球面圓盤！** 這意味著正北 25.5 公里的點在盒外，而切向對角線 28.3 公里的點反而仍在盒內。任何單純的「最近鄰替換」推論都無法保證 SQL 查詢行為不變。

![立方體與圓盤的差異：切向 28.3 公里仍在盒內，軸向 25.5 公里的點在盒外](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1789972120643_pruning-box-vs-disc.svg "earth_box 立方體與球面圓盤的差異")
{style="width:60%;"}

因此，剪枝器採用嚴格的「證明不了就保留」原則，對每個候選點 $p$ 證明：**刪掉 $p$ 後，所有可能受影響的查詢位置，回傳的行政區名稱均不變**：
- **T0（局部同一性）**：候選點 $p$ 的所有 Delaunay 三角網格鄰居必須屬於同一行政區。
- **T1（區域覆蓋性）**：受影響區域 $R_p$ 內的每一處，在刪除 $p$ 後仍被其他同名點的 25 公里範圍覆蓋。
- **T2（邊界一致性）**：在超出 25 公里邊界而回退 Natural Earth 國名時，結果依然與原先完全一致。

![T0、T1、T2 三個判準的分工](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1789971954140_pruning-three-tiers.svg "T0、T1、T2 三層證明架構")
{style="width:80%;"}

為了驗證連續區域，程式採用**心射投影（gnomonic projection）**進行遞迴四分細分。心射投影能將大圓映射為直線，確保多邊形具備測地凸性，從而可以安全地用區域角點界定整體區間。

![遞迴細分：整塊、切四塊、再切四塊，未解區域逐步縮小](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1789972129175_pruning-subdivision.svg "心射投影下的遞迴四分細分")
{style="width:75%;"}

此外，T0 的論證需要鄰居存活，如果同時刪除相鄰點位論證就會失效。因此單趟只能刪除兩兩不相鄰的「最大獨立集」（Maximal Independent Set），每趟刪除後重新計算球面 Delaunay 鄰接並重新證明，實際經 **20 趟迭代收斂**才完成完整剪枝。

![多趟獨立集刪除：每趟刪掉互不相鄰的一組點，重建圖後再刪一組](https://images.rxchi1d.me/file/inktrace/engineering/immich-geodata-tech-02-pipeline/1789972134954_pruning-multipass.svg "多趟獨立集反覆迭代刪除")
{style="width:72%;"}

#### 剪枝成效

實測結果（細分預算 2048、多趟迭代收斂）：
- **列數減少 33.5%**：全球點位由 487,372 點降至 324,296 點（淨刪除 163,076 點）。
- **體積與索引縮減**：解壓後 `cities500.txt` 減少 25.2%（47.8 MB），PostgreSQL `geodata_places` 表與索引減少 25.8%（164 MB），GiST 空間索引亦減少 46.1%（41 MB）。
- **查詢速度提升 3 倍**：密集地區反向地理查詢平均延遲由 3.36 ms 降低至 1.15 ms（**降幅達 66%**，p50 降至 0.63 ms）。
- **零差異驗證**：在真實 PostgreSQL 進行 635 萬個探測點的差分測試，比對 `(country, state, city)`，**標籤改變數為 0，新增空結果數為 0**。
- **稀疏地區天然保護**：加拿大、俄羅斯等原本點位稀疏的國家，因無法滿足 T1 證明而全數保留（59 個產生候選的國家中，僅 6 個密集國家有刪除點），完全不需要維護人工國家白名單。

剪枝為 release 流程預設步驟，亦可透過 `--pass-prune` 跳過，或以 `cargo run --release -- prune` 單獨執行。

### `pack`：打包

把剪枝與翻譯後的檔案、`data/vendor/i18n-iso-countries/`（國家名稱對照，見[反向地理編碼是怎麼運作的](/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)）、`LICENSE`、`NOTICE.md` 整理成 release 目錄結構，寫入 `geodata-date.txt`，最後產出 `release.tar.gz` 與 `release.zip`。

這包就是安裝腳本 `update_data.sh` 下載的東西，目錄結構直接對應安裝時要放進 Immich 的位置。

## 不呼叫外部服務的驗證方式

這條流程的麻煩之處在於，它同時依賴網路下載與付費 API，不可能每次改動都跑一次完整流程來驗證。因此 CLI 提供兩種驗證模式：

**dry-run**：驗證 release 的階段編排，不下載資料也不呼叫 API。

```bash
cargo run -- release --dry-run \
  --locationiq-api-key "fixture" \
  --country-code "KR" "TH" \
  --batch-size 100 --locationiq-qps 2
```

`--batch-size` 與 `--locationiq-qps` 是 `locationiq` 階段的節流參數（每批查詢筆數、每秒請求數）。dry-run 不會真的發出請求，帶上它們只是為了讓編排走過同一條路徑。

**fixture mode**：用本地的固定測資產生一份 smoke artifact，用來驗證 release 壓縮檔與 `update_data.sh` 需要的目錄結構是否正確。

```bash
cargo run -- release --fixture-mode \
  --pass-locationiq \
  --output-folder /tmp/rust-release-smoke
```

正式發布與 nightly 的 workflow 都走真實流程，但會先跑 fixture release smoke 當前置檢查。

> [!NOTE] 這套階段劃分不是 Rust 版才有的
> 六階段從 v2 的 Python + Polars 時代就存在，v3 改寫為 Rust 之後階段名稱與職責大致沿用；後來為了解決圖資擴充帶來的資料庫膨脹與查詢延遲問題，正式加入了第七個階段 `prune`，在不影響輸出結果的前提下大幅精簡資料。
> 其中比較有意思的一項是各國處理邏輯的註冊方式：Python 版用 registry 自動註冊，handler 類別定義好就會被掃到；Rust 版刻意改成 enum 與 static dispatch 的明確註冊，新增國家時必須同步修改 CLI 的國家解析與 dispatch。多寫那幾行，換掉的是「release 行為取決於 runtime 掃描到什麼」。發布流程產出的是所有使用者會下載的資料，這種地方的動態魔法出問題時很難查。

---

[下一篇：五個地區，五種方案](/posts/engineering/immich-geodata-tech-03-strategies/)進入各國的處理邏輯：同一套流程之下，五個地區為什麼會得出五種不同的顯示策略。

## 參考資源

- [本地資料處理](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/development.md) - 各國 extract 指令與完整流程的操作說明
- [地名點剪枝說明文件](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/point-pruning.md) - prune 階段的完整幾何證明與差分測試細節
- [City 層級選擇條件](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/city-level-criteria.md) - 各國城市名層級的裁定判準
- [GeoNames Documentation](https://www.geonames.org/export/) - 原始資料的檔案格式
- [LocationIQ Documentation](https://locationiq.com/docs) - Reverse Geocoding API
