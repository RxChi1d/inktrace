# 圖片生成 prompt：immich-geodata-zh-tw 系列

> **⚠️ 此文件已停用，僅作歷史紀錄。不要照著它生成或調整任何圖片。**
>
> 現行規範在 `.claude/skills/blog-diagram-generation/`（SKILL.md ＋ 驗收腳本）。
>
> 這份只涵蓋三張圖，而系列實際有九張。**它記錄的 prompt 與目前線上的圖片不一定
> 對應**——多張已經重繪過。九張現行圖的逐字 prompt 在
> `~/Pictures/inktrace-diagrams/2026-08-31/image-review-handoff.md`（不在版控內）。

## 為什麼停用

原本開頭寫著「沿用 `image-prompts-immich-geodata-tech-01.md` 的統一風格指南
（soft 3D cards、圓角 16px、曲線箭頭帶微光⋯⋯）」。

那份風格指南現已停用：光澤 3D 卡片漸層搭配立體 stock 圖示（魔法棒代表 `enhance`、
掃把代表 `cleanup`）是「一眼 AI 生」的主要來源。判準是**這個圖示換掉會不會損失
資訊**——不會就是裝飾。

現行風格改為扁平、細彩色邊框、不使用任何裝飾性圖示，完整的 style lock 逐字內容
在 skill 裡。

另外這份使用的 API 參數假設也不成立：實際生成路徑是 `codex exec` 的
`image_generation` 工具，quality、size、background 全部無法設定。

---

以下為原始內容，保留供歷史對照。

## 目標路徑（Cloudflare R2）

CDN 慣例為 `inktrace-files/<category>/<slug>/<檔名>.png`。

| 圖 | 目標路徑 |
| :--- | :--- |
| 機制篇流程圖（重繪） | `inktrace-files/engineering/immich-geodata-tech-01-reverse-geocoding/immich-reverse-geocoding-flow.png` |
| 機制篇檔案關係圖（重繪） | `inktrace-files/engineering/immich-geodata-tech-01-reverse-geocoding/geonames-file-relationships.png` |
| 流程篇六階段圖（新增） | `inktrace-files/engineering/immich-geodata-tech-02-pipeline/release-pipeline-stages.png` |
| Wikidata 篇失敗路徑圖（新增） | `inktrace-files/engineering/immich-geodata-tech-04-translation/wikidata-failure-paths.png` |
| 臺灣篇點位密度圖（新增） | `inktrace-files/engineering/immich-geodata-tech-05-taiwan/point-density-comparison.png` |

機制篇兩張為重繪，原檔在舊 slug 目錄 `immich-geodata-tech-01-pipeline/` 底下，新圖請放到
新 slug 目錄，文章內的網址一併更新。

---

## 1. 流程篇：release 六階段管線圖

縱向或橫向流程圖，分成上下兩條線。

**上半部 `extract`**：五張並排的小卡片（🇹🇼 NLSC、🇯🇵 国土数値情報、🇰🇷 admdongkor、
🇹🇭 COD-AB、🇮🇩 BIG），各自以曲線箭頭指向一張標示「中介 CSV `meta_data/*.csv`」的卡片。
標題（中文）：「extract：各國官方圖資 → 中介 CSV」。

**下半部 `release`**：六個依序串接的階段卡片，箭頭由左至右：
`cleanup` → `prepare` → `enhance` → `locationiq` → `translate` → `pack`。
- `enhance` 卡片以較大尺寸強調，並用虛線接回上半部的中介 CSV 卡片，標註（中文）「併入各國資料」
- `prepare` 卡片旁標註「GeoNames」小圖示
- `locationiq` 卡片標註（中文）「僅非 handler 國家」，用不同色（#FF8A80）表示會呼叫外部 API
- 最右端輸出一個壓縮檔圖示，標籤 `release.tar.gz`

底部標註（中文）：「每個階段可單獨執行，或以 --pass-<stage> 跳過」。

比例 16:9。

## 2. Wikidata 篇：兩條失敗路徑圖

橫向流程圖，重點是**三個出口的視覺差異**。

起點卡片：「地名（韓文／泰文／印尼文）」→ `Wikidata 搜尋` → `候選過濾` → `P131 隸屬驗證`。

驗證後分出三條路徑：
1. **通過且實體正確**（綠色 #54D62C，粗線）→ 輸出卡片「正確的中文譯名」
2. **查不到或驗證失敗**（灰色，虛線）→ 輸出卡片「回退原文」，旁邊加一個眼睛圖示與
   標註（中文）「看得見：會出現在未翻譯清單」
3. **選到錯誤實體但通過驗證**（紅色 #E53935，粗線）→ 輸出卡片「錯誤的中文譯名」，旁邊加一個
   劃掉的眼睛圖示與標註（中文）「看不見：輸出是合法中文，不在任何清單裡」

第三條路徑加一個實際案例小標籤：`관악구 → 新林洞`。

底部標註（中文）：「失敗是無聲的」。

比例 16:9。

## 3. 臺灣篇：點位密度對比圖

左右並排的兩張地圖示意（臺灣北部局部輪廓即可，不需精確地理形狀）。

**左側**：標題（中文）「GeoNames 原始資料」。少量稀疏的點位（約 3-5 個），一張照片圖示
（含 GPS 標記）以虛線連到距離最近但明顯偏遠的點，標註（中文）「標到隔壁鄉鎮」。

**右側**：標題（中文）「NLSC 村里界（7,986 個代表點）」。密集的點位（約 40-60 個），
同一張照片圖示以短實線連到正下方的點，標註（中文）「落在正確的鄉鎮市區」。

兩側底部各放一個結果標籤：左「新北市」、右「新北市 板橋區」。

中央以細分隔線區隔，避免兩側混淆。比例 16:9。
