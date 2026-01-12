# Taxonomy i18n 設計文件

## 架構決策：基於內容的翻譯 (Content-Based Translation)

我們明確選擇使用 **Hugo 原生內容機制 (`_index.md`)**，而非 **覆蓋模板 (Template Overrides)**。

### 決策理由 (Rationale)
1.  **主題穩定性 (Theme Stability)**：覆蓋 `themes/blowfish/layouts/partials/article-meta/basic.html` 會增加維護負擔。每當上游主題更新該檔案時，我們都需要手動解決合併衝突。
2.  **原生支援 (Native Support)**：Hugo 和 Blowfish 本就設計為使用內容層來管理 Taxonomy Metadata。模板中的 `.LinkTitle` 會自動解析為 `_index.md` Front Matter 中定義的 `title`。
3.  **可擴充性 (Extensibility)**：此結構允許未來擴充（例如為 Taxonomy 頁面新增描述、圖片或 SEO Metadata），而無需更改翻譯機制。

## 語言與檔名規範 (Language & Filename Policy)
- **語言代碼**：統一使用 `zh-TW`（符合 RFC 5646/BCP 47 慣例：語言小寫、區域大寫）。
- **輸出檔案**：每個 Term 產生 `_index.zh-TW.md` 與 `_index.en.md`。
- **回退 (Fallback)**：若對應語言缺翻譯（或檔案不存在），渲���時直接回退到 Taxonomy 原始標題（Term/Slug）。

## 自動化策略 (Automation Strategy)

為了減輕管理大量小檔案的負擔，我們引入生成腳本。

### 單一真實來源 (Single Source of Truth, SSOT)
-   **來源**：`data/taxonomy/zh-TW.yaml` 與 `data/taxonomy/en.yaml`。
-   **目標**：`content/{categories,tags}/<term>/_index.<lang>.md`。
-   **格式**：YAML，且僅允許以下結構：
    -   最上層只允許 `categories` 與 `tags`。
    -   `categories`/`tags` 的 key 為 Term（全小寫 kebab-case）。
    -   value 為顯示用 `title`（字串）。

**SSOT 範例：**
```yaml
categories:
  linux-technical: "Linux 技術"
  paper-survey: "論文筆記"
tags:
  nerf: "NeRF"
  neus: "NeuS"
```

### 腳本設計 (`scripts/generate-taxonomy-index.sh`)
1.  **功能**：解析 SSOT 取得各語言翻譯。
2.  **動作**：
    -   產生或更新 `_index.zh-TW.md` 與 `_index.en.md`。
    -   自動建立缺失目錄（`mkdir -p content/{categories,tags}/<term>/`）。
    -   **冪等性**：若檔案已存在，先讀取內容比較 `title`。僅當 `title` 不一致時才寫入，並保留其他 Front Matter 欄位。
3.  **驗證**：
    -   產出檔案需對應所有實際使用的 Term。
    -   翻譯缺失時仍產生檔案（`title` 使用原始 Term），並輸出警告。
    -   SSOT 必須同時定義 `zh-TW` 與 `en` 翻譯（允許內容相同，但不可缺漏）。

### Term 驗證機制 (`script/validate-taxonomy-terms.sh`)
1.  **功能**：驗證內容中的 taxonomy term 是否符合 SSOT。
2.  **檢查範圍**：僅檢查本次 commit 內「新增或變更」且已暫存的內容檔案（`git diff --cached --diff-filter=AM`）。
3.  **檢查項目**：
    -   Term 必須全小寫（kebab-case）。
    -   Term 必須存在於 SSOT。
    -   SSOT 必須同時定義 `zh-TW` 與 `en` 翻譯。
4.  **執行方式**：於 `script/git-hooks/pre-commit` 中呼叫。
5.  **執行順序**：必須先執行 taxonomy 驗證。若驗證失敗，中止 commit 並阻止執行後續腳本（如 edit time 更新）。
6.  **結果**：若檢查失敗，必須中止 commit。

## 語言處理 (Language Handling)
1.  **預設語言**：`zh-TW`。
2.  **英文支援**：必須產生 `_index.en.md`。
3.  **回退**：缺翻譯時，顯示原始 Term。

## Term 命名規範 (Term Naming Policy)
-   **必須全小寫**（kebab-case）。
-   既有內容若存在大小寫混用，需先修正為全小寫，避免產生重複 Term。

## 模板調整 (Template Alignment)

為配合內容驅動的翻譯機制，同時減少維護負擔，我們採取以下策略：

1.  **移除冗餘模板 (Remove Redundant Templates)**
    -   透過分析發現，移除 `i18n` 轉換後，部分模板與 Blowfish 原生版本功能一致。
    -   直接刪除以下檔案，回歸使用原生模板：
        -   `layouts/_default/term.html`
        -   `layouts/partials/term-link/text.html`
        -   `layouts/partials/term-link/card.html`

2.  **更新自訂模板 (Update Custom Templates)**
    -   保留包含自訂 UI 邏輯（如 SVG 圖標、自訂卡片樣式）的模板。
    -   修改以下檔案，移除 `i18n` 函數，改用 `.Title` / `.Page.Title`：
        -   `layouts/categories/term.html` (含資料夾圖標)
        -   `layouts/categories/terms.html` (自訂卡片列表)
        -   `layouts/tags/term.html` (含標籤圖標)
        -   `layouts/tags/terms.html` (自訂標籤雲)
