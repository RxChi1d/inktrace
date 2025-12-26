# Feature Specification: 遷移至 Blowfish 原生 GitHub Alert 支援

**Feature Branch**: `001-migrate-github-alerts`
**Created**: 2025-12-26
**Status**: Draft
**Input**: User description: "在我的專案當中 ，原本有使用自定的方式來設計與支援 github alert 語法，其中當然包含了讀取以及渲染的相關代碼。但是在 Blowfish主題更新至 2.94.0 後，已經原生的支援了相關的語法功能，所以我們代碼庫當中自訂 github alert (callout) 相關配置可以移除了。我需要你仔細的去閱讀當前的代碼庫，找出我們自定的 github alert相關代碼，做安全的移除，要註意不要影響到其他的功能。"

## Clarifications

### Session 2025-12-26

- Q: 建置與驗證流程 - 每個階段完成後需要執行 `npm run build` 並進行人工驗證的時機？ → A: 在 P1 和 P2 兩個階段完成後都必須執行 `npm run build`，並提供對應的驗證 checklist 讓使用者在 `hugo server` 中驗證
- Q: 驗證 Checklist 的具體內容應該包含哪些項目？ → A: P1 階段 checklist 包含：1) GitHub Alert 樣式失效驗證（文章頁面中 alert 不顯示或顯示為純文字）、2) 其他頁面功能正常（首頁、標籤、分類、導航）、3) 瀏覽器控制台無錯誤；P2 階段 checklist 包含：1) GitHub Alert 正確顯示（所有類型的圖示、顏色、邊框）、2) 其他頁面功能持續正常、3) 瀏覽器控制台無錯誤
- Q: 如果驗證階段發現問題，應該採用什麼回滾策略？ → A: 每個階段完成後先進行 git commit，如果驗證失敗，使用 `git reset --hard` 回滾到上一個 commit，然後重新執行該階段
- Q: 如何識別包含 GitHub Alert 的測試文章？ → A: 使用 `content/posts/container-platform/n8n 容器部署教學/index.md` 作為測試文章，該文章包含多個 admonition；同時在實作過程中使用 `rg` 搜尋 content 目錄中包含 GitHub Alert 語法標記的文章（如 `> [!NOTE]`、`> [!TIP]` 等）

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 移除自訂 GitHub Alert 程式碼 (Priority: P1)

作為開發者，我需要安全地移除所有自訂的 GitHub Alert（callout）相關程式碼，包括渲染邏輯、樣式檔案和配置，以便專案能夠乾淨地準備使用 Blowfish 主題的原生支援。

**Why this priority**: 這是遷移的第一步，也是最關鍵的步驟。移除舊程式碼後才能確保沒有衝突並驗證功能確實失效，為後續的主題升級做好準備。

**Independent Test**: 可以透過啟動 Hugo 開發伺服器，瀏覽包含 GitHub Alert 語法的文章頁面，確認 alert 樣式已經失效（不再顯示或顯示為純文字），來驗證自訂程式碼已完全移除。

**Acceptance Scenarios**:

1. **Given** 代碼庫中存在自訂的 GitHub Alert 渲染程式碼，**When** 開發者執行移除操作，**Then** 所有相關的 HTML 模板檔案、CSS 樣式檔案和 JavaScript 檔案都應該被移除
2. **Given** 移除操作完成且執行 `npm run build` 後，**When** 啟動 `hugo server` 並瀏覽包含 GitHub Alert 的文章，**Then** alert 功能應該失效（不顯示或顯示為純文字）
3. **Given** 移除操作完成後，**When** 開發者根據 P1 驗證 checklist 檢查網站，**Then** 應該確認：1) GitHub Alert 樣式已失效、2) 首頁/標籤/分類/導航等其他頁面功能正常、3) 瀏覽器控制台無錯誤訊息

---

### User Story 2 - 升級 Blowfish 主題至 2.94.0 (Priority: P2)

作為開發者，我需要將 Blowfish 主題的 submodule 更新至 2.94.0 版本，以啟用原生的 GitHub Alert 支援功能。

**Why this priority**: 在確認自訂程式碼已完全移除且不影響其他功能後，才能安全地進行主題升級，避免新舊程式碼衝突。

**Independent Test**: 可以透過檢查 themes/blowfish 的 git commit hash 或 tag，確認版本為 2.94.0，並在開發伺服器中瀏覽包含 GitHub Alert 語法的文章，驗證 alert 功能已恢復正常顯示。

**Acceptance Scenarios**:

1. **Given** Blowfish submodule 指向舊版本，**When** 開發者執行 submodule 更新操作，**Then** themes/blowfish 應該切換至 tag 2.94.0 或對應的 commit
2. **Given** Blowfish 已更新至 2.94.0 且執行 `npm run build` 後，**When** 啟動 `hugo server` 並瀏覽包含 GitHub Alert 的文章，**Then** alert 應該使用 Blowfish 原生樣式正確顯示（包含圖示、顏色和邊框）
3. **Given** Blowfish 已更新至 2.94.0 後，**When** 開發者根據 P2 驗證 checklist 檢查網站，**Then** 應該確認：1) 所有類型的 GitHub Alert（NOTE、TIP、IMPORTANT、WARNING、CAUTION）正確顯示、2) 其他頁面功能持續正常、3) 瀏覽器控制台無錯誤訊息

---

### User Story 3 - 驗證遷移完整性 (Priority: P3)

作為開發者，我需要全面驗證遷移後的網站功能，確保 GitHub Alert 功能完全由 Blowfish 原生支援接管，且沒有遺留的自訂程式碼或樣式衝突。

