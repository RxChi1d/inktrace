# Tasks: 遷移至 Blowfish 原生 GitHub Alert 支援

**Input**: Design documents from `/specs/001-migrate-github-alerts/`
**Prerequisites**: spec.md (user stories), plan.md (technical strategy), research.md (migration analysis)

**Tests**: 此專案使用人工驗證策略，不包含自動化測試任務

**Organization**: 任務按照使用者故事（P1, P2, P3）組織，確保每個階段可以獨立執行和驗證

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可以並行執行（不同文件，無依賴關係）
- **[Story]**: 任務所屬的使用者故事（例如：US1, US2, US3）
- 包含確切的文件路徑

## Path Conventions

此專案為 Hugo 靜態網站，結構如下：
- **Hugo 專案根目錄**: `/Users/rxchi1d/github-repositories/inktrace-blowfish/`
- **自訂代碼**: `layouts/`, `assets/css/custom/`, `i18n/`
- **主題**: `themes/blowfish/` (Git submodule)
- **文章內容**: `content/posts/`
- **專案文檔**: `CLAUDE.md`, `layout_notes.md`

---

## Phase 1: Setup（專案準備）

**Purpose**: 確認專案環境和前置條件

- [x] T001 驗證 Git repository 狀態乾淨，無未提交的變更 (`specs/*` 除外)
- [x] T002 [P] 確認 Node.js 和 npm 可用，執行 `npm --version` 驗證
- [x] T003 [P] 確認 Hugo Extended 可用，執行 `hugo version` 驗證
- [x] T004 [P] 確認 `rg` (ripgrep) 可用，執行 `rg --version` 驗證
- [x] T005 驗證 Blowfish submodule 已初始化，執行 `git submodule status` 檢查 themes/blowfish

---

## Phase 2: Foundational（無此階段）

**Purpose**: 此專案為代碼移除和主題升級任務，無需建立基礎設施

**Note**: 跳過此階段，直接進入 User Story 實作

---

## Phase 3: User Story 1 - 移除自訂 GitHub Alert 程式碼（Priority: P1）🎯 MVP

**Goal**: 安全地移除所有自訂的 GitHub Alert 相關程式碼，包括渲染邏輯、樣式檔案、i18n 翻譯鍵和文檔參考

**Independent Test**: 執行 `npm run build` 和 `hugo server` 後，瀏覽包含 GitHub Alert 的文章，確認 alert 樣式已失效（不顯示或顯示為純文字），且其他頁面功能正常

**Acceptance Criteria**:
- 所有相關的 HTML 模板檔案、CSS 樣式檔案已移除
- i18n 翻譯檔案中的 alert 翻譯鍵已移除（7-17 行）
- 文檔文件中的 alert 參考已移除
- GitHub Alert 功能失效
- 其他頁面功能（首頁、標籤、分類、導航）正常
- 瀏覽器控制台無錯誤訊息

### Implementation for User Story 1

- [x] T006 [P] [US1] 使用 `rg` 搜尋 content 目錄中包含 GitHub Alert 語法的文章，識別測試樣本（搜尋模式：`> \[!NOTE\]`、`> \[!TIP\]` 等）
- [x] T007 [P] [US1] 使用 `rg` 搜尋 `.custom-alert` CSS 類別引用，確認無其他功能依賴（搜尋路徑：assets/, layouts/）
- [x] T008 [US1] 移除自訂 blockquote 渲染邏輯：刪除整個文件 layouts/_default/_markup/render-blockquote.html
- [x] T009 [US1] 移除自訂 alert 樣式：刪除整個文件 assets/css/custom/blockquote-alerts.css
- [x] T010 [US1] 移除 zh-TW i18n 翻譯鍵：編輯 i18n/zh-TW.yaml，刪除第 7-17 行（alert 相關翻譯）
- [x] T011 [US1] 移除 en i18n 翻譯鍵：編輯 i18n/en.yaml，刪除第 7-17 行（alert 相關翻譯）
- [x] T012 [US1] 更新 CLAUDE.md 文檔：移除第 19 行（blockquote-alerts.css 範例參考）
- [x] T013 [US1] 更新 layout_notes.md 文檔：移除第 16-17 行（GitHub Alert 功能描述）
- [x] T014 [US1] 執行 `npm run build` 重建 CSS 樣式
- [x] T015 [US1] 提交變更：使用 commit 訊息 `refactor(alert): 移除自訂 GitHub Alert 實作`，包含完整的變更說明和測試計劃參考
- [x] T016 [US1] 驗證 P1 階段：啟動 `hugo server`，執行人工驗證 checklist（見下方）

