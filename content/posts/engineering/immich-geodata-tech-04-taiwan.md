---
title: "Immich 繁體中文地理資料技術解析 (四)：臺灣地理資料在地化實踐"
slug: "immich-geodata-tech-04-taiwan"
date: 2025-11-30T10:30:00+08:00
lastmod: 2025-12-29T16:03:17+08:00
tags: ["immich", "gis", "taiwan", "open-data"]
categories: ["Engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 5
draft: true
---

本系列文章第四篇將深入探討 **immich-geodata-zh-tw** 專案的核心：如何針對臺灣地區進行深度在地化處理。我們將分析原始資料的缺陷，並介紹如何利用 **國土測繪中心 (NLSC)** 的官方圖資，重建精確且權威的地理資訊。

<!--more-->

## 為什麼臺灣需要特別處理？

在使用 Immich（或其他基於 GeoNames 的地圖服務）時，臺灣使用者常會遇到三個主要問題：

1.  **「中國臺灣省」的標籤問題**：
    GeoNames 的資料庫基於 ISO 3166 標準，經常將臺灣標示為 "Taiwan, Province of China"。雖然可以透過翻譯修正，但根源在於資料結構。

2.  **行政區層級缺失**：
    原生資料往往只有「縣市」層級，缺乏「鄉鎮市區」的詳細資訊。例如，在板橋拍的照片只顯示「新北市」，而無法精確定位到「板橋區」。

3.  **地名準確度不足**：
    缺乏在地化的村里界資料，導致反向地理編碼（Reverse Geocoding）時，經常無法正確解析到最小行政單位。

為了根本解決這些問題，我們決定捨棄 GeoNames 的預設臺灣資料，改用 **中華民國國土測繪中心 (NLSC)** 的官方圖資。

---

## 核心解法：NLSC 官方圖資整合

### 1. 資料來源選擇
我們選用 NLSC 的 **村(里)界 (TWD97經緯度)** 開放資料。
-   **來源**：[國土測繪中心開放資料平台](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)
-   **格式**：Shapefile (.shp)
-   **優勢**：
    -   **權威性**：政府官方維護，邊界精準。
    -   **完整性**：包含從縣市、鄉鎮市區到村里的完整層級名稱。
    -   **更新頻率**：定期更新，反映最新的行政區劃變動（如升格、合併）。

### 2. 座標系統的挑戰與轉換
NLSC 提供的資料使用 **TWD97** 座標系統，而 Immich 需要的是 **WGS84**。

雖然兩者差異極小，但為了追求極致的中心點計算精度，我們採取了以下轉換策略：
1.  **投影轉換**：先將緯度轉換為投影座標系統 **TWD97 / TM2 zone 121 (EPSG:3826)**。
2.  **計算中心點 (Centroid)**：在投影平面上計算多邊形的幾何中心。這能避免在球面上計算中心點時因緯度造成的面積失真。
3.  **逆轉換**：將計算出的中心點轉回 **WGS84 (EPSG:4326)**。

這確保了我們生成的每個「村里」座標點，都精確位於其地理中心。

---

## 行政區層級重構 (Mapping Strategy)

GeoNames 的資料結構包含 `Country`, `Admin1`, `Admin2` 等層級。我們將 NLSC 的資料對應如下：

| Immich/GeoNames 層級 | NLSC 欄位 | 對應臺灣行政區 | 範例 |
| :--- | :--- | :--- | :--- |
| **Country** | (固定值) | 國家 | 臺灣 |
| **Admin1** | `COUNTYNAME` | 直轄市、縣、市 | 新北市、彰化縣、新竹市 |
| **Admin2** | `TOWNNAME` | 區、鄉、鎮、市 | 板橋區、鹿港鎮、東區 |
| **Admin3** | `VILLNAME` | 村、里 | 文化里、永安村 |

> [!NOTE] 去政治化處理
> 我們在程式碼中直接將 `Country` 欄位強制寫入為「臺灣」，這是解決 "Province of China" 顯示問題最直接且有效的方法。

### 關鍵修正：
-   **Country** 直接強制寫入「臺灣」，徹底解決 "Province of China" 的顯示問題。
-   **Admin2** 的補齊是本專案的最大亮點。現在 Immich 可以正確顯示「新北市 板橋區」，而不僅僅是「新北市」。

---

## 實作細節：`TaiwanGeoDataHandler`

在 v2.0 架構下，所有的處理邏輯都封裝在 `core/geodata/taiwan.py` 中。

```python
class TaiwanGeoDataHandler(GeoDataHandler):
    COUNTRY_CODE = "TW"

    def extract_from_shapefile(self, shapefile_path: str, output_csv: str):
        # 1. 讀取 Shapefile
        gdf = gpd.read_file(shapefile_path, encoding="utf-8")
        
        # 2. 座標轉換與中心點計算
        gdf = gdf.to_crs(epsg=3826)  # 轉為投影座標
        gdf["geometry"] = gdf.geometry.centroid
        gdf = gdf.to_crs(epsg=4326)  # 轉回 WGS84
        
        # 3. 欄位對應與資料清理
        # ... (略)
```

### 自動化 ID 分配
為了避免與 GeoNames 原有的 ID 衝突，我們為臺灣資料分配了專屬的 ID 區段（`92_000_000` 起）。這確保了即使 GeoNames 更新，我們自定義的臺灣資料也不會被覆蓋或錯亂。

---

## 結語

透過引入 NLSC 官方圖資，我們不僅解決了名稱顯示的政治正確問題，更將 Immich 在臺灣的地理定位精度提升到了「村里」等級。這對於整理旅遊照片（例如回顧某個特定老街或景點）非常有幫助。

下一篇，我們將把目光轉向東北亞，探討如何處理 **日本 (JP)** 與 **南韓 (KR)** 的地理資料，看看在「保留原文」與「完全翻譯」之間的取捨哲學。
