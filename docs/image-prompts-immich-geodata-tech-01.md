# 圖片生成 prompt：Immich 繁體中文地理資料技術解析（一）

> **⚠️ 此文件已停用，僅作歷史紀錄。不要照著它生成或調整任何圖片。**
>
> 現行規範在 `.claude/skills/blog-diagram-generation/`（SKILL.md ＋ 驗收腳本）。
>
> 下面保留的 prompt 屬於最早一代配圖，**與目前線上的圖片沒有對應關係**——那幾張
> 已經重繪過。內容留著只為了對照風格演變。

## 為什麼停用

這份 prompt 有兩類已知會產生問題的指示，照做會重現它們。

**風格指示會生出「一眼 AI 生」的圖**

- `soft 3D cards`、`gentle gradients`、`glow`：光澤 3D 卡片漸層
- `Small sparkles ✨`、`location pins 📍`、`gentle floating particles`：純裝飾元素
- `PostgreSQL elephant logo`、`Magnifying glass over mini 3D globe`：立體 stock 圖示

判準是：**這個圖示換掉會不會損失資訊？** 不會，就是裝飾，也就是 AI 味的來源。

**內容指示本身有事實錯誤**

- `PostGIS spatial index icon`、`PostGIS finding nearest point`：本專案的最近鄰
  查詢走 `earthdistance`，不是 PostGIS
- `"TW → 台灣"`：專案慣例用「臺」不用「台」
- `admin2Codes.txt` 畫了從 `admin2_code` 過來的連線：本專案不處理 admin2，原檔保留不動
- `"讀取 geodata-date.txt 時間戳"`：Immich 比對的是檔案內容是否相同，不是時間戳

原本開頭那條待辦（判斷框應改為「內容與資料庫紀錄不同？」）**已經完成**，線上版本
正確，不需要再處理。

---

以下為原始內容，保留供歷史對照。

本檔保存文章配圖的 AI 生成 prompt。原先內嵌於文章的 HTML 註解，但 `config/_default/markup.toml` 設定 `unsafe = true`，註解會原封輸出到頁面原始碼，因此移出。

```text
AI Image Prompt:

=== UNIFIED STYLE GUIDE (apply to all 4 images) ===
- Visual style: Modern tech blog illustration with soft 3D cards, gentle gradients, rounded corners (16px radius)
- Color palette: Soft blue (#6B9BD1), warm coral (#FF8A80), purple accent (#9C27B0), gentle green (#54D62C)
- Shadows: REQUIRED - All cards must have soft drop shadows (blur 20px, opacity 15%, offset 0 4px)
- Typography: Clean sans-serif, use rounded containers for labels
- Arrows: Always smooth Bezier curves with subtle glow (glow: opacity 30%, blur 8px), never straight lines
- Background: **CRITICAL** - Must be almost white/neutral with BARELY visible pattern (opacity 3-5% maximum). The pattern should be nearly invisible.
- Decorative elements: Small sparkles ✨, location pins 📍, gentle floating particles (all with low opacity)
- Overall feel: Warm, approachable, developer-friendly (think Stripe/Vercel style)

**IMPORTANT: All labels and annotations in Traditional Chinese. Technical terms (field names, parameters, code) stay in English.**

=== IMAGE 2: Immich Reverse Geocoding Flow ===

Vertical flowchart (top to bottom), soft 3D cards connected by curved glowing lines:

**Step 1: 容器啟動** 🚀
- 3D card with soft blue background (#6B9BD1)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Icon: Docker container with small sparkle
- Clock icon with file symbol
- Label (Chinese): "讀取 geodata-date.txt 時間戳"
- Curved glowing arrow pointing down →

**Step 2: 判斷決策** ❓
- Rounded diamond shape (soft yellow/amber #FFC107, lighter tint)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Question text (Chinese): "內容與資料庫紀錄不同？"
- Two paths branching out:
  * Left path - thick curved line with glow: "是 ✓" (gentle green color)
  * Right path - thin dashed curved line: "否 ✗" (gray, skip to step 4)

**Step 3: 資料匯入階段** 📥
- Large 3D expandable card (warm coral #FF8A80 background)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Header (Chinese): "資料匯入階段"
- Inside card content:
  * Small code preview: "cities500.txt" with tab-separated fields
  * Flowing arrow with badge: "200,000 records"
  * Table label: "geodata_places"
  * PostgreSQL elephant logo (cute, receiving data)
  * PostGIS spatial index icon (grid/map overlay)
- Curved glowing arrow pointing down →

**Step 4: 容器就緒** ⏸️
- Small 3D card (gentle green #54D62C)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Checkpoint flag icon
- Label (Chinese): "容器就緒"

--- Visual separator: soft dotted line with small cloud bubble ---
- Text in bubble (Chinese): "稍後..."
- Time indicator icon (clock with pause)

**Step 5: 使用者上傳照片** 📸
- 3D card (purple accent #9C27B0)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Icon: Illustrated smartphone with photo upload arrow
- GPS coordinate bubble: "25.033, 121.565"
- Label (Chinese): "使用者上傳照片"
- Curved glowing arrow pointing down →

**Step 6: 空間查詢** 🔍
- 3D card (soft blue #6B9BD1)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Icon: Magnifying glass over mini 3D globe
- Visual: PostGIS finding nearest point
- Annotation (Chinese label): "尋找最近點 (Country, Admin1, City)"
- Label (Chinese): "空間查詢"
- Curved glowing arrow pointing down →

**Step 7: 寫入資料庫** 💾
- 3D card (gentle green #54D62C)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Icon: Database record symbol
- Visual: Structured data card showing:
  * Country: Taiwan
  * State: Taipei City
  * City: Xinyi District
- Label (Chinese): "寫入位置資訊"

Background: **Almost white/neutral base** with BARELY visible elements:
- Tiny floating code symbols (opacity 3%)
- Database connection lines (opacity 3%)
- Should look almost like a clean white background at first glance

Decorative elements (all subtle):
- 3-5 small sparkles ✨ (opacity 40%)
- Gentle floating particles (opacity 20%)
- Connection arrows with subtle glow

Aspect ratio: 3:2
```