**P1 驗證 Checklist**（人工執行）:
1. 瀏覽測試文章 `content/posts/container-platform/n8n 容器部署教學/index.md`
   - [x] GitHub Alert 樣式失效（不顯示或顯示為純文字）
2. 檢查其他頁面功能
   - [x] 首頁正常顯示
   - [x] 標籤頁正常顯示
   - [x] 分類頁正常顯示
   - [x] 導航功能正常
3. 檢查瀏覽器控制台
   - [x] 無 JavaScript 錯誤
   - [x] 無 CSS 載入錯誤

**Rollback Strategy（如果驗證失敗）**:
```bash
git reset --hard HEAD^  # 回滾到上一個 commit
# 然後重新執行 T006-T016
```

**Checkpoint**: 此階段完成後，自訂 GitHub Alert 代碼已完全移除，alert 功能應該失效

---

## Phase 4: User Story 2 - 升級 Blowfish 主題至 2.94.0（Priority: P2）

**Goal**: 將 Blowfish 主題的 Git submodule 更新至 v2.94.0，啟用原生的 Admonition 支援功能

**Independent Test**: 檢查 themes/blowfish 的 git tag 為 v2.94.0，執行 `npm run build` 和 `hugo server` 後，瀏覽包含 GitHub Alert 的文章，確認 alert 功能已恢復且正確顯示（包含圖示、顏色、邊框）

**Acceptance Criteria**:
- Blowfish submodule 版本為 v2.94.0
- GitHub Alert 使用 Blowfish 原生樣式正確顯示
- 所有類型的 alert（NOTE、TIP、IMPORTANT、WARNING、CAUTION）正確渲染
- admonition 標題顯示英文（視覺樣式為首字母大寫）
- 其他頁面功能持續正常
- 瀏覽器控制台無錯誤訊息

### Implementation for User Story 2

- [x] T017 [US2] 進入 Blowfish submodule 目錄：`cd themes/blowfish`
- [x] T018 [US2] 拉取所有遠端標籤：執行 `git fetch --all --tags`
- [x] T019 [US2] 切換至 v2.94.0 標籤：執行 `git checkout v2.94.0`
- [x] T020 [US2] 驗證當前版本：執行 `git describe --tags` 確認輸出為 `v2.94.0`
- [x] T021 [US2] 返回專案根目錄：`cd ../..`
- [x] T022 [US2] 將 submodule 變更加入 staging：執行 `git add themes/blowfish`
- [x] T023 [US2] 執行 `npm run build` 重建 CSS 樣式
- [ ] T024 [US2] 提交變更：使用 commit 訊息 `chore(theme): 升級 Blowfish 主題至 v2.94.0`，包含完整的變更說明和測試計劃參考
- [x] T025 [US2] 驗證 P2 階段：啟動 `hugo server`，執行人工驗證 checklist（見下方）

**P2 驗證 Checklist**（人工執行）:
1. 瀏覽測試文章 `content/posts/container-platform/n8n 容器部署教學/index.md`
   - [x] NOTE alert 正確顯示（藍色、info icon、英文標題 "Note"）
   - [x] TIP alert 正確顯示（綠色、lightbulb icon、英文標題 "Tip"）
   - [x] IMPORTANT alert 正確顯示（紫色、star icon、英文標題 "Important"）
   - [x] WARNING alert 正確顯示（橙色、triangle-exclamation icon、英文標題 "Warning"）
   - [x] CAUTION alert 正確顯示（紅色、fire icon、英文標題 "Caution"）
   - [x] 自訂標題功能正常（如使用 `> [!NOTE] 自訂標題`）
   - [x] 可摺疊功能正常（如使用 `+` 或 `-`）
2. 檢查其他頁面功能
   - [x] 首頁正常顯示
   - [x] 標籤頁正常顯示
   - [x] 分類頁正常顯示
   - [x] 導航功能正常
3. 檢查瀏覽器控制台
   - [x] 無 JavaScript 錯誤
   - [x] 無 CSS 載入錯誤
4. 使用 Chrome DevTools 檢查 alert 元素
   - [x] 樣式來自 Blowfish 主題（非自訂 CSS）
   - [x] CSS 類別為 `.admonition` 和 `[data-type="{type}"]`

**Rollback Strategy（如果驗證失敗）**:
```bash
git reset --hard HEAD^  # 回滾到上一個 commit
cd themes/blowfish
git checkout <previous-commit-hash>  # 切換回原版本
cd ../..
# 然後重新執行 T017-T025
```

