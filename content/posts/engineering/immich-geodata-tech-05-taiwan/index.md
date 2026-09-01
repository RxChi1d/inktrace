---
title: "Immich 繁體中文地理資料技術解析（五）：用官方圖資重建臺灣的行政區"
slug: "immich-geodata-tech-05-taiwan"
date: 2026-08-28T10:00:00+08:00
lastmod: 2026-08-31T22:21:53+08:00
description: "用國土測繪中心村里界圖資重建 Immich 的臺灣行政區：7,986 個代表點、座標系轉換與欄位對應，以及為什麼這個 handler 幾乎不做名稱加工。"
tags: ["immich", "gis", "taiwan", "open-data"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 6
---

[前一篇：用 Wikidata 翻地名](/posts/engineering/immich-geodata-tech-04-translation/)談的是沒有官方圖資可用時，翻譯要付出多少代價來換取可信度。這篇是相反的情況：**臺灣有完整、免費、定期更新的官方圖資**，處理流程因此可以簡單到近乎乏味，而這正是它最好的地方。

這篇同時是一個 handler 的完整走查。[流程篇](/posts/engineering/immich-geodata-tech-02-pipeline/)講過 `extract` 的固定管線與各國專屬的插入點，這裡看的是臺灣把那幾個點填成了什麼。

<!--more-->

## 原始資料的三個問題

Immich 預設的 GeoNames 資料用在臺灣，會遇到三個問題：

1. **國家名稱顯示不正確**：GeoNames 依 ISO 3166 標準，原始輸出是 "Taiwan, Province of China"。
2. **行政區層級缺失**：多數縣市名稱從缺，鄉鎮市區層級更是幾乎沒有。在板橋拍的照片只會顯示到「新北市」，甚至只顯示國家。
3. **點位密度不足**：GeoNames 的 `cities500` 只收錄人口超過 500 人的聚落點，臺灣的收錄密度不足以支撐「找最近點」的解析方式，照片常被標到隔壁鄉鎮。

第一個問題單獨處理（見[系列首篇技術文](/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)的 `en.json` 一節）。後兩個問題的根源是**資料本身不夠細**，所以解法只有一個：換一份夠細的資料。

## 資料來源：NLSC 村里界

專案採用**內政部國土測繪中心（NLSC）**的「村(里)界 (TWD97經緯度)」開放資料。

- **來源**：[國土測繪中心開放資料平台](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)
- **格式**：Shapefile
- **目前使用版本**：`1150624`（版本號是民國日期，即民國 115 年 6 月 24 日；下列數字皆以此版為準，NLSC 改版後會變動）
- **產出規模**：7,986 列，每一列是一個村里的代表點
- **授權**：政府資料開放授權條款第 1 版，可自由重製與衍生利用（須標示出處）

選村里界而不是鄉鎮界，是因為 Immich 用的是最近鄰查詢：**點位越密，被標到隔壁行政區的機率越低**。一個鄉鎮只給一個點，邊界附近的照片幾乎必然出錯；細到村里之後，同一個鄉鎮內散布數十個點，落點自然收斂。

![點位密度對比：GeoNames 原始資料點位稀疏，照片被標到隔壁鄉鎮；改用 NLSC 村里界的 7,986 個代表點後，照片落在正確的鄉鎮市區](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-05-taiwan/point-density-comparison.png "點位密度決定最近鄰查詢會落在哪個行政區")
{style="width:80%;"}

而村里界資料本身就帶有完整的上層名稱（縣市、鄉鎮市區、村里），所以行政區層級不需要另外拼裝。

## 座標處理：先投影，再算中心點

原始資料是地理座標（經緯度），但幾何中心點不能直接在經緯度上算，那等於把球面當平面用，緯度越高失真越大。

這裡有個容易混淆的地方：**TWD97 同時指一個地理座標系（以經緯度表示）與一組投影座標系（以公尺表示）**。NLSC 這份資料是前者，計算中心點時要轉成後者，兩者名字相同但單位不同。

處理流程是：

1. **讀取來源 CRS**：以 Shapefile 的 `.prj` 宣告為準，不預設固定代碼。來源沒有宣告 CRS 時直接中止並報錯，而不是猜一個。
2. **投影**：轉換到 TWD97 / TM2 zone 121（[EPSG:3826](https://epsg.io/3826)），單位是公尺。
3. **算中心點**：在投影平面上計算多邊形的幾何中心。
4. **轉回 WGS84**：[EPSG:4326](https://epsg.io/4326)，輸出經緯度。

座標四捨五入到小數 8 位（約 1.1 毫米），寫出時去除尾端多餘的 0。

已知限制：程式取的是幾何中心點，沒有額外做「保證落在多邊形內」的修正。狹長或凹形的村里（例如沿海、環狀行政區），中心點有可能落在邊界之外。實務上對 Immich 的最近鄰查詢影響有限，鄰近的村里代表點會接手，但這是這個做法本身的邊界條件。

離島、飛地這類 multipart 圖徵的處理值得一提：**臺灣採用合併後的面積加權中心點，一個村里恆為一列**。逐個 part 拆成多列的做法目前只在印尼啟用。印尼是群島國家，一個行政區可能散在數座島上，不拆會讓部分島嶼的定位嚴重偏移；臺灣的離島多半自成村里，沒有這個問題。

![代表點取法對比：由三座島組成的行政區若合併成單一代表點，該點會落在島與島之間的海面上，照片因此被標到很遠的位置；改為每個 part 各自取代表點後，照片落在正確的島上](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-05-taiwan/centroid-multipart.png "群島地形下，合併代表點會落在海上；逐 part 拆列則每座島各有代表點")
{style="width:70%;"}

## NLSC 欄位對應到 GeoNames 行政區層級

| GeoNames 層級 | NLSC 欄位 | 對應臺灣行政區 | 範例 |
| :--- | :--- | :--- | :--- |
| Admin1 | `COUNTYNAME` | 直轄市、縣、市 | 新北市、彰化縣、新竹市 |
| Admin2 | `TOWNNAME` | 區、鄉、鎮、縣轄市 | 板橋區、鹿港鎮、東區 |
| Admin3 | `VILLNAME` | 村、里 | 文化里、永安村 |

只讀這三個欄位，DBF 的各種型別統一轉成字串輸出。

> [!NOTE]
> `admin_3`（村里）只存在於專案的中介 CSV，用於追溯與除錯，**不會輸出到 Immich 使用的 `cities500`**。Immich 顯示的最細層級是 `admin_2`。村里資料的價值在於它提供了密集的代表座標，而不在於顯示。

中介 CSV 另有一個 `country` 欄位固定填「臺灣」，同樣僅供人工檢視。**Immich 實際顯示的國家名稱由國碼 `TW` 決定**，對應到 `i18n-iso-countries/langs/en.json` 裡的值，與這個欄位無關。這點在[系列第一篇](/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)談過。

來源 `VILLNAME` 為空的情形（多為離島未編組村里的圖幅）會寫入字串 `None`。注意這是四個字元的字串，不是空值，這是中介 CSV 沿用的既有寫法，用來區分「來源就是空的」與「欄位不存在」。現行資料共 206 列，其中連江縣佔 134 列。因為這欄不輸出，不影響顯示。

## 沒有翻譯，沒有修正

臺灣 handler 最特別的地方是它**幾乎不做任何加工**：

- 不套用 OpenCC 轉換。
- 不查詢國教院官方譯名。
- 不做任何名稱修正或驗證。

NLSC 給什麼就用什麼。只保留「裏」轉「里」的一次性字元修正與空值正規化，而這兩者在現行 NLSC 資料下實際上都不會生效。

這跟[前一篇談的 Wikidata 流程](/posts/engineering/immich-geodata-tech-04-translation/)形成強烈對比：那邊需要 P131 隸屬驗證、候選過濾、簡體字偵測、未翻譯清單逐筆比對，而這邊什麼都不需要，因為**資料來源本身就是權威**。行政區的官方名稱就是內政部說了算，不存在「翻得對不對」的問題。

處理流程能簡單到什麼程度，取決於資料來源的品質。這大概是整個專案最實際的一課。

## ID 配發

新增的資料列要併回 GeoNames 的 `cities500.txt`，因此 `geoname_id` 不能與既有資料撞號。

做法是先算出目前資料中的**全域最大 ID**，再從最大值加一往後配發，`admin1CodesASCII.txt` 與 `cities500.txt` 各自取得連續的 ID 區間。不寫死號碼區段的好處是，GeoNames 之後擴充資料時，新增的列也不會覆蓋到官方既有的點位。

## 替換後的臺灣定位精度

換掉資料之後，臺灣的照片可以穩定解析到「縣市 + 鄉鎮市區」層級，而不是只顯示到縣市或國家。這個結果來自兩件事：`admin_2` 直接取自 NLSC 的 `TOWNNAME` 官方欄位，不經任何推斷；代表點密度從 GeoNames 的聚落點提高到 7,986 個村里中心點，最近鄰查詢因此不容易落到隔壁鄉鎮。實際安裝與驗證步驟見[圖文安裝教學](/posts/container-platform/immich-geodata-zh-tw/)。

而整套處理邏輯，實際上只是「讀 Shapefile、轉座標系、算中心點、輸出三個欄位」。

## 換一個國家要動什麼

把臺灣這個案例反過來看，就是新增一個國家要做的事：

1. **在 `Country` enum 註冊**。這是「哪些國家有 handler」的唯一事實來源，CLI 的清單由它導出，不需要另外同步一份。
2. **選定座標策略**。臺灣用固定的 EPSG:3826，因為全島適用同一個投影帶；日韓走 dynamic UTM；泰國與印尼各自用 Albers。這個選擇取決於該國的經度跨幅與地形。
3. **寫欄位對應與名稱決定邏輯**。臺灣這一步異常簡單，三個欄位直接讀、名稱原樣採用；其他國家的複雜度都集中在這裡，[五個地區，五種答案](/posts/engineering/immich-geodata-tech-03-strategies/)談的就是這些取捨。

剩下的讀檔、投影計算、排序、輸出格式都由共用流程處理。所以「新增一個國家」的實際工作量，幾乎完全取決於該國的官方圖資有多乾淨、以及地名要不要翻譯。

---

## 參考資源

- [臺灣行政區處理邏輯](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/taiwan-admin-processing.md) - 專案的完整技術文件
- [國土測繪中心開放資料平台](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx) - 村(里)界圖資下載
- [GeoNames Administrative Division Codes](https://www.geonames.org/export/codes.html) - 行政區層級定義
