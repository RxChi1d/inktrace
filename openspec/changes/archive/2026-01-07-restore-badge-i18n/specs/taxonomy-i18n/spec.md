# Taxonomy i18n 規格 (Specification)

## ADDED Requirements

### Requirement: 多語 Taxonomy 內容結構 (Multilingual Taxonomy Content Structure)
系統必須 (MUST) 使用 Hugo 內容檔案 (`_index.<lang>.md`) 來定義 Taxonomy Term 的本地化標題。

#### Scenario: Category 標題解析（zh-TW）
-   **Given** 有一個 Category Term `linux-technical`。
-   **And** 存在內容檔案 `content/categories/linux-technical/_index.zh-TW.md`。
-   **And** 該檔案的 Front Matter 包含 `title: "Linux 技術"`。
-   **When** 渲染 Taxonomy Badge 時。
-   **Then** 它必須顯示 "Linux 技術"。

#### Scenario: Tag 標題解析（en）
-   **Given** 有一個 Tag Term `nerf`。
-   **And** 存在內容檔案 `content/tags/nerf/_index.en.md`。
-   **And** 該檔案的 Front Matter 包含 `title: "NeRF"`。
-   **When** 渲染 Taxonomy Badge 時。
-   **Then** 它必須顯示 "NeRF"。

### Requirement: 翻譯缺失回退 (Fallback to Term)
當對應語言的翻譯檔案不存在或缺少 `title` 時，系統必須 (MUST) 回退至原始 Term。

#### Scenario: 回退到 Term
-   **Given** 有一個 Tag Term `open-data`。
-   **And** 不存在 `content/tags/open-data/_index.en.md`。
-   **When** 於英文語系渲染 Taxonomy Badge 時。
-   **Then** 它必須顯示 "open-data"。

### Requirement: 模板顯示來源一致 (Template Alignment)
系統必須 (MUST) 以 `.Title` / `.LinkTitle` 作為 taxonomy 標題來源，且不得再使用 `i18n` 進行轉換。

#### Scenario: 移除 i18n 轉換
-   **Given** 自訂模板存在 taxonomy 標題的顯示邏輯。
-   **When** 渲染 taxonomy badge 或 term 連結。
-   **Then** 僅使用 `.Title` / `.LinkTitle`，不使用 `i18n`。

### Requirement: Term 命名規範 (Lowercase Terms)
系統必須 (MUST) 使用全小寫的 taxonomy term（kebab-case）。

#### Scenario: 修正混用大小寫
-   **Given** 內容內存在 `tags: ["NeuS"]`。
-   **When** 進行 taxonomy term 正規化。
-   **Then** term 必須被修正為 `neus`。

### Requirement: SSOT 資料格式 (SSOT Data Format)
系���必須 (MUST) 以 YAML 檔案定義 taxonomy 翻譯，且格式僅允許 `categories` 與 `tags` 兩個頂層鍵值，並使用 `term: title` 的鍵值對。

#### Scenario: SSOT 結構正確
-   **Given** `data/taxonomy/zh-TW.yaml` 含有 `categories` 與 `tags`。
-   **And** 兩者皆由 `kebab-case` 的 term 對應字串 `title`。
-   **When** 解析 SSOT。
-   **Then** 驗證必須通過。

### Requirement: 自動化工具 (Automation Tooling)
必須 (SHALL) 提供腳本，以從 SSOT 自動產生 Taxonomy 內容檔案。

#### Scenario: 腳本生成（雙語）
-   **Given** `data/taxonomy/zh-TW.yaml` 與 `data/taxonomy/en.yaml` 中定義 `linux-technical` 的翻譯。
-   **When** 執行 `scripts/generate-taxonomy-index.sh`。
-   **Then** 檔案 `content/categories/linux-technical/_index.zh-TW.md` 必須存在。
-   **And** 檔案 `content/categories/linux-technical/_index.en.md` 必須存在。
-   **And** 其內容分別包含對應語言的 `title`。

#### Scenario: 腳本驗證與回退
-   **Given** 內容中存在 `open-data` term，但 SSOT 中缺少對應翻譯。
-   **When** 執行 `scripts/generate-taxonomy-index.sh`。
-   **Then** 對應的 `_index.<lang>.md` 仍必須存在。
-   **And** `title` 必須回退為原始 Term。

### Requirement: Term 驗證機制 (Term Validation)
必須 (SHALL) 提供驗證腳本，並在 pre-commit 中執行以阻止不合規的 taxonomy term。

#### Scenario: 驗證失敗中止 commit
-   **Given** 某內容檔案新增 `tags: ["Engineering"]`。
-   **When** 執行 `script/validate-taxonomy-terms.sh`。
-   **Then** 驗證必須失敗並阻止 commit。

#### Scenario: 驗證範圍為已暫存檔案
-   **Given** 本次 commit 內僅暫存部分內容檔案。
-   **When** 執行驗證腳本。
-   **Then** 僅檢查 `git diff --cached --diff-filter=AM` 的內容檔案。

#### Scenario: 雙語翻譯完整性
-   **Given** `data/taxonomy/zh-TW.yaml` 定義了 `nerf`。
-   **And** `data/taxonomy/en.yaml` 未定義 `nerf`。
-   **When** 執行驗證腳本。
-   **Then** 驗證必須失敗並阻止 commit。
