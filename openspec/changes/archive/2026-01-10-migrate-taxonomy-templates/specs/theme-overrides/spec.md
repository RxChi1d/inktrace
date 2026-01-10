## ADDED Requirements
### Requirement: 覆蓋模板紀錄檔
系統 SHALL 在專案根目錄維護 `BLOWFISH-OVERRIDES.md`，列出本次變更新增的 Blowfish 覆蓋模板路徑、來源版本 (Source Commit Hash)、覆蓋原因、功能與必要性。

#### Scenario: 覆蓋清單完整
- **Given** 已完成 taxonomy 模板遷移。
- **When** 檢視覆蓋模板紀錄檔。
- **Then** 檔案必須存在於專案根目錄且檔名為 `BLOWFISH-OVERRIDES.md`。
- **And** 必須列出 `layouts/_default/terms.html`、`layouts/_default/term.html`、`layouts/partials/term-link/text.html`。
- **And** 每一項都包含「來源 Commit Hash」、「為什麼要覆蓋」、「功能是什麼」、「必要性」的說明。

### Requirement: 升級檢查提醒
系統 SHALL 在指定文件（`CLAUDE.md`）中新增提醒章節，指示 Blowfish 主題升級時需檢查覆蓋模板與紀錄檔的同步性。

#### Scenario: 提醒章節存在
- **Given** 覆蓋模板紀錄檔已建立。
- **When** 檢視 `CLAUDE.md`。
- **Then** 必須存在提醒章節。
- **And** 章節內容需提及覆蓋模板紀錄檔並要求升級時比對。
