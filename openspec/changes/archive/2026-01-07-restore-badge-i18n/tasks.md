# 任務列表 (Tasks)

1.  **建立生成腳本 (Create Generation Script)**
    - [x] 開發 `scripts/generate-taxonomy-index.sh`。
    - [x] 實作 `data/taxonomy/zh-TW.yaml` 與 `data/taxonomy/en.yaml` 解析邏輯。
    - [x] 實作 `_index.zh-TW.md` 與 `_index.en.md` 檔案寫入邏輯。
    - [x] **冪等性設計**：僅當 `title` 確實變更時才寫入檔案（避免無謂更新 mtime）。
    - [x] 自動建立缺失目錄（`mkdir -p`）。
    - [x] 僅更新 `title`，保留既有 Front Matter 欄位。
    - [x] 加入驗證機制，確保產生的標題與 SSOT 一致；缺翻譯時回退到原始 Term 並輸出警告。

2.  **建立 SSOT (Create SSOT Data Files)**
    - [x] 新增 `data/taxonomy/zh-TW.yaml` 與 `data/taxonomy/en.yaml`。
    - [x] 撰寫一次性腳本，將 `i18n/*.yaml` 的 taxonomy 翻譯條目遷移至 data 檔案。
    - [x] 遵循 SSOT 格式：僅允許 `categories` 與 `tags`，並以 `term: title` 定義。

3.  **產生內容檔案 (Generate Content Files)**
    - [x] 執行腳本以填入 `content/categories/` 與 `content/tags/`。
    - [x] 確認每個 Term 皆有 `_index.zh-TW.md` 與 `_index.en.md`。

4.  **Term 驗證機制 (Add Term Validation)**
    - [x] 新增 `script/validate-taxonomy-terms.sh`。
    - [x] 驗證範圍限於 `git diff --cached --diff-filter=AM` 的內容檔案。
    - [x] 驗證失敗需中止 commit。
    - [x] 接入 `script/git-hooks/pre-commit`。

5.  **拆分 pre-commit 腳本 (Split pre-commit Scripts)**
    - [x] 將 edit time 更新邏輯抽成獨立腳本（如 `script/update-edit-time.sh`）。
    - [x] `script/git-hooks/pre-commit` 只負責串接腳本。
    - [x] **執行順序**：必須為 **taxonomy 驗證 → edit time 更新**。
    - [x] **錯誤處理**：若 taxonomy 驗證失敗（exit code != 0），**絕對不執行**後續的 edit time 更新。

6.  **修正 Term 命名 (Normalize Terms)**
    - [x] 將內容中的 taxonomy term 全面修正為小寫（kebab-case）。
    - [x] 此為破壞性變更，依賴 Git commit 作為 fallback checkpoint。

7.  **移除模板 i18n 並遷移至原生模板 (Template Cleanup & Migration)**
    - [x] **刪除冗餘模板 (改用 Blowfish 原生行為)**：
        - `layouts/_default/term.html` (Hero 邏輯更新、Grid 樣式調整、可配置指紋)
        - `layouts/partials/term-link/text.html`
        - `layouts/partials/term-link/card.html` (採用更完整的原生卡片結構：img 標籤、lazy loading、外部連結支援)
    - [x] **保留 categories/tags 自訂模板與 CSS**（自訂樣式需求，僅移除 `i18n`）
    - [x] **更新自訂模板**（移除 `i18n` 函數，改用 `.Title`）：
        - `layouts/categories/term.html`
        - `layouts/categories/terms.html`
        - `layouts/tags/term.html`
        - `layouts/tags/terms.html`
    - [x] **補齊 taxonomy list 的 `_index.<lang>.md`**（確保 `.Title` 有值）：
        - `content/categories/_index.zh-TW.md`
        - `content/categories/_index.en.md`
        - `content/tags/_index.zh-TW.md`
        - `content/tags/_index.en.md`
    - [x] **驗收檢查**：
        - 檢查 Taxonomy 列表頁 (Tags/Categories) Grid 佈局是否正常（驗證 `start-[...]` 等 Tailwind class）。
        - 檢查 Taxonomy 列表卡片圖片顯示是否正常（驗證 `img` 標籤與 CSS 適配性）。

8.  **驗證實作 (Validate Implementation)**
    - [x] 啟動 Hugo Server (`hugo server`)。
    - [x] 驗證首頁、列表頁與文章頁上的 Taxonomy Badge 是否顯示翻譯名稱。
    - [x] 驗證連結跳轉功能是否正常。
    - [x] 驗證缺翻譯時回退為原始 Term。

9.  **更新文件 (Documentation)**
    - [x] 更新 `CLAUDE.md`，加入新的「Taxonomy 管理規範」與語言代碼標準（`zh-TW`）。
    - [x] 更新 `MIGRATION_STATUS.md`，將「Badge i18n」標記為已完成。
