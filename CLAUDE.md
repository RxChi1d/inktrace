<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

此檔案提供 Claude Code (claude.ai/code) 在此儲存庫中工作時的指引。

## 專案概述

本專案是個人部落格的儲存庫，使用框架為 Hugo，搭配 Blowfish 主題。

## CSS 組織規範

本專案使用模組化的方式管理自訂 CSS，透過 `extend-head.html` 自動載入 `custom/` 目錄下的所有樣式檔案。

使用 `layouts/partials/extend-head.html` 搭配 Hugo Pipes 的 `resources.Match` 和 `resources.Concat`：

- 自動掃描 `assets/css/custom/*.css` 下的所有檔案
- 按檔名排序後合併成單一 bundle
- 在主題樣式之後載入，可覆寫預設樣式

### 檔案組織規則

**目錄結構：**
```
assets/css/custom/
├── global.css          # 全域樣式
├── homepage-custom.css # 首頁樣式
├── posts.css           # 文章頁樣式
├── categories.css      # 分類頁樣式
└── tags.css            # 標籤頁樣式
```

> 僅提供範例作爲參考

**命名規範：**
- 使用 `kebab-case` 命名
- 檔名清楚描述功能或頁面類型
- 建議前綴數字控制載入順序（如 `00-global.css`, `10-posts.css`）

### 修改 CSS 時的操作

**新增樣式檔案：**
- 在 `assets/css/custom/` 建立新的 `.css` 檔案
- 無需額外配置，`extend-head.html` 會自動偵測並載入

**修改現有樣式：**
- 直接編輯 `assets/css/custom/` 下對應的檔案

**移除樣式檔案：**
- 直接刪除 `assets/css/custom/` 下的檔案即可

### 禁止事項

- **絕不修改 `themes/blowfish/` 下的任何檔案**
- 所有自訂樣式必須放在專案層級的 `assets/css/custom/` 下
- 避免在 `custom/` 目錄外放置其他 CSS 檔案（會被自動掃描）

## Taxonomy 管理規範

為確保多語言分類 (Taxonomy) 顯示正確，本專案採用 Hugo 原生內容機制管理 Taxonomy 標題。

### 單一真實來源 (SSOT)

- `data/taxonomy/zh-TW.yaml`: 繁體中文翻譯
- `data/taxonomy/en.yaml`: 英文翻譯

### 內容生成

透過 `scripts/generate-taxonomy-index.sh` 自動產生 `content/{categories,tags}/<term>/_index.<lang>.md`。此腳本確保：
1. 每個 Term 都有對應的 `_index` 檔案
2. Front Matter 中的 `title` 與 SSOT 保持同步

### 驗證機制

`script/validate-taxonomy-terms.sh` 會在 commit 前檢查：
1. Term 必須為全小寫 kebab-case
2. Term 必須存在於 SSOT 中
3. SSOT 必須包含完整的 zh-TW 與 en 翻譯

## Blowfish 主題功能查閱準則

為確保準確掌握 Blowfish 主題的原生功能支援，避免重複造輪子：

- **查詢原生功能**：在建議或實作新的 UI 元件、Shortcode 或 Markdown 擴充語法前，**必須**通過搜尋以下檔案來準確瞭解主題設計的功能：
  - `themes/blowfish/exampleSite/content/docs/shortcodes/index.md` (Shortcodes 總覽)
  - `themes/blowfish/exampleSite/content/samples/**/index.md` (實作範例與語法展示)
  - `themes/blowfish/exampleSite/content/docs/front-matter/` (頁面參數設定)
  - `themes/blowfish/exampleSite/content/docs/configuration/` (全站配置)
  - `themes/blowfish/exampleSite/content/docs/partials/` (Partials 元件)
- **優先使用原生語法**：確認主題是否已提供所需功能，並優先使用原生的 Shortcode 或 Markdown 語法。

## 語言規則

**重要：請嚴格遵循以下語言規則**

1. **Claude.md 內容**：使用zh-tw
2. **對話語言**：使用zh-tw
3. **程式碼註解**：使用en
4. **函數/變數命名**：使用en
5. **Git commit 訊息**：使用zh-tw
6. **文件字串 (docstrings)**：使用zh-tw
7. **專案文檔**：使用zh-tw
8. **其他發布用文件**：使用zh-tw

## 撰寫風格與格式

- **專案文檔、說明文字、文件模板**：遵循 Google 風格。
- **Commit 與 PR 訊息**：遵循 Conventional Commit 格式與 Google 風格。
- **Changelog**：遵循 Keep a Changelog 格式。
- **分支名稱**：遵循 Conventional Branch Naming。

### Commit 撰寫規範

- **格式**：遵循 **Conventional Commits** 規範
- **風格**：Google 風格

#### 格式要求

```
<type>(<scope>): <description>    ← 第一行（50-72 字符）

[optional body]                   ← 詳細說明（72 字符換行）

[optional footer(s)]              ← 破壞性變更、問題參考
```

**重要說明**：
- **第一行**：GitHub 自動生成 release notes 使用
- **內容主體**：複雜變更的詳細解釋（不會出現在 release notes 中）
- **腳註**：破壞性變更和問題參考

### Pull Request 撰寫規範

**重要**：建立 PR 時必須遵循以下規範：

#### PR 標題格式
- 必須遵循約定式提交格式：`<type>(<scope>): <description>`
- 範例：`feat: add async operations with progress callbacks`

#### PR 內容格式
- 參考 `.github/pull_request_template.md` 中的模板
- 包含完整的變更說明、測試資訊、檢查清單

#### PR 標籤
- 根據 PR 標題自動分類（Release Drafter 自動處理）
- 確保選擇正確的變更類型

#### PR 描述要求
- 清楚描述變更內容和原因
- 列出相關的測試項目
- 確認所有檢查清單項目

**模板位置**：`.github/pull_request_template.md`
**風格**：Google 風格

## AI 行為規範
- **絕不假設缺漏的上下文，如有疑問務必提出問題確認。**
- **嚴禁臆造不存在的函式或套件**
- **在程式碼或測試中引用檔案路徑或模組名稱前，務必確認其存在。**
- **除非有明確指示，或任務需求（見 `TASK.md`），**否則**不得刪除或覆蓋現有程式碼。**
- **需要分析或拆解問題，通過 sequential thinking 進行更深度思考**
- **與 GitHub 互動需使用 gh CLI**
- **不准在未經允許的情況下，擅自在任何的文檔、訊息等文字中，包含 AI 編輯器或是 AI 模型的名稱**，例如:
  - Generated with [Claude Code]
  - Co-Authored-By: Claude

## Shell 工具使用指引

⚠️ **重要**：使用以下專業工具替代傳統 Unix 指令（若缺少請安裝）：

| 任務類型 | 必須使用 | 禁止使用 |
|---------|---------|---------|
| 檔案搜尋 | `fd` | `find`, `ls -R` |
| 文字搜尋 | `rg` (ripgrep) | `grep`, `ag` |
| 程式碼結構分析 | `ast-grep` | `grep`, `sed` |
| 互動式選擇 | `fzf` | 手動篩選 |
| 處理 JSON | `jq` | `python -m json.tool` |
| 處理 YAML/XML | `yq` | 手動解析 |
