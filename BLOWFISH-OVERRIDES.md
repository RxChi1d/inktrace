# Blowfish 覆蓋模板紀錄

本檔案列出專案內覆蓋 Blowfish 原生模板的清單，供升級時比對與同步更新。
**注意**：此清單僅涵蓋已完成研究並確認覆蓋原因與功能的模板。`layouts/` 目錄中可能仍有其他覆蓋檔案尚未納入，代表其原因與用途尚未整理或驗證；因此請勿將本清單視為 `layouts/` 的完整覆蓋總覽。

## 覆蓋檔案結構

```
layouts/
├─ _default/
│  ├─ term.html
│  └─ terms.html
├─ posts/
│  └─ list.html
└─ partials/
   ├─ home/
   │  └─ custom.html
   └─ term-link/
      └─ text.html
```

## Source Commit
- Blowfish submodule commit: `9f2045746e83af34b9ead2aef38c8eafa10b592b`

## 覆蓋清單

### 1. `layouts/_default/terms.html`
- 原始來源：`themes/blowfish/layouts/_default/terms.html`
- 來源 Commit Hash：`9f2045746e83af34b9ead2aef38c8eafa10b592b`
- 覆蓋原因：需要在列表頁加入 `data-taxonomy` hook 供 CSS 精準鎖定 Tags/Categories 樣式。
- 功能說明：保持原生 terms 模板結構與邏輯，只在最外層容器增加 taxonomy 類型標記。
- 必要性：避免 CSS selector 汙染 term 文章列表，並支援 tags inline / categories card 的差異化樣式。

### 2. `layouts/_default/term.html`
- 原始來源：`themes/blowfish/layouts/_default/term.html`
- 來源 Commit Hash：`9f2045746e83af34b9ead2aef38c8eafa10b592b`
- 覆蓋原因：需要在 term 頁加入 `data-taxonomy` hook 供 CSS 套用標題 icon 與樣式。
- 功能說明：保持原生 term 模板結構與邏輯，只在最外層容器增加 taxonomy 類型標記。
- 必要性：確保 tags/categories 單一頁標題 icon 可被 CSS 精準套用且不影響文章列表樣式。

### 3. `layouts/partials/term-link/text.html`
- 原始來源：`themes/blowfish/layouts/partials/term-link/text.html`
- 來源 Commit Hash：`9f2045746e83af34b9ead2aef38c8eafa10b592b`
- 覆蓋原因：需要移除 tags item 的強制寬度 class、加入 categories inline SVG icon，並保留 Post/Posts 單複數。
- 功能說明：維持原生 `<article><h2><a>` 結構，僅做最小調整以還原自訂視覺。
- 必要性：達成 tags inline tag cloud、categories card icon 可隨主題切換，以及 Post/Posts 語意正確。

### 4. `layouts/partials/home/custom.html`
- 參考來源：
  - `themes/blowfish/layouts/partials/home/profile.html`
  - `themes/blowfish/layouts/partials/home/hero.html`
  - `themes/blowfish/layouts/partials/home/page.html`
- 來源 Commit Hash：`9f2045746e83af34b9ead2aef38c8eafa10b592b`
- 覆蓋原因：需要自訂首頁「雙欄」結構（左側作者區塊、右側部落格標題區塊）。
- 功能說明：以自訂雙欄版型呈現作者與網站標題，保留 `recent-articles` 區塊，並對齊 Blowfish 的語意與圖片處理方式。
- 必要性：確保首頁版面符合雙欄設計需求，並可在 Blowfish 更新時對照相關 home 模板變更。

### 5. `layouts/posts/list.html`
- 原始來源：`themes/blowfish/layouts/_default/list.html`
- 來源 Commit Hash：`9f2045746e83af34b9ead2aef38c8eafa10b592b`
- 覆蓋原因：為 posts section 實作 timeline 視覺效果，提供 Git graph 風格的文章列表展示。
- 功能說明：
  - 保持 Blowfish 的核心功能（分頁、groupByYear、cardView 等參數）
  - 在非卡片視圖模式下，使用語意化的 `<ol>` 和 `<li>` 元素建構 timeline
  - 包含年份標記（amber 色點）和文章項目（藍色點）
  - 使用 `<time>` 元素與 datetime 屬性確保語意正確和 SEO 友好
  - 裝飾性元素使用 `aria-hidden="true"` 提升可訪問性
- 配合檔案：`assets/css/custom/posts.css` 提供 timeline 樣式
- 必要性：
  - 實現特定的視覺設計需求（timeline layout）
  - 保持語意 HTML 和可訪問性標準
  - 在 Blowfish 更新時需要對照 `_default/list.html` 的變更