```text
AI Image Prompt:

=== UNIFIED STYLE GUIDE (apply to all 4 images) ===
- Visual style: Modern tech blog illustration with soft 3D cards, gentle gradients, rounded corners (16px radius)
- Color palette: Soft blue (#6B9BD1), warm coral (#FF8A80), purple accent (#9C27B0), gentle green (#54D62C)
- Shadows: REQUIRED - All cards must have soft drop shadows (blur 20px, opacity 15%, offset 0 4px)
- Typography: Clean sans-serif, use rounded containers for labels
- Arrows: Always smooth Bezier curves with subtle glow (glow: opacity 30%, blur 8px), never straight lines
- Background: **CRITICAL** - Must be almost white/neutral with BARELY visible pattern (opacity 3-5% maximum). The pattern should be nearly invisible.
- Decorative elements: Small sparkles ✨, location pins 📍, gentle floating particles (all with low opacity)
- Overall feel: Warm, approachable, developer-friendly (think Stripe/Vercel style)

**IMPORTANT: All labels and annotations in Traditional Chinese. Technical terms (field names, parameters, code) stay in English.**

=== IMAGE 1: GeoNames Data File Relationships ===

Central element: Large 3D card "cities500.txt" with document icon
- Card background: Soft blue (#6B9BD1) with white/light overlay
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Show sample fields (keep English):
  - geoname_id: 1668341
  - name: Taipei
  - latitude: 25.0330
  - admin1_code: "03" → (curved arrow pointing left)

Left floating card: "admin1CodesASCII.txt" with table/grid icon
- Card background: Warm coral (#FF8A80)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Example text: "TW.03 → Taiwan Province"
- Curved Bezier arrow WITH GLOW from cities500's admin1_code field
- Header label (Chinese): "一級行政區對照"

Right floating card: "admin2Codes.txt" with table/grid icon
- Card background: Purple accent (#9C27B0)
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Example text: "TW.03.01 → District Name"
- Curved Bezier arrow WITH GLOW from cities500's admin2_code field
- Header label (Chinese): "二級行政區對照"

Top cloud shape: "i18n-iso-countries" with globe/translation icon
- Cloud background: Gentle green (#54D62C) with light tint
- Apply shadow: blur 20px, opacity 15%, offset 0 4px
- Example text: "TW → 台灣"
- Dotted curved Bezier line WITH GLOW to cities500's country_code field
- Label inside cloud (Chinese): "國家名稱翻譯"

Bottom center: Simplified PostgreSQL elephant logo (light blue)
- Rounded container with shadow
- Text below logo (Chinese): "匯入至 geodata_places 表格"
- Curved arrow pointing down from cities500 card

Background: **Almost white/neutral base** with BARELY visible elements:
- Tiny location pins (opacity 3%)
- Coordinate numbers (opacity 3%)
- Globe wireframe pattern (opacity 3-5%)
- Should look almost like a clean white background at first glance

Decorative elements (all subtle):
- 3-5 small sparkles ✨ (opacity 40%)
- Gentle floating dots/particles (opacity 20%)

Aspect ratio: 16:9
```