**Why this priority**: 這是最終的品質保證步驟，確保遷移成功且沒有副作用，可以安全地提交變更。

**Independent Test**: 可以透過執行完整的網站渲染測試，包括檢查所有包含 GitHub Alert 的文章、驗證樣式一致性、檢查瀏覽器控制台沒有錯誤訊息，來確認遷移完全成功。

**Acceptance Scenarios**:

1. **Given** 遷移完成後，**When** 開發者使用代碼搜尋工具查找「alert」、「callout」等關鍵字，**Then** 應該不再找到任何自訂的 alert 實作程式碼
2. **Given** 遷移完成後，**When** 開發者在瀏覽器中檢查 alert 元素的樣式來源，**Then** 所有樣式都應該來自 Blowfish 主題，而非自訂的 CSS 檔案
3. **Given** 遷移完成後，**When** 開發者執行 Hugo 建置並檢查輸出，**Then** 建置過程應該沒有警告或錯誤訊息

---

### Edge Cases

- 如果某些文章使用了非標準的 alert 語法格式，移除自訂程式碼後可能無法被 Blowfish 正確解析
- 如果自訂 CSS 中有其他樣式與 alert 樣式混合定義，需要確保移除 alert 樣式時不影響其他樣式
- 如果有其他自訂功能依賴於 alert 相關的 HTML 結構或 CSS 類別，移除後可能導致這些功能失效
- 如果 Blowfish 2.94.0 的 alert 樣式與專案整體設計風格不一致，可能需要額外的樣式覆寫
- 如果驗證失敗需要回滾，必須確保 submodule 狀態也正確回滾到對應的版本

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系統必須能夠識別並移除所有自訂的 GitHub Alert 渲染邏輯（HTML 模板、shortcodes、partial 檔案等）
- **FR-002**: 系統必須能夠識別並移除所有自訂的 GitHub Alert 樣式檔案（CSS 檔案中與 alert 或 callout 相關的樣式規則）
- **FR-003**: 移除操作必須保留專案中其他不相關的自訂樣式和功能
- **FR-004**: Blowfish submodule 必須更新至 tag 2.94.0 或對應的 commit hash
- **FR-005**: 更新後的 Blowfish 主題必須能夠正確渲染所有標準的 GitHub Alert 類型（NOTE、TIP、IMPORTANT、WARNING、CAUTION）
- **FR-006**: 網站的其他核心功能（導航、文章列表、標籤、分類、搜尋等）在移除和升級過程中必須保持正常運作
- **FR-007**: 在 P1（移除自訂程式碼）和 P2（升級主題）階段完成後，系統必須執行 `npm run build` 以確保 CSS 等相關樣式更新
- **FR-008**: P1 階段的驗證 checklist 必須包含：1) GitHub Alert 樣式失效驗證（文章頁面中 alert 不顯示或顯示為純文字）、2) 其他頁面功能正常（首頁、標籤、分類、導航）、3) 瀏覽器控制台無錯誤
- **FR-009**: P2 階段的驗證 checklist 必須包含：1) GitHub Alert 正確顯示（所有類型的圖示、顏色、邊框）、2) 其他頁面功能持續正常、3) 瀏覽器控制台無錯誤
- **FR-010**: 每個階段（P1 和 P2）完成後必須先進行 git commit，然後才進行驗證
- **FR-011**: 如果驗證失敗，必須使用 `git reset --hard` 回滾到上一個 commit，然後重新執行該階段
- **FR-012**: 系統必須能夠使用 `rg` 搜尋 content 目錄中包含 GitHub Alert 語法標記的文章（如 `> [!NOTE]`、`> [!TIP]` 等）
- **FR-013**: 驗證過程必須包含測試文章 `content/posts/container-platform/n8n 容器部署教學/index.md`，該文章包含多個 admonition
- **FR-014**: 所有變更必須透過 git 進行版本控制，並使用符合專案規範的 commit 訊息

### Assumptions

- 假設專案中的 GitHub Alert 語法遵循標準的 GitHub Flavored Markdown 格式
- 假設 Blowfish 2.94.0 的 alert 樣式與專案整體設計風格相容，或可透過最小的 CSS 覆寫調整
- 假設自訂的 GitHub Alert 程式碼沒有被其他功能深度整合或依賴
- 假設開發者具備基本的 Hugo、Git submodule 操作知識

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 移除自訂程式碼後，代碼庫中不應存在任何與「GitHub Alert」或「callout」相關的自訂實作檔案
- **SC-002**: 使用代碼搜尋工具在移除後的代碼庫中搜尋「alert」、「callout」等關鍵字，不應找到任何自訂的渲染邏輯或樣式定義
- **SC-003**: Blowfish submodule 的版本應該為 2.94.0，可透過 `git describe --tags` 或檢查 commit hash 驗證
- **SC-004**: 升級後，所有包含 GitHub Alert 語法的文章頁面都應該正確渲染，alert 元素應該顯示適當的圖示、顏色和邊框樣式
- **SC-005**: 網站的其他功能（首頁、文章列表、標籤頁、分類頁、搜尋功能等）在移除和升級後應該保持 100% 正常運作
- **SC-006**: Hugo 建置過程應該成功完成，沒有錯誤或警告訊息
- **SC-007**: 測試文章 `content/posts/container-platform/n8n 容器部署教學/index.md` 中的所有 admonition 在 P1 階段應該失效，在 P2 階段應該正確顯示
- **SC-008**: 開發者能夠在移除自訂程式碼後和升級主題後各進行一次視覺驗證，確認變更符合預期
