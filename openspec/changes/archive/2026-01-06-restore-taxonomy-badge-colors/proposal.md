# Change: 恢復 Taxonomy Badge 顏色區分功能

## Why

在執行原生卡片遷移時，移除了專案層級的 `article-meta/basic.html`，導致 Category 和 Tag badges 失去顏色區分功能（原本 Category 為綠色系、Tag 為藍色系，現在全部使用主題預設顏色）。

經過詳細分析後發現，專案層級的 `badge.html` 包含大量未使用的功能（dict/map 參數支援、type 參數邏輯、冗餘的 i18n 處理），且自訂的 CSS class 缺少顏色定義，形同虛設。移除 `badge.html` 後會失去 badge 層級的 i18n 處理（若未來需要 taxonomy 翻譯，應改採 Hugo taxonomy term `_index.md` 的多語標題機制）。相關分析與遷移說明將記錄為獨立文件，避免未來再回頭翻 codebase。

## What Changes

1. **移除專案層級 badge.html**：刪除 `layouts/partials/badge.html`，完全回歸 Blowfish 原生實作
2. **清理未使用的 CSS**：移除 `assets/css/custom/global.css` 中依賴專案 badge.html 的樣式（`.badge-custom`, `.badge-inner`, `.badge-category`, `.badge-tag`）
3. **新增純 CSS 顏色區分方案**：建立 `assets/css/custom/taxonomy-badges.css`，使用 CSS 屬性選擇器 `a[href*="/categories/"]` 和 `a[href*="/tags/"]` 實現顏色區分
4. **新增分析與遷移說明文件**：建立 `analysis.md` 與 `migration-notes.md`，記錄 badge 行為差異、i18n 影響與未來翻譯遷移路徑

## Impact

- **受影響的 spec**：`taxonomy-display`（新建立，定義 badge 顏色區分需求）
- **受影響的檔案**：
  - 刪除：`layouts/partials/badge.html`
  - 修改：`assets/css/custom/global.css`（移除未使用的樣式）
  - 新增：`assets/css/custom/taxonomy-badges.css`
  - 新增：`openspec/changes/restore-taxonomy-badge-colors/analysis.md`
  - 新增：`openspec/changes/restore-taxonomy-badge-colors/migration-notes.md`
- **優勢**：
  - 完全回歸 Blowfish 原生模板，降低主題升級衝突風險
  - 移除所有死代碼和冗餘邏輯，代碼庫更簡潔
  - 純 CSS 解決方案，易於維護且不侵入 HTML 結構
