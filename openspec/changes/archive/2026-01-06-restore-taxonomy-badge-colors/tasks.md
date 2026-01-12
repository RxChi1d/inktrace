# Implementation Tasks

## 0. 分析與遷移說明文件
- [x] 0.1 新增 `analysis.md`，整理 badge.html 對比、實際呼叫來源、冗餘邏輯（dict/type/i18n）與風險點
- [x] 0.2 在 `analysis.md` 記錄 timelineItem shortcode 仍會呼叫 `badge` 的行為與影響範圍
- [x] 0.3 在 `analysis.md` 記錄 taxonomy i18n 現況與影響（`.LinkTitle` 來源與 i18n key 的落差）
- [x] 0.4 新增 `migration-notes.md`，說明移除 badge.html 後的 i18n 影響與未來遷移方式（taxonomy term `_index.md` 多語標題）
- [x] 0.5 使用 `rg -n "badge-custom|badge-inner|badge-category|badge-tag"` 搜尋依賴，確認沒有其他檔案使用

## 1. 移除專案層級 badge.html
- [x] 1.1 刪除 `layouts/partials/badge.html`
- [x] 1.2 確認所有 badge 呼叫位置會自動 fallback 到 Blowfish 原生版本
- [x] 1.3 確認 badge 滑鼠指標仍為手形（由 Blowfish 原生 `cursor-pointer` class 提供）

## 2. 清理未使用的 CSS
- [x] 2.1 移除 `assets/css/custom/global.css` 中的以下樣式（若存在）：
  - `.badge-custom:not(.badge-category):not(.badge-tag)`
  - `.dark .badge-custom:not(.badge-category):not(.badge-tag)`
  - `.badge-custom .badge-inner`
  - `.badge-category`
  - `.badge-tag`

## 3. 實作純 CSS 顏色區分
- [x] 3.1 建立新檔案 `assets/css/custom/taxonomy-badges.css`
- [x] 3.2 新增 Category badges 樣式（綠色系）：
  - Light mode: border `#22c55e` (green-500), text `#15803d` (green-700)
  - Dark mode: border `#4ade80` (green-400), text `#86efac` (green-300)
- [x] 3.3 新增 Tag badges 樣式（藍色系）：
  - Light mode: border `#0ea5e9` (sky-500), text `#0369a1` (sky-700)
  - Dark mode: border `#38bdf8` (sky-400), text `#7dd3fc` (sky-300)
- [x] 3.4 使用 CSS 屬性選擇器：`a[href*="/categories/"]` 和 `a[href*="/tags/"]`
- [x] 3.5 目標 Blowfish 原生結構：`span.flex.cursor-pointer > span`（避免誤選 term count）
- [x] 3.6 **先不使用 `!important`**，若開發者工具顯示未覆蓋再補上

## 4. 測試與驗證
- [x] 4.1 執行 `hugo --cleanDestinationDir` 清理並重建
- [x] 4.2 驗證 HTML 結構使用 Blowfish 原生結構（Tailwind classes）
- [x] 4.3 確認沒有 `badge-custom`、`badge-inner`、`badge-category` 等 class
- [x] 4.4 測試 Light mode：Category 綠色、Tag 藍色
- [x] 4.5 測試 Dark mode：顏色正確切換
- [x] 4.6 回歸測試：Draft 標籤、Timeline、Badge shortcode 正常運作
- [x] 4.7 檢查所有使用 badge 的頁面無視覺或功能退化
