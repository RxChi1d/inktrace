# Migration Notes: Restore Native Card Behavior

本文件記錄因執行 `restore-native-cards` 遷移工作而受影響的自訂功能。這些功能在遷移過程中被移除或重置，以便後續重新評估與補回。

## 1. Summary Line Clamp (摘要行數限制)

- **原始功能**: 允許透過 `config` 設定 `summaryLineClamp` 參數（例如 `3`），自動截斷文章列表中的摘要文字並顯示刪節號。
- **原始實作**: 在 `layouts/partials/article-link/simple.html` 中使用 inline style (`-webkit-line-clamp`)。
- **遷移影響**: 為求結構回歸原生，此邏輯將被移除（或若保留則需確認與原生結構的相容性）。
- **後續行動**: 待遷移完成後，評估是否以 CSS class 或其他方式重新加入此功能。

## 2. Taxonomy Badge Colors (分類與標籤顏色區分)

- **原始功能**: 分類 (Category) 顯示為綠色系，標籤 (Tag) 顯示為藍色系。
- **原始實作**: 
  - `article-meta/basic.html` 呼叫 `badge.html` 時傳入 `type="category"` 或 `type="tag"`。
  - `assets/css/custom/global.css` 依據 `type` 套用對應 CSS 變數。
- **遷移影響**: 回歸原生 `basic.html` 邏輯後，不再傳遞 `type` 參數，所有 Badge 將變回主題預設顏色。
- **後續行動**: 等待 Blowfish 上游支援，或尋找不侵入 HTML 結構的 CSS 選取方案（如 `:nth-of-type` 或屬性選取器）。

### 詳細樣式規格 (Style Spec)

**Category (Category Badges):**
*   **Light Mode:**
    *   Border: `#22c55e` (green-500)
    *   Text: `#15803d` (green-700)
*   **Dark Mode:**
    *   Border: `#4ade80` (green-400)
    *   Text: `#86efac` (green-300)

**Tag (Tag Badges):**
*   **Light Mode:**
    *   Border: `#0ea5e9` (sky-500)
    *   Text: `#0369a1` (sky-700)
*   **Dark Mode:**
    *   Border: `#38bdf8` (sky-400)
    *   Text: `#7dd3fc` (sky-300)

**Fallback/Default:**
*   Uses Theme Primary Colors (`var(--color-primary-*)`).

**CSS Code (Archive):**
```css
/* Badge custom styles */
.badge-category {
  /* Light mode styles for category */
  --badge-border-color: #22c55e; /* green-500 */
  --badge-text-color: #15803d;   /* green-700 */
}
.dark .badge-category {
  /* Dark mode styles for category */
  --badge-border-color: #4ade80; /* green-400 */
  --badge-text-color: #86efac;   /* green-300 */
}

.badge-tag {
  /* Light mode styles for tag */
  --badge-border-color: #0ea5e9; /* sky-500 */
  --badge-text-color: #0369a1;   /* sky-700 */
}
.dark .badge-tag {
  /* Dark mode styles for tag */
  --badge-border-color: #38bdf8; /* sky-400 */
  --badge-text-color: #7dd3fc;   /* sky-300 */
}
```

## 3. Custom Image Handling (自訂圖片處理)

- **原始功能**: 使用 CSS `background-image` 顯示卡片縮圖。
- **遷移影響**: 改回 Blowfish 原生的 `<img>` 標籤，支援 lazy loading 與 async decoding。
- **後續行動**: 無需補回，原生方案效能較佳。僅需確認視覺裁切效果 (`object-cover`) 是否符合預期。

## 4. Card Visual Styling (卡片視覺樣式差異)

- **原始功能**: 卡片具有毛玻璃背景、陰影與 hover 變色效果。
- **原始實作**:
  - `layouts/partials/article-link/simple.html` 使用 `border-2 rounded-2xl border-neutral-200 dark:border-neutral-700 article-card-hover`。
  - `assets/css/custom/posts.css` 提供 `article-card-hover` 的背景、陰影與 hover 變化。
  - `assets/css/custom/global.css` 補上 `a.article-card-hover:hover` 的背景變色。
- **遷移影響**:
  - 回到 Blowfish 原生卡片：**無背景色、無 hover 背景變色**。
  - 邊框改回原生規格：`rounded-lg`、`border-neutral-300 dark:border-neutral-600`（視覺上比原自訂圓角更小、邊框色更深）。
- **後續行動**: 若要保留原自訂外觀，需以純 CSS 方式重新加入，或等待上游提供可選樣式。
