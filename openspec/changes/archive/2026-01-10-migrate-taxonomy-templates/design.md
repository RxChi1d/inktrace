## Context
目前 taxonomy 相關頁面（tags/categories）使用專案自訂模板，偏離 Blowfish 原生邏輯，導致升級風險高且維護成本上升。目標是回歸原生模板並保留既有視覺與功能。

## Goals / Non-Goals
- Goals:
  - 以 Blowfish 原生模板為主，最小覆蓋達成現有視覺與功能 100% 還原。
  - 透過最小 hook 讓 CSS 能可靠判斷 taxonomy 類型。
  - 保留 Categories 的 Post/Posts 單複數顯示邏輯。
  - 依既定修正方案調整結構與 CSS。
  - 新增覆蓋模板紀錄與升級檢查提醒。
- Non-Goals:
  - 不修改 `themes/blowfish/` 任何檔案。
  - 不新增 JavaScript 判斷 URL 的方案。

## Decisions
- Decision: 使用 3 個最小覆蓋檔案。
  - `layouts/_default/terms.html` 與 `layouts/_default/term.html` 僅在最外層容器加上 taxonomy hook（例如 `data-taxonomy`），其餘內容保持與 Blowfish 原生一致。
  - `layouts/partials/term-link/text.html` 調整 tags 的寬度 class、加入 categories inline SVG，並保留 Post/Posts 單複數邏輯。
- Decision: Categories icon 以 inline SVG 產生，確保可繼承主題顏色。
- Decision: Tags list 移除強制寬度 class，恢復 inline tag cloud 排版。
- Decision: CSS selector 鎖定列表頁容器（`section.flex.flex-wrap`），避免汙染 term 文章列表。
- Decision: 建立專案根目錄 `BLOWFISH-OVERRIDES.md`，內容必須包含原始檔案的 Commit Hash，並在 `CLAUDE.md` 提醒升級檢查。
- Decision: Categories 卡片內 icon 與文字間距以 CSS margin 控制，避免 icon 過於貼近文字。

## Alternatives Considered
- 純 CSS 無模板覆蓋：無法可靠區分 taxonomy 類型，且無法提供語意正確的 Post/Posts。
- JavaScript 根據 URL 加 class：增加 JS 依賴與閃爍風險。

## Risks / Trade-offs
- 覆蓋檔案需在 Blowfish 升級時同步比對。
- 視覺 100% 還原依賴 CSS 與 hook 的穩定性。

## Migration Plan
1. 確認修正策略與範圍。
2. 移除 `layouts/tags/` 與 `layouts/categories/` 自訂模板。
3. 從 Blowfish 原生模板複製對應檔案並加入最小 hook（兩個模板 + 一個 partial）。
4. 調整 `term-link/text.html`（移除 tags 寬度 class、加入 categories inline SVG、保留 Post/Posts）。
5. 收斂 CSS selector 範圍並解除 tags 容器寬度限制，避免 term 頁面污染。
6. 微調 categories 卡片內 icon 與文字間距，貼近原設計節奏。
7. 建立 `BLOWFISH-OVERRIDES.md`（含 Source Commit Hash）並更新 `CLAUDE.md` 提醒章節。
8. 本地 `hugo server` 搭配 Chrome DevTools 驗證 zh-TW/en 的 tags/categories 視覺與功能。

## Open Questions
- （已確認）提醒章節寫入 `CLAUDE.md`。
- （已確認）覆蓋模板紀錄檔命名為 `BLOWFISH-OVERRIDES.md`。
