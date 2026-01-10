# Blowfish 覆蓋模板紀錄

本檔案列出專案內覆蓋 Blowfish 原生模板的清單，供升級時比對與同步更新。
**注意**：此清單僅涵蓋已完成研究並確認覆蓋原因與功能的模板。`layouts/` 目錄中可能仍有其他覆蓋檔案尚未納入，代表其原因與用途尚未整理或驗證；因此請勿將本清單視為 `layouts/` 的完整覆蓋總覽。

## 覆蓋檔案結構

```
layouts/
├─ _default/
│  ├─ term.html
│  └─ terms.html
└─ partials/
   ├─ article-link/
   │  ├─ card.html
   │  ├─ card-related.html
   │  ├─ simple.html
   │  └─ _shortcode.html
   └─ term-link/
      └─ text.html
```

## Source Commit
- Blowfish submodule commit: `f9eb1d4e811d6da744848c35fb842cf386f6df39`

## 覆蓋清單

### 1. `layouts/_default/terms.html`
- 原始來源：`themes/blowfish/layouts/_default/terms.html`
- 來源 Commit Hash：`f9eb1d4e811d6da744848c35fb842cf386f6df39`
- 覆蓋原因：需要在列表頁加入 `data-taxonomy` hook 供 CSS 精準鎖定 Tags/Categories 樣式。
- 功能說明：保持原生 terms 模板結構與邏輯，只在最外層容器增加 taxonomy 類型標記。
- 必要性：避免 CSS selector 汙染 term 文章列表，並支援 tags inline / categories card 的差異化樣式。

### 2. `layouts/_default/term.html`
- 原始來源：`themes/blowfish/layouts/_default/term.html`
- 來源 Commit Hash：`f9eb1d4e811d6da744848c35fb842cf386f6df39`
- 覆蓋原因：需要在 term 頁加入 `data-taxonomy` hook 供 CSS 套用標題 icon 與樣式。
- 功能說明：保持原生 term 模板結構與邏輯，只在最外層容器增加 taxonomy 類型標記。
- 必要性：確保 tags/categories 單一頁標題 icon 可被 CSS 精準套用且不影響文章列表樣式。

### 3. `layouts/partials/term-link/text.html`
- 原始來源：`themes/blowfish/layouts/partials/term-link/text.html`
- 來源 Commit Hash：`f9eb1d4e811d6da744848c35fb842cf386f6df39`
- 覆蓋原因：需要移除 tags item 的強制寬度 class、加入 categories inline SVG icon，並保留 Post/Posts 單複數。
- 功能說明：維持原生 `<article><h2><a>` 結構，僅做最小調整以還原自訂視覺。
- 必要性：達成 tags inline tag cloud、categories card icon 可隨主題切換，以及 Post/Posts 語意正確。

### 4. `layouts/partials/article-link/card.html`
- 原始來源：`themes/blowfish/layouts/partials/article-link/card.html`
- 來源 Commit Hash：`f9eb1d4e811d6da744848c35fb842cf386f6df39`
- 覆蓋原因：補回 Summary Line Clamp 功能（對齊 Blowfish PR #2714）。
- 功能說明：在 `<article>` 增加 `article-link--card` class，Summary 區塊新增 `article-link__summary` class 並套用 `line-clamp-5`。
- 必要性：避免摘要過長破壞卡片排版與閱讀節奏。待 PR #2714 合併後可回收此覆蓋。

### 5. `layouts/partials/article-link/card-related.html`
- 原始來源：`themes/blowfish/layouts/partials/article-link/card-related.html`
- 來源 Commit Hash：`f9eb1d4e811d6da744848c35fb842cf386f6df39`
- 覆蓋原因：補回 Summary Line Clamp 功能（對齊 Blowfish PR #2714）。
- 功能說明：在 `<article>` 增加 `article-link--related` class，Summary 區塊新增 `article-link__summary` class 並套用 `line-clamp-5`。
- 必要性：避免相關文章摘要過長破壞卡片排版。待 PR #2714 合併後可回收此覆蓋。

### 6. `layouts/partials/article-link/simple.html`
- 原始來源：`themes/blowfish/layouts/partials/article-link/simple.html`
- 來源 Commit Hash：`f9eb1d4e811d6da744848c35fb842cf386f6df39`
- 覆蓋原因：補回 Summary Line Clamp 功能（對齊 Blowfish PR #2714）。
- 功能說明：在 `<article>` 增加 `article-link--simple` class，Summary 區塊新增 `article-link__summary` class 並套用 `line-clamp-3`。
- 必要性：確保簡單列表摘要維持 3 行內顯示。待 PR #2714 合併後可回收此覆蓋。

### 7. `layouts/partials/article-link/_shortcode.html`
- 原始來源：`themes/blowfish/layouts/partials/article-link/_shortcode.html`
- 來源 Commit Hash：`f9eb1d4e811d6da744848c35fb842cf386f6df39`
- 覆蓋原因：補回 Summary Line Clamp 功能（對齊 Blowfish PR #2714）。
- 功能說明：在 `<article>` 增加 `article-link--shortcode` class，Summary 區塊新增 `article-link__summary` class，並依 `compactSummary` 決定是否套用 `line-clamp-3`。
- 必要性：確保 shortcode 列表摘要在 compact 模式下正確截斷。待 PR #2714 合併後可回收此覆蓋。
