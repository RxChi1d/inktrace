<!--
Sync Impact Report:
- Version: 0.0.0 → 1.0.0 (Initial constitution based on CLAUDE.md)
- New constitution creation from CLAUDE.md
- Added sections: Core Principles (5 principles), Development Workflow, Governance
- Templates requiring updates:
  ✅ plan-template.md (reviewed - Constitution Check section aligns)
  ✅ spec-template.md (reviewed - requirements align with language rules)
  ✅ tasks-template.md (reviewed - task organization aligns with principles)
- Follow-up TODOs: None
-->

# Inktrace Blog Constitution

## Core Principles

### I. 模組化 CSS 管理 (Modular CSS Management)

**規則 (MUST):**
- 所有自訂 CSS 必須放置於 `assets/css/custom/` 目錄下
- 使用 `kebab-case` 命名 CSS 檔案
- 絕對禁止修改 `themes/blowfish/` 目錄下的任何檔案
- CSS 檔案會透過 `layouts/partials/extend-head.html` 自動載入

**理由:**
此原則確保專案自訂樣式與主題分離，便於升級主題而不影響客製化內容。模組化組織讓樣式管理更清晰且易於維護。

### II. 語言規則 (Language Standards)

**規則 (MUST):**
- CLAUDE.md 內容、對話語言、Git commit 訊息、文件字串、專案文檔：使用 zh-tw
- 程式碼註解、函數/變數命名：使用 en
- 所有語言選擇必須遵循上述規範，無例外

**理由:**
一致的語言使用確保文檔可讀性和程式碼的國際化。中文用於面向使用者的文檔和溝通，英文用於程式碼層級以保持技術通用性。

### III. 撰寫風格與格式 (Writing Style & Format)

**規則 (MUST):**
- 專案文檔、說明文字、文件模板：遵循 Google 風格
- Commit 與 PR 訊息：遵循 Conventional Commit 格式與 Google 風格
- Changelog：遵循 Keep a Changelog 格式
- 分支名稱：遵循 Conventional Branch Naming

**Commit 格式要求:**
```
<type>(<scope>): <description>    ← 第一行（50-72 字符）

[optional body]                   ← 詳細說明（72 字符換行）

[optional footer(s)]              ← 破壞性變更、問題參考
```

**PR 要求:**
- 標題必須遵循約定式提交格式：`<type>(<scope>): <description>`
- 內容參考 `.github/pull_request_template.md` 模板
- 包含完整的變更說明、測試資訊、檢查清單

**理由:**
標準化的撰寫風格確保版本控制歷史清晰，便於自動生成 release notes 和追蹤變更歷史。一致的格式降低溝通成本。

### IV. AI 行為規範 (AI Behavior Standards)

**規則 (MUST):**
- 絕不假設缺漏的上下文，如有疑問務必提出問題確認
- 嚴禁臆造不存在的函式或套件
- 在程式碼或測試中引用檔案路徑或模組名稱前，務必確認其存在
- 除非有明確指示或任務需求，否則不得刪除或覆蓋現有程式碼
- 需要分析或拆解問題時，通過 sequential thinking 進行深度思考
- 與 GitHub 互動必須使用 gh CLI
- 不准在未經允許的情況下，擅自在任何文檔、訊息等文字中包含 AI 編輯器或 AI 模型的名稱

**理由:**
這些規範確保 AI 助手的行為可預測、安全且尊重現有程式碼。要求確認而非假設可避免引入錯誤或不存在的依賴。

### V. Shell 工具使用 (Shell Tool Standards)

**規則 (MUST):**
使用以下專業工具替代傳統 Unix 指令：

| 任務類型 | 必須使用 | 禁止使用 |
|---------|---------|---------|
| 檔案搜尋 | `fd` | `find`, `ls -R` |
| 文字搜尋 | `rg` (ripgrep) | `grep`, `ag` |
| 程式碼結構分析 | `ast-grep` | `grep`, `sed` |
| 互動式選擇 | `fzf` | 手動篩選 |
| 處理 JSON | `jq` | `python -m json.tool` |
| 處理 YAML/XML | `yq` | 手動解析 |

**理由:**
現代化工具提供更好的效能、更友善的輸出格式和更強大的功能。統一工具使用確保團隊協作一致性。

## Development Workflow

### CSS 修改流程

**新增樣式檔案:**
1. 在 `assets/css/custom/` 建立新的 `.css` 檔案
2. 使用 `kebab-case` 命名
3. 無需額外配置，系統自動偵測並載入

**修改現有樣式:**
- 直接編輯 `assets/css/custom/` 下對應的檔案

**移除樣式檔案:**
- 直接刪除 `assets/css/custom/` 下的檔案

### Git 工作流程

**Pre-commit Hook:**
- 自動更新已修改的 Markdown 檔案的 `lastmod` 欄位
- 為 `date` 與今日不同的檔案新增 `lastmod` 欄位
- 使用台北時區（Asia/Taipei）

**分支命名:**
- 遵循 Conventional Branch Naming
- 範例：`feat/add-new-feature`, `fix/correct-typo`

**Commit 規範:**
- 第一行用於 GitHub 自動生成 release notes
- 內容主體用於複雜變更的詳細解釋
- 腳註用於破壞性變更和問題參考

## Governance

### 憲法優先級

本憲法優先於所有其他實踐規範和指引。所有專案活動（程式碼變更、文檔更新、工具使用）必須符合憲法原則。

### 修正程序

**憲法修正需要:**
1. 在 `.specify/memory/constitution.md` 中記錄變更
2. 更新版本號（遵循語義化版本）
3. 更新 `LAST_AMENDED_DATE` 為修正日期
4. 驗證相關模板檔案的一致性
5. 產生 Sync Impact Report

### 版本控制規則

**版本號格式:** MAJOR.MINOR.PATCH

- **MAJOR**: 向後不相容的治理/原則移除或重新定義
- **MINOR**: 新增原則/章節或實質擴展指引
- **PATCH**: 澄清、措辭、錯字修正、非語義精煉

### 合規性審查

**所有 PR/審查必須驗證:**
- CSS 變更是否僅限於 `assets/css/custom/` 目錄
- 語言使用是否符合規範
- Commit 訊息格式是否正確
- 未使用禁止的 Shell 指令
- 未假設或臆造不存在的資源

**複雜性審查:**
如有違反原則的情況，必須在 `plan.md` 的 Complexity Tracking 區段中提供正當理由。

### 指引文件

**主要指引文件:**
- `CLAUDE.md`: AI 助手的運行時開發指引（本憲法的來源文件）
- `.github/pull_request_template.md`: PR 模板
- `.specify/templates/`: 各類工作流程模板

**一致性要求:**
憲法修正後，必須檢查並更新所有依賴模板以保持一致性。

---

**Version**: 1.0.0 | **Ratified**: 2025-12-26 | **Last Amended**: 2025-12-26
