---
title: "Immich 繁體中文地理資料技術解析 (三)：Wikidata 智慧翻譯引擎"
slug: "immich-geodata-tech-03-translation"
date: 2025-11-30T10:15:00+08:00
lastmod: 2025-12-29T16:03:17+08:00
tags: ["immich", "wikidata", "sparql", "knowledge-graph"]
categories: ["Engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 4
draft: true
---

在上一篇架構設計中，我們介紹了如何透過官方圖資來處理地理資料。然而，並非所有國家都有完美的開放圖資，或是我們只需要對現有資料進行「翻譯」。這時，v2.2.0 引入的 **WikidataTranslator** 就成為了關鍵角色。本文將深入解析這個基於知識圖譜的智慧翻譯引擎。

<!--more-->

## 為什麼選擇 Wikidata？

傳統的翻譯方式通常依賴 Google Translate 或 LocationIQ 等 API。但對於「地名」這種特殊資料，這些通用 API 往往力有未逮：
1.  **缺乏上下文**：「中區」翻譯成英文是 "Central District"，但如果是韓國的中區，我們希望保留漢字「中區」或翻譯為對應的韓文發音，通用 API 難以區分。
2.  **同名地名**：全世界有無數個 "San Jose" 或 "Washington"。
3.  **成本與限制**：商業 API 通常昂貴且有配額限制。

Wikidata 作為一個結構化的知識圖譜，提供了完美的解決方案：
-   **P131 (位於行政區)**：明確指出該地點隸屬於哪個上級行政區。
-   **P31 (隸屬性質)**：區分這是「城市」、「村莊」還是「行政區」。
-   **多語言標籤**：擁有全球最豐富的地名多語言對照表。

---

## 核心技術：SPARQL 查詢與層級驗證

`WikidataTranslator` 的核心在於如何精準地找到對應的實體 (Item)。我們使用 SPARQL 查詢語言來與 Wikidata 溝通。

### 解決「同名地名」的挑戰
最困難的挑戰在於處理同名行政區。例如，南韓有許多個「中區」(Jung-gu)：
-   首爾特別市 中區
-   釜山廣域市 中區
-   大邱廣域市 中區
-   ...

如果只搜尋「Jung-gu」，我們無法確定是哪一個。因此，我們的查詢邏輯必須包含 **父層級驗證**。

### SPARQL 查詢範例
我們會建構類似以下的 SPARQL 查詢：

```sparql
SELECT ?item ?itemLabel ?adminLabel WHERE {
  # 1. 模糊搜尋地名 (例如 "Jung-gu")
  ?item rdfs:label ?label.
  FILTER(LANG(?label) = "en" && REGEX(?label, "^Jung-gu$", "i"))
  
  # 2. 驗證它位於目標父行政區 (例如 "Seoul" 的 QID: Q86)
  ?item wdt:P131+ wd:Q86. 
  
  # 3. 取得繁體中文標籤
  SERVICE wikibase:label { bd:serviceParam wikibase:language "zh-tw,zh-hant,zh,en". }
}
```

這個 `?item wdt:P131+ wd:Q86` 是最關鍵的一行。`P131+` 代表「遞迴查找上級行政區」，只要該地點的上級鏈中包含首爾 (Q86)，它就是我們要找的那個「首爾的中區」。

---

## 多層次翻譯回退策略 (Fallback Strategy)

為了提供最佳的繁體中文體驗，我們設計了嚴謹的語言回退機制。當我們請求 Wikidata 標籤時，順序如下：

1.  **zh-tw (臺灣繁體)**：最優先使用。
2.  **zh-hant (繁體中文)**：若無臺灣特有詞彙，使用通用繁體。
3.  **zh (中文)** + **OpenCC**：這是關鍵一步。Wikidata 上許多條目只有簡體中文 (`zh` 或 `zh-cn`)。我們獲取後，會自動透過 OpenCC 套件將其轉換為繁體中文。
4.  **en (英文)**：若完全無中文，回退至英文。
5.  **Source Language (原文)**：最後手段（如保留韓文原文）。

這確保了即使 Wikidata 資料不完整，使用者也能看到最接近繁體中文的結果，而不是空白。

---

## Context-Aware Cache (上下文感知快取)

由於 SPARQL 查詢速度較慢且對伺服器負擔大，快取 (Cache) 是必須的。但簡單的 `Key-Value` 快取（Key=地名）會出問題。

### 傳統 Cache 的問題
如果我們只用 `Jung-gu` 當 Key：
1.  查詢首爾的中區 -> 存入 `Jung-gu: 中區` (正確)
2.  查詢釜山的中區 -> 讀取 Cache -> 得到 `中區` (雖然文字一樣，但在某些語言或脈絡下可能不同，且失去了對應不同 QID 的機會)

更嚴重的是，如果兩個不同國家的同名城市，翻譯可能完全不同。

### 解決方案：Context-Aware Key
我們設計了包含父層級資訊的快取鍵：

`Key = {Level}/{CountryCode}/{ParentName}/{Name}`

例如：
-   `admin_2/KR/Seoul/Jung-gu` -> 對應 QID A
-   `admin_2/KR/Busan/Jung-gu` -> 對應 QID B

這確保了快取的 **隔離性**。即使地名拼寫完全相同，只要隸屬的父行政區不同，就會被視為不同的實體進行查詢與儲存。

---

## 總結

`WikidataTranslator` 不僅僅是一個翻譯器，它是一個 **地理實體解析器**。透過 Wikidata 強大的結構化資料與我們設計的驗證邏輯，它能夠精準地將全球各地的地名轉換為符合臺灣使用者習慣的繁體中文，同時避開了同名地名的誤區。

下一篇，我們將把焦點轉回 **臺灣 (TW)**，看看如何結合這些技術與 NLSC 官方圖資，打造最完美的在地化體驗。