**Checkpoint**: 此階段完成後，Blowfish 主題已升級至 v2.94.0，alert 功能應該完全由 Blowfish 原生支援接管

---

## Phase 5: User Story 3 - 驗證遷移完整性（Priority: P3）

**Goal**: 全面驗證遷移後的網站功能，確保 GitHub Alert 功能完全由 Blowfish 原生支援接管，且沒有遺留的自訂程式碼或樣式衝突

**Independent Test**: 執行完整的網站渲染測試，包括檢查所有包含 GitHub Alert 的文章、驗證樣式一致性、使用代碼搜尋工具確認無自訂實作殘留

**Acceptance Criteria**:
- 代碼庫中不存在任何自訂的 alert 實作程式碼
- 所有 alert 樣式來自 Blowfish 主題
- Hugo 建置過程無錯誤或警告
- 所有包含 alert 的文章正確渲染

### Implementation for User Story 3

- [ ] T026 [P] [US3] 使用 `rg` 搜尋 layouts/ 目錄中的 "alert" 關鍵字，確認無自訂 alert 渲染邏輯殘留
- [ ] T027 [P] [US3] 使用 `rg` 搜尋 assets/ 目錄中的 "custom-alert" 或 "blockquote-alert" 關鍵字，確認無自訂 CSS 殘留
- [ ] T028 [P] [US3] 使用 `rg` 搜尋 i18n/ 目錄中的 "note:" 或 "tip:" 關鍵字（頂層鍵），確認自訂翻譯鍵已移除
- [ ] T029 [P] [US3] 檢查 CLAUDE.md 和 layout_notes.md，確認無 blockquote-alerts.css 或 GitHub Alert 功能參考
- [ ] T030 [US3] 執行完整建置：`npm run build` 並檢查輸出無錯誤或警告
- [ ] T031 [US3] 使用 `rg '> \[!' content/` 搜尋所有包含 alert 語法的文章，建立測試清單
- [ ] T032 [US3] 逐一瀏覽測試清單中的文章，驗證所有 alert 類型正確顯示
- [ ] T033 [US3] 使用 Chrome DevTools 檢查至少 3 篇文章的 alert 元素，確認樣式來源為 Blowfish 主題
- [ ] T034 [US3] 驗證 alert 標題顯示為英文（視覺樣式為首字母大寫），符合專案需求
- [ ] T035 [US3] 最終驗證：執行完整的網站導航測試（首頁、文章列表、標籤、分類、搜尋）

**P3 驗證 Checklist**（人工執行）:
1. 代碼搜尋驗證
   - [ ] `rg "alert" layouts/` 無結果或僅有主題文件
   - [ ] `rg "custom-alert" assets/` 無結果
   - [ ] `rg "^note:" i18n/` 無結果（頂層鍵）
   - [ ] `rg "blockquote-alerts" .` 無結果（僅在 specs/ 目錄有文檔參考）
2. 建置驗證
   - [ ] `npm run build` 成功完成
   - [ ] 無錯誤訊息
   - [ ] 無警告訊息
3. 視覺驗證
   - [ ] 所有測試文章的 alert 正確顯示
   - [ ] alert 標題統一顯示英文（視覺樣式為首字母大寫）
   - [ ] 樣式來自 Blowfish 主題（使用 DevTools 確認）
4. 功能驗證
   - [ ] 網站所有頁面正常顯示
   - [ ] 瀏覽器控制台無錯誤

**Checkpoint**: 遷移完全成功，所有驗證通過

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 最終清理和文檔更新

- [ ] T036 [P] 更新 specs/001-migrate-github-alerts/plan.md 狀態為 "Completed"
- [ ] T037 [P] 如有需要，在 specs/001-migrate-github-alerts/ 建立遷移完成報告（migration-report.md）
- [ ] T038 審查所有 commit 訊息，確保符合 Conventional Commits 格式
- [ ] T039 如有需要，執行 git rebase 整理 commit 歷史（可選）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 無依賴 - 可立即開始
- **Foundational (Phase 2)**: N/A（此專案無此階段）
- **User Stories (Phase 3-5)**: 必須按照優先級順序執行
  - Phase 3 (US1): 依賴 Phase 1 完成
  - Phase 4 (US2): 依賴 Phase 3 (US1) 完成並驗證通過
  - Phase 5 (US3): 依賴 Phase 4 (US2) 完成並驗證通過
- **Polish (Phase 6)**: 依賴所有 User Stories 完成

### User Story Dependencies

