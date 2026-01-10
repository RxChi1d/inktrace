# Change: 遷移 taxonomy 版型回 Blowfish 並最小覆蓋還原樣式

## Why
目前 taxonomy（tags/categories）使用專案自訂模板，與 Blowfish 原生邏輯分離，維護成本高且升級容易失真。本變更旨在回歸 Blowfish 原生模板，再以最小覆蓋與 CSS 調整達到現有樣式與功能的 100% 還原，同時建立覆蓋紀錄以利後續升級檢查。

## What Changes
- 移除 `layouts/tags/` 與 `layouts/categories/` 的自訂模板，改用 Blowfish 原生模板。
- 以最小覆蓋方式新增 3 個模板覆蓋檔：
  - `layouts/_default/terms.html`
  - `layouts/_default/term.html`
  - `layouts/partials/term-link/text.html`
- 保留 Categories 的 Post/Posts 單複數顯示邏輯（不更改設計）。
- 依既定修正方案調整 taxonomy 結構與 CSS：
  - 移除 tags item 的強制寬度 class，恢復 inline tag cloud。
  - Categories icon 改為 inline SVG（可隨主題顏色變化）。
  - CSS selector 收斂至列表頁容器（避免汙染 term 文章列表）。
  - 修正 tags 容器寬度限制（解除 `max-w-prose` 影響）。
  - 微調 categories 卡片內 icon 與文字間距，避免 icon 過於貼近文字。
- 新增專案根目錄「覆蓋模板紀錄檔」：`BLOWFISH-OVERRIDES.md`，列出本次覆蓋原因與功能。
- 更新 `CLAUDE.md` 新增提醒章節：升級 Blowfish 時需檢查覆蓋模板是否同步更新。

## Impact
- Affected specs: `theme-overrides`（新增）、可能影響 taxonomy 外觀但不改變資料語意。
- Affected code: taxonomy 模板覆蓋（3 檔）、taxonomy CSS、覆蓋紀錄文件、`CLAUDE.md`。
- 注意事項：提醒章節將寫入 `CLAUDE.md`（依使用者指示）。
