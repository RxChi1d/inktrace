# Analysis: Taxonomy Badge 顏色恢復

本文件記錄 `restore-taxonomy-badge-colors` 的關鍵分析與風險點，避免日後需重新掃描整個 codebase。

## 分析範圍與來源

- 專案 badge 覆寫：`layouts/partials/badge.html`
- Blowfish 原生 badge：`themes/blowfish/layouts/partials/badge.html`
- taxonomy badges 呼叫：`themes/blowfish/layouts/partials/article-meta/basic.html`
- 其他 badge 呼叫：
  - `themes/blowfish/layouts/partials/article-link/card.html`
  - `themes/blowfish/layouts/partials/article-link/card-related.html`
  - `themes/blowfish/layouts/partials/article-link/simple.html`
  - `themes/blowfish/layouts/partials/article-link/_shortcode.html`
  - `themes/blowfish/layouts/shortcodes/timelineItem.html`
- 既有 custom CSS：`assets/css/custom/global.css`

## badge.html 差異摘要

### 專案版 (`layouts/partials/badge.html`)
- 支援 dict/map 參數（`reflect.IsMap`）
- 支援 `type="category"` / `type="tag"`（決定 class）
- 內建 i18n fallback（`(i18n $text) | default $text`）
- 使用自訂 class（`badge-custom`, `badge-inner`, `badge-category`, `badge-tag`）
- 內建 `style="cursor: pointer;"`（滑鼠指標變手）

### Blowfish 原生 (`themes/blowfish/layouts/partials/badge.html`)
- 僅接受字串
- 不支援 `type`
- 不做 i18n
- 使用 Tailwind classes（`border-primary-400`, `text-primary-700` 等）
- 已包含 `cursor-pointer` class（滑鼠指標變手）

## 呼叫來源與實際使用

目前專案內所有 badge 呼叫都傳入**字串**，未傳 dict/map，也未傳 `type`：

- `article-meta/basic.html`：taxonomy badges（`.LinkTitle`）
- `article-link/*.html`：draft badge
- `article-link/_shortcode.html`：draft badge
- `shortcodes/timelineItem.html`：badge 參數字串。此 shortcode 直接將 `badge` 參數傳給 partial。移除專案 badge 後，timeline badge 將使用 Blowfish 預設樣式（無顏色區分），這符合預期，因為 timeline badge 通常不是 taxonomy，不需要特定顏色。

結論：
- dict/map 支援未被使用
- `type` 邏輯未被使用
- i18n 於呼叫前已完成（例如 draft），badge 內的 i18n 為冗餘
- `cursor: pointer` 在原生 badge 已存在，移除專案 badge 不影響視覺互動

## taxonomy i18n 現況

- Blowfish taxonomy badge 使用 `.LinkTitle`，其來源是 Hugo taxonomy term 的顯示名稱
- 目前專案未建立 `content/categories/` / `content/tags/` 的 term `_index.md`，因此 `.LinkTitle` 多半等於原始 term 字串
- `i18n/zh-TW.yaml` 已存在部分 term key（例如 `immich`），但 **Blowfish 不會自動用 i18n key 取代 `.LinkTitle`**。這意味著單純在 i18n 檔案中定義 taxonomy 翻譯是無效的，這也是為何移除專案 badge 內建的 i18n 邏輯不會造成實際退化（因為它原本就沒被正確用在 taxonomy 上，或者 taxonomy 根本沒傳入 i18n key）。


## 建議的翻譯路徑（未包含在本次變更）

若未來要讓 taxonomy 顯示翻譯名稱，建議採 Hugo 的 term content：

- 建立多語 term page，例如：
  - `content/tags/immich/_index.zh-tw.md`
  - `content/tags/immich/_index.en.md`
- 在 front matter 設定 `title` / `linkTitle`
- `.LinkTitle` 會自動帶出對應語言標題

## CSS 選擇器依賴與風險

本變更計畫使用：
- `a[href*="/categories/"]` 與 `a[href*="/tags/"]` 判斷 taxonomy 類型
- `span.flex.cursor-pointer > span` 指向 Blowfish badge 結構

決策說明：
- **保留 `cursor-pointer` 作為 badge 辨識條件**。
- 原始 selector 不會誤選 term count badge，因為 term count 結構為 `span.flex` 且**沒有** `cursor-pointer`。
- `cursor-pointer` 屬於互動提示（可點擊）而非純視覺樣式，變動風險低於 `text-xs` 等設計性 class。

風險：
- 若 taxonomy 路徑改名（例如 `/topics/`），需同步調整 selector
- 若 Blowfish 移除 `cursor-pointer` class，selector 需調整（但機率低）

## !important 策略

先不使用 `!important`，若開發者工具顯示未覆蓋再補上，避免不必要的強制覆寫。