- **User Story 1 (P1)**: 移除自訂代碼 - 必須先完成，阻塞 US2
- **User Story 2 (P2)**: 升級主題 - 依賴 US1 完成，阻塞 US3
- **User Story 3 (P3)**: 驗證遷移 - 依賴 US1 和 US2 完成

**重要**: 此專案的 User Stories 必須順序執行，無法並行，因為 US2 依賴 US1 的完成狀態，US3 依賴 US1 和 US2 的完成狀態。

### Within Each User Story

- User Story 1:
  - T006-T007 [P] 可並行（搜尋任務）
  - T008-T013 依序執行（文件移除和編輯）
  - T014-T016 依序執行（建置、提交、驗證）

- User Story 2:
  - T017-T025 必須依序執行（Git submodule 操作步驟）

- User Story 3:
  - T026-T029 [P] 可並行（代碼搜尋驗證）
  - T030-T035 依序執行（建置和視覺驗證）

### Parallel Opportunities

- **Phase 1 Setup**: T002, T003, T004 可並行
- **Phase 3 US1**: T006, T007 可並行
- **Phase 5 US3**: T026, T027, T028, T029 可並行
- **Phase 6 Polish**: T036, T037 可並行

---

## Parallel Example: User Story 1

```bash
# 並行執行搜尋任務（T006-T007）:
Task: "使用 rg 搜尋 content 目錄中包含 GitHub Alert 語法的文章"
Task: "使用 rg 搜尋 .custom-alert CSS 類別引用"

# 並行執行文檔更新（T012-T013）:
Task: "更新 CLAUDE.md 文檔"
Task: "更新 layout_notes.md 文檔"
```

## Parallel Example: User Story 3

```bash
# 並行執行代碼搜尋驗證（T026-T029）:
Task: "使用 rg 搜尋 layouts/ 目錄中的 alert 關鍵字"
Task: "使用 rg 搜尋 assets/ 目錄中的 custom-alert 關鍵字"
Task: "使用 rg 搜尋 i18n/ 目錄中的頂層翻譯鍵"
Task: "檢查 CLAUDE.md 和 layout_notes.md 文檔"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup（完成專案環境驗證）
2. Complete Phase 3: User Story 1（移除自訂代碼）
3. **STOP and VALIDATE**: 執行 P1 驗證 checklist，確認 alert 功能失效但其他功能正常
4. 如驗證失敗，使用 `git reset --hard` 回滾並重試

### Incremental Delivery

1. Setup → 環境準備就緒
2. User Story 1 → 自訂代碼移除完成 → 驗證通過 → Commit
3. User Story 2 → Blowfish 升級完成 → 驗證通過 → Commit
4. User Story 3 → 完整驗證通過 → 遷移完成
5. Polish → 文檔更新和最終清理

### Sequential Strategy（此專案必須採用）

由於 User Stories 之間存在強依賴關係，必須順序執行：

1. 完成 Phase 1: Setup
2. 完成 Phase 3: User Story 1 → 驗證通過
3. 完成 Phase 4: User Story 2 → 驗證通過
4. 完成 Phase 5: User Story 3 → 驗證通過
5. 完成 Phase 6: Polish

**不支援並行團隊策略**，因為每個 User Story 必須等待前一個完成並驗證通過。

---

## Notes

- [P] 任務 = 不同文件，無依賴關係，可並行執行
- [Story] 標籤映射任務到特定使用者故事，便於追蹤
- 每個 User Story 必須獨立驗證後才能進入下一個
- 使用 `rg` 而非 `grep` 進行代碼搜尋（符合憲法規範）
- 每個階段完成後提交 commit，便於回滾
- 驗證失敗時使用 `git reset --hard HEAD^` 回滾
- Commit 訊息必須遵循 Conventional Commits 格式
- 所有變更使用 zh-TW 撰寫 commit 訊息
- admonition 標題將統一顯示英文小寫（符合專案需求）
- 避免：模糊的任務描述、同一文件衝突、破壞獨立性的跨故事依賴

---

## Task Count Summary

- **Total Tasks**: 39 tasks
- **Phase 1 (Setup)**: 5 tasks
- **Phase 3 (User Story 1)**: 11 tasks
- **Phase 4 (User Story 2)**: 9 tasks
- **Phase 5 (User Story 3)**: 10 tasks
- **Phase 6 (Polish)**: 4 tasks

**Parallel Opportunities**: 11 tasks marked [P] across all phases

**Suggested MVP Scope**: Phase 1 + Phase 3 (User Story 1) = 16 tasks
