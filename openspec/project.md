# Project Context

## Purpose
這是一個個人部落格專案，使用 [Hugo](https://gohugo.io/) 靜態網站產生器框架搭配 [Blowfish](https://github.com/nunocoracao/blowfish) 主題建置。目標是提供一個易於維護、高度客製化且效能良好的寫作平台。

## Tech Stack
- **Framework**: Hugo Extended (v0.87.0+)
- **Theme**: Blowfish (作為 Git submodule 管理)
- **Version Control**: Git
- **CSS**: Custom CSS (Modular management)
- **Scripting**: Bash (Setup and maintenance scripts)

## Project Conventions

### Code Style
- **語言規則**:
  - 文檔、Commit 訊息、PR 描述：使用 **zh-tw** (繁體中文)。
  - 程式碼註解、變數/函數命名：使用 **en** (英文)。
- **撰寫風格**:
  - 文檔遵循 Google 風格。
  - Commit 與 PR 遵循 Conventional Commits 與 Google 風格。
- **AI 行為規範**:
  - 嚴禁臆造不存在的函式或套件。
  - 修改程式碼前必須確認檔案存在。
  - 必須使用 `gh` CLI 與 GitHub 互動。
  - **Shell 工具使用規範**:
    | 任務類型 | 必須使用 | 禁止使用 |
    |---------|---------|---------|
    | 檔案搜尋 | `fd` | `find`, `ls -R` |
    | 文字搜尋 | `rg` (ripgrep) | `grep`, `ag` |
    | 程式碼結構分析 | `ast-grep` | `grep`, `sed` |
    | 互動式選擇 | `fzf` | 手動篩選 |
    | 處理 JSON | `jq` | `python -m json.tool` |
    | 處理 YAML/XML | `yq` | 手動解析 |

### Architecture Patterns
- **模組化 CSS 管理**:
  - 所有自訂 CSS 必須位於 `assets/css/custom/`。
  - 檔案命名採用 `kebab-case`。
  - 透過 `layouts/partials/extend-head.html` 自動載入。
  - **絕對禁止**修改 `themes/blowfish/` 目錄下的檔案。
- **目錄結構**:
  - `content/`: 存放文章與頁面。
  - `archetypes/`: 內容模板。
  - `layouts/`: 自訂版面覆寫。
  - `static/`: 靜態資源。

### Testing Strategy
- 目前主要依賴人工審查與本地預覽 (`hugo server`)。
- PR 提交時必須包含測試資訊與檢查清單。
- 確保所有變更符合憲法原則 (Constitution)。

### Git Workflow
- **分支命名**: 遵循 Conventional Branch Naming (例如 `feat/add-new-feature`, `fix/correct-typo`)。
- **Commit 訊息**: 遵循 Conventional Commits。
  ```
  <type>(<scope>): <description>
  
  [optional body]
  
  [optional footer(s)]
  ```
- **Pre-commit Hook**: 自動更新 Markdown 檔案的 `lastmod` 欄位（使用 Asia/Taipei 時區）。

## Domain Context
- 本專案為靜態網站，重點在於內容呈現與閱讀體驗。
- 使用 Hugo 的內容管理機制 (Sections, Taxonomies)。
- 高度依賴 Blowfish 主題的功能，應優先使用主題原生的 Shortcodes 和配置。

## Important Constraints
- **憲法優先**: 所有開發活動必須符合 `.specify/memory/constitution.md` 定義的原則。
- **主題完整性**: 為了保持主題升級的便利性，嚴禁直接修改 `themes/blowfish/` 內的檔案。所有客製化必須透過 Hugo 的 override 機制（在專案根目錄下的 `layouts/` 或 `assets/` 進行）。
- **語言一致性**: 嚴格遵守中英文使用場景的區分。

## External Dependencies
- **Blowfish Theme**: 作為 Git Submodule 存在，位於 `themes/blowfish/`。
- **Hugo**: 構建工具。