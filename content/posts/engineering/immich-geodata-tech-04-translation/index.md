---
title: "Immich 繁體中文地理資料技術解析（四）：用 Wikidata 翻地名，以及它如何安靜地出錯"
slug: "immich-geodata-tech-04-translation"
date: 2026-08-27T10:00:00+08:00
lastmod: 2026-08-31T22:21:53+08:00
description: "用 Wikidata 翻譯地名的六種已知失效形態：錯誤不會中斷流程，而是安靜地產出一個合法卻指向錯誤地點的中文名。含防護機制反噬的實際案例與驗證方法。"
tags: ["immich", "wikidata", "sparql", "knowledge-graph", "data-quality"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 5
---

[上一篇：五個地區，五種方案](/posts/engineering/immich-geodata-tech-03-strategies/)談到，泰國、印尼這類非漢字系統的地名只能走翻譯路線，而專案選擇的翻譯來源是 Wikidata。

這篇要談的不是「怎麼查」，SPARQL 查詢本身沒什麼難度。難的是：**Wikidata 翻錯的時候，通常不會有任何跡象**。流程不會中斷，日誌不會報錯，輸出是一個合法的中文字串，只是指向錯的地方。

<!--more-->

## 為什麼是 Wikidata

地名這種資料有幾個特性讓通用翻譯很難處理：

1. **同名地名到處都是**：南韓有首爾中區、釜山中區、大邱中區；泰國、印尼也都有大量重複的行政區名。翻譯 API 看不到上下文，無法區分。
2. **地名不是語意翻譯，是查表**：「Ngawi」該翻成什麼，取決於既有的中文慣用譯名，而不是字面意思。
3. **需要驗證管道**：翻出來的結果必須有辦法確認「這確實是那個行政區」，而不只是「這串字讀起來像」。

Wikidata 剛好補上這一塊。它是結構化的知識圖譜，每個地理實體都有：

- **[P131（located in the administrative territorial entity）](https://www.wikidata.org/wiki/Property:P131)**：明確指出隸屬的上級行政區。
- **P31（instance of）**：區分這是城市、行政區、車站還是機關。
- **多語言標籤**：包含 `zh-tw`、`zh-hant` 等中文變體。

有了 P131，就能用「上級行政區」來裁決同名問題：查「中區」時，額外要求它的 P131 鏈必須包含首爾（`Q86`），釜山的中區自然就被排除了。

```sparql
SELECT ?item ?itemLabel WHERE {
  # 直接綁定韓文原名，不要用 FILTER 掃全圖的 label（那樣幾乎必然逾時）
  ?item rdfs:label "중구"@ko.

  # 關鍵：驗證它確實位於首爾的行政區鏈上
  ?item wdt:P131+ wd:Q86.

  SERVICE wikibase:label { bd:serviceParam wikibase:language "zh-tw,zh-hant,zh,en". }
}
```

到這裡為止，一切看起來都很美好。

## 失敗是無聲的

實際跑下來會發現，這套流程的失敗有兩種，而且**兩種長得完全不一樣**：

**第一種：查不到實體，或所有候選都通不過隸屬驗證。**
結果是回退為來源原文，該地名維持未翻譯。這種其實是好結果，它會出現在未翻譯清單裡，一眼就能看到。

**第二種：選到了錯誤的實體，而那個實體通過了 P131 驗證。**
譯名會直接取自那個錯誤實體。這種最難察覺，因為輸出是一個合法的中文字串，不會出現在任何異常清單裡。

第二種的實例：首爾的 `관악구`（冠嶽區）曾經被輸出成「新林洞」。冠嶽區裡確實有個新林洞，新林洞的 P131 鏈也確實包含首爾，驗證完全通過。從資料上看不出任何問題，除非有人真的去比對每一個區名。

![Wikidata 地名翻譯的三種結果：驗證通過得到正確譯名、查不到則回退原文並出現在未翻譯清單、選到錯誤實體卻通過驗證則產出看不見的錯誤譯名](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-04-translation/wikidata-failure-paths.png "三條路徑中，只有回退原文是看得見的失敗")
{style="width:80%;"}

## 六種已知的出錯方式

以下是專案實際遇過並記錄下來的形態：

| 形態 | 案例 | 怎麼判別 |
| :--- | :--- | :--- |
| 搜尋選到錯誤實體 | `관악구` 選到區內的 `신림동`；`송파구` 選到地鐵站 `잠실역` | 候選的原文 label 與查詢名稱不相等 |
| 上游 label 停在舊制 | `여주시` 的中文 label 曾是升格前的「驪州郡」 | 行政層級後綴對不上（시→市、군→郡、구→區） |
| 宣稱是繁體，字形卻有誤 | `함평군` 的 `zh-tw` 把「咸」轉成「鹹」；印尼 Papua 的 `zh-hant` 直接殘留簡體「巴布亚」 | 人工抽查，或用簡體字白名單掃描 |
| 缺少 P131 敘述 | `영종구` 設區後一段時間內完全沒有 | 隸屬驗證失敗且查無敘述 |
| P131 被標為 deprecated | 印尼 `Kabupaten Ngawi` 隸屬東爪哇省的敘述曾被標 deprecated | SPARQL 的 [`wdt:` 前綴只走 best-rank statement](https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service/queries#Truthy_statements)，deprecated 等同不存在 |
| 我方的過濾規則誤殺正確候選 | 見下一節 | 正確實體根本不在候選結果裡 |

第五種特別值得注意，因為它完全違反直覺：`Kabupaten Ngawi` 的資料明明還在 Wikidata 上，只是被標記成 deprecated，而 `wdt:` 前綴只會走 best-rank 的敘述。對查詢來說，那條敘述等於不存在。

## 最諷刺的一種：防護機制自己製造錯誤

第六種形態是我們自己造成的。

為了避免搜尋選到機關單位（區公所、教育廳之類），原本的做法是關鍵字黑名單：逐一檢查候選實體取回的每個 label，含有「廳」、「所」這類字就剔除。

然後正確的 `관악구` 被剔除了，因為它的 `zh-hant` label 被機器人從中文維基的 infobox 匯入成「冠嶽區**廳**」，那是區公所的名稱，不是行政區的名稱。黑名單認得「廳」字，於是把唯一正確的候選踢掉，剩下的候選裡最接近的就是那個新林洞。

**黑名單式的排除規則永遠列不完**，而且會因為某個無關語言的 label 誤傷正確候選。南韓 handler 後來改成白名單式判定：候選的原文 label 必須與查詢名稱**完全相符**。機關、職位、選區、車站的名稱不會與行政區名完全相同，自然就落選了，而且不需要維護任何關鍵字清單。

> [!WARNING]
> 印尼的處理路徑目前仍保有類似的關鍵字比對機制，涵蓋範圍包含中文系 label 與維基條目標題，也就是當初誤殺 `관악구` 的同一個範圍。印尼目前沒有觀察到誤殺案例，但這是已知風險。

## 驗證方法論：不能只看總數

這些形態導出一條操作原則：**驗證資料時必須比對未翻譯名稱的完整清單，不能只看數量**。

實際案例：印尼從舊版圖資換到新版時，未翻譯的二級行政區數量維持 51 個，看起來毫無變化。逐筆比對才發現 `Kabupaten Ngawi` 掉出來了，同時另一個地名首次翻譯成功，剛好抵銷。

同樣地，未翻譯數量上升時也不能直接當成「上游新增了行政區」。上游新增行政區與譯名失效，在數字上的表現一模一樣。

## 快取：多層，而且會短路

SPARQL 查詢慢，快取是必須的。快取檔放在專案的 `geoname_data/{國碼}_wikidata_cache.json`（例如 `KR_wikidata_cache.json`），內部分成好幾層：

- `cache.search`：搜尋結果
- `cache.labels`：實體的多語言 label
- `cache.instance_of`：P31 類別
- `cache.p131`：隸屬關係驗證結果
- `translations`：最終的譯名決策

這裡有個實務上會踩到的坑。`translations` 命中時要同時滿足兩個條件：本次算出的上層 QID 與快取記錄相同，且該筆結果為翻譯失敗或已通過隸屬驗證。兩者都成立時，流程會**直接採用快取結果，完全不查 `cache.p131`**。

也就是說，修正了上游的 P131 敘述之後，只清 `cache.p131` 重跑，會發現什麼都沒改變，因為那一層根本沒被讀到。要重驗單一實體，`cache.p131` 與 `translations` 兩處都得清；改動的是候選篩選邏輯的話，直接用空快取重跑比較省事。

## 優先修正上游

最後是一個方向性的原則：**某個譯名錯誤如果源自 Wikidata 本身，優先去修 Wikidata，而不是在專案裡加一條對照表。**

修正上游對所有使用者都有效；對照表只對這個專案有效，而且要長期維護。南韓的例子在[上一篇](/posts/engineering/immich-geodata-tech-03-strategies/)提過：原本為了修上游錯誤而規劃的七條人工對照表，在改用韓文維基的漢字表記作為名稱來源之後，降到了零條。

翻譯這條路線的核心體悟大概就是這個：**能不翻譯的就不要翻譯，必須翻譯的就要有辦法驗證，驗證不過就老實回退到原文。** 一個看得出來沒翻譯的地名，遠比一個看起來很合理的錯誤譯名有價值。

## 參考資源

- [Wikidata 譯名的已知失效形態](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/wikidata-translation.md) - 專案的完整技術文件
- [Wikidata Query Service](https://query.wikidata.org/) - SPARQL 查詢介面
- [Wikidata P131](https://www.wikidata.org/wiki/Property:P131) - located in the administrative territorial entity

---

[下一篇：用官方圖資重建臺灣的行政區](/posts/engineering/immich-geodata-tech-05-taiwan/)回到臺灣，看看有官方圖資可用時，處理流程可以簡單到什麼程度。
