# 恢復 Taxonomy Badge 多語言支援 (i18n)

## 摘要 (Summary)
透過實作 Hugo 原生的多語言內容機制 (`_index.<lang>.md`)，恢復 Taxonomy Badge（分類與標籤）的翻譯顯示。我們將以 `data/taxonomy/zh-TW.yaml` 與 `data/taxonomy/en.yaml` 作為 SSOT 自動產生 taxonomy 內容檔案，並移除模板中針對 taxonomy 的 `i18n` 轉換，確保顯示一致且符合 Hugo/Blowfish 的標準作法。同時新增 term 驗證機制以防止內容使用錯誤或缺漏的 taxonomy。

## 問題 (Problem)
在將專案遷移回 Blowfish 原生架構後，文章卡片和 Metadata 區域上的 Taxonomy Badge 目前顯示的是原始的 Term ID（例如 "linux-technical", "nerf"），而非預期的翻譯名稱（例如 "Linux 技術", "NeRF"）。這是因為 Blowfish 原生模板直接使用 `.LinkTitle`，並預期標題會在內容層（Content Layer）定義，而非透過 `i18n` 函數轉換。

## 解決方案 (Solution)
我們將採用符合 Hugo 與 Blowfish 設計哲學的標準做法：
1.  在 `content/categories/` 與 `content/tags/` 下，為每個 Term 建立 `_index.zh-TW.md` 與 `_index.en.md`。
2.  在這些檔案的 Front Matter 中定義翻譯後的 `title`，並在缺翻譯時回退到原始 Term。
3.  開發 Shell 腳本 (`scripts/generate-taxonomy-index.sh`)，以 `data/taxonomy/` 作為 SSOT 自動產生或更新這些檔案。
4.  新增 term 驗證腳本並接入 `script/git-hooks/pre-commit`，確保內容中的 term 合規且雙語翻譯完整。
5.  移除自訂模板中對 taxonomy 標題的 `i18n` 轉換，統一使用 `.Title` / `.LinkTitle`。

此方案完全不需要修改任何 Blowfish 主題模板，避免了日後升級主題時的維護負擔。
