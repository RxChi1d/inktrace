# Implementation Plan: 遷移至 Blowfish 原生 GitHub Alert 支援

**Branch**: `001-migrate-github-alerts` | **Date**: 2025-12-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-migrate-github-alerts/spec.md`

## Summary

本專案旨在將 Hugo 部落格從自訂的 GitHub Alert（Callout）實作遷移至 Blowfish 2.94.0 主題的原生 Admonition 系統。研究發現 Blowfish 2.94.0 不僅支援 GitHub Alert，更提供完整的 Admonition 功能（15 種類型 + 14 個別名），完全涵蓋自訂實作的所有核心功能（自訂標題、可摺疊、多語言），且功能更強大。

**技術策略**: 採用漸進式遷移，分兩階段執行：
1. **P1 階段**: 移除所有自訂代碼（HTML render hook、CSS 樣式、i18n 翻譯鍵、文檔參考），驗證功能失效
2. **P2 階段**: 升級 Blowfish submodule 至 v2.94.0，驗證功能恢復
3. **專案需求**: admonition 標題統一使用預設語(英文)（不配置 zh-TW 翻譯）

每個階段完成後執行 `npm run build`、git commit 並進行人工驗證，失敗時使用 `git reset --hard` 回滾。

## Technical Context

**Language/Version**: N/A（此為代碼移除和主題升級任務）
**Primary Dependencies**:
- Hugo Extended（現有版本）
- Blowfish 主題 2.94.0（Git submodule）
- Node.js + npm（用於 `npm run build`）

**Storage**: N/A（靜態網站，無資料庫）
**Testing**: 人工視覺驗證（透過 `hugo server` + Chrome DevTools）
**Target Platform**: macOS 開發環境 + Hugo 靜態網站生成
**Project Type**: Hugo 靜態網站（單一專案類型）
**Performance Goals**: 建置時間應與現有水平相當（<5 秒）
**Constraints**:
- 必須保留所有文章內容不變
- 不得影響網站其他功能（導航、標籤、分類、搜尋等）
- 必須使用 `rg` 而非 `grep` 進行代碼搜尋（符合憲法 Shell 工具規範）
- admonition 標題統一使用英文（專案需求）

**Scale/Scope**:
- 需移除 4 個核心文件
- 需更新 2 個 i18n 翻譯文件（移除 7-17 行）
- 需更新 2 個文檔文件
- 測試至少 1 篇包含多個 admonition 的文章

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. 模組化 CSS 管理

✅ **通過**: 移除 `assets/css/custom/blockquote-alerts.css` 符合模組化 CSS 管理原則，且不會修改主題文件。所有自訂 CSS 移除後，將完全依賴 Blowfish 主題的 Admonition 樣式系統（`themes/blowfish/assets/css/components/admonition.css`）。

### II. 語言規則

✅ **通過**:
- 所有文檔（research.md, plan.md）使用 zh-TW
- Commit 訊息將使用 zh-TW 並遵循 Conventional Commit 格式
- admonition 標題將顯示英文（專案需求，透過 Blowfish 預設行為實現）

### III. 撰寫風格與格式

✅ **通過**:
- Commit 訊息遵循 Conventional Commit 格式和 Google 風格
- 專案文檔（research.md, plan.md）遵循 Google 風格
- 每階段 commit 格式範例：`refactor(alert): 移除自訂 GitHub Alert 渲染邏輯`

### IV. AI 行為規範

✅ **通過**:
- 已透過 Explore agent 和代碼檢查確認所有要移除的文件確實存在
- 已驗證 Blowfish 2.94.0 的實際 admonition 實作（透過讀取 render-blockquote.html 和 admonition.css）
- 使用 `rg` 進行代碼搜尋（符合規範）
- 不會臆造或假設不存在的功能

### V. Shell 工具使用

✅ **通過**:
- 使用 `rg` 而非 `grep` 進行文字搜尋
- 使用 `fd` 而非 `find` 進行檔案搜尋（如需要）
- 符合憲法 Shell 工具規範

### 憲法符合性總結

所有核心原則均已滿足，無需在 Complexity Tracking 區段提供違反理由。

**Phase 0 研究狀態**: ✅ 已完成（[research.md](research.md) 完整且詳細）

## Project Structure

### Documentation (this feature)

```text
specs/001-migrate-github-alerts/
├── plan.md              # 此文件（實作計劃）
├── spec.md              # 功能規格（已完成）
├── research.md          # Phase 0 研究輸出（已完成）
├── checklists/
│   └── requirements.md  # 規格品質檢查（已完成）
└── tasks.md             # Phase 2 輸出（將由 /speckit.tasks 生成）
```

**說明**: 此為代碼移除和主題升級任務，不需要 `data-model.md`、`contracts/` 或 `quickstart.md`。

### Source Code (repository root)

此專案為 Hugo 靜態網站，遷移將涉及以下目錄和文件：

```text
/Users/rxchi1d/github-repositories/inktrace-blowfish/
├── layouts/
│   └── _default/
│       └── _markup/
│           └── render-blockquote.html   # [P1 移除] 自訂 blockquote 渲染邏輯
├── assets/
│   └── css/
│       └── custom/
│           └── blockquote-alerts.css    # [P1 移除] Alert 樣式（230 行）
├── i18n/
│   ├── zh-TW.yaml                       # [P1 更新] 移除第 7-17 行（alert 翻譯鍵）
│   └── en.yaml                          # [P1 更新] 移除第 7-17 行（alert 翻譯鍵）
├── content/
│   └── posts/                           # [不變] 文章內容保持不變
│       └── container-platform/
│           └── n8n 容器部署教學/
│               └── index.md             # [驗證用] 測試文章，包含多個 admonition
├── themes/
│   └── blowfish/                        # [P2 升級] Submodule 從 v2.93.0 → v2.94.0
├── CLAUDE.md                            # [P1 更新] 移除第 19 行（alert 文檔參考）
└── layout_notes.md                      # [P1 更新] 移除第 16-17 行（alert 功能描述）
```

**Structure Decision**: 採用 Hugo 專案標準結構，此次遷移僅涉及：
1. 移除專案層級的自訂代碼（layouts, assets, i18n）
2. 升級主題 submodule（themes/blowfish）
3. 更新專案文檔（CLAUDE.md, layout_notes.md）

不涉及新增目錄或重組結構。所有變更都在現有目錄中進行。

## Complexity Tracking

**無憲法違反項目需要追蹤。**

## Phase 0: Research (✅ Completed)

Phase 0 研究已完成並記錄於 [research.md](research.md)。關鍵發現：

### 關鍵發現摘要

1. **Blowfish 2.94.0 提供完整 Admonition 系統**:
   - 支援 15 種獨特類型 + 14 個別名（總計 29 種語法變體）
   - 完全支援自訂標題（`.AlertTitle`）
   - 完全支援可摺疊功能（`.AlertSign`: `+`/`-`）
   - 完整 i18n 支援（`admonition.*` 翻譯鍵）

2. **自訂實作的 10 種類型全部相容**:
   - 8 種直接支援：note, info, tip, important, warning, caution, danger, success
   - 2 種透過別名映射：error → danger, check → success

3. **無功能損失，反而功能增強**:
   - 自訂實作：10 種類型
   - Blowfish 2.94.0：15 種類型（額外提供 abstract, todo, question, failure, bug）

### 遷移策略

基於研究結果，確定以下策略（詳見 [research.md](research.md#遷移策略)）：

1. **完全移除自訂實作**（選項 A）
2. **手動兩步驟更新 submodule**（選項 C）
3. **兩階段人工驗證**（P1 驗證失效，P2 驗證恢復）
4. **i18n 翻譯鍵移除**（統一使用英文標題）

### 風險評估

整體風險等級：**低**（詳見 [research.md](research.md#風險與緩解)）

- i18n 翻譯鍵移除：**低**（符合專案需求）
- 視覺樣式差異：**低**（P2 驗證後調整）
- CSS 類別變更：**低**（將確認無其他依賴）
- Submodule 更新失敗：**低**（使用明確 git 指令）

## Phase 1: Design & Contracts (N/A)

**此階段不適用**:

此專案為代碼移除和主題升級任務，不涉及：
- 資料模型設計（無需 `data-model.md`）
- API 契約定義（無需 `contracts/`）
- 快速入門指南（無需 `quickstart.md`）

所有實作細節已在 Phase 0 研究中完成，包括：
- 需移除的文件清單（[research.md](research.md#核心文件識別)）
- Blowfish 2.94.0 功能對比（[research.md](research.md#功能對比)）
- 遷移影響評估（[research.md](research.md#遷移影響評估)）

## Next Steps

Phase 0 和 Phase 1 已完成（或標記為不適用）。下一階段為：

**Phase 2: Task Breakdown** (`/speckit.tasks`)

將根據本計劃和研究文檔生成詳細的任務分解（`tasks.md`），包括：
- P1 階段任務：移除自訂代碼
- P2 階段任務：升級 Blowfish submodule
- P3 階段任務：驗證遷移完整性
- 每個任務的具體執行步驟、驗證標準和回滾策略

**執行 `/speckit.tasks` 即可開始任務分解階段。**
