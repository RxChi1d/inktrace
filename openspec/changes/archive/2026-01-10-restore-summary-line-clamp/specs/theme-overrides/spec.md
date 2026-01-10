## MODIFIED Requirements
### Requirement: 覆蓋模板紀錄檔
系統 SHALL 在專案根目錄維護 `BLOWFISH-OVERRIDES.md`，列出本次變更新增的 Blowfish 覆蓋模板路徑、來源版本 (Source Commit Hash)、覆蓋原因、功能與必要性。

#### Scenario: 覆蓋清單完整
- **Given** 已完成 Summary Line Clamp 暫時覆蓋。
- **When** 檢視覆蓋模板紀錄檔。
- **Then** 檔案必須存在於專案根目錄且檔名為 `BLOWFISH-OVERRIDES.md`。
- **And** 必須列出 `layouts/_default/terms.html`、`layouts/_default/term.html`、`layouts/partials/term-link/text.html`。
- **And** 必須列出 `layouts/partials/article-link/card.html`、`layouts/partials/article-link/card-related.html`、`layouts/partials/article-link/simple.html`、`layouts/partials/article-link/_shortcode.html`。
- **And** 每一項都包含「來源 Commit Hash」、「為什麼要覆蓋」、「功能是什麼」、「必要性」的說明。
