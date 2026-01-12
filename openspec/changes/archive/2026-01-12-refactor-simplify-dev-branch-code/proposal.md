# Proposal: Simplify Dev Branch Code

## Change ID
`refactor-simplify-dev-branch-code`

## Status
Draft

## Summary
對 dev 分支中相較於 main 分支的所有程式碼變更進行保守優化，包括 HTML 模板、CSS 樣式檔案和 Shell 腳本。目標是在保持功能完整性和 Blowfish 主題一致性的前提下，簡化程式碼、提升可維護性。

## Why

### Problem Statement
目前 dev 分支的程式碼雖然功能正常，但存在可維護性問題：

1. **HTML 模板缺乏文檔**：覆蓋 Blowfish 原生模板時未說明原因，增加未來維護難度
2. **CSS 選擇器過於複雜**：部分選擇器達 7 層深度，降低可維護性和效能
3. **Shell 腳本有重複代碼**：categories 和 tags 驗證邏輯重複 ~80 行

### Business Value
- 降低維護成本：清晰的註解和簡化的程式碼結構
- 提升開發效率：減少重複代碼，單一真實來源
- 改善效能：簡化 CSS 選擇器，減少瀏覽器計算負擔
- 確保品質：完整的測試覆蓋，視覺回歸驗證

## What Changes

### Code Changes
1. **HTML Templates** (7 files):
   - Add comprehensive English comments explaining override reasons
   - Reference Blowfish base commit (f9eb1d4e) and PR #2714
   - Remove empty trailing divs

2. **CSS Stylesheets** (5 files):
   - Simplify selectors from 7 layers to ≤3 layers
   - Add English comments for design decisions
   - Document browser compatibility (backdrop-filter)

3. **Shell Scripts** (2 files):
   - Extract duplicate logic into reusable functions
   - Standardize error message format
   - Replace external commands (sed) with Bash native features

### Documentation Changes
- `VALIDATION_REPORT.md`: Comprehensive validation results
- `TASK_3.2_SUMMARY.md`: Detailed optimization summary for Task 3.2
- `tasks.md`: Complete checklist with all items marked as done

## Background

### Current State
dev 分支包含以下主要變更：

1. **HTML 模板覆蓋** (layouts/):
   - 新增 `data-taxonomy` 屬性供 CSS 精準選擇
   - 實作 Summary Line Clamp 功能 (對齊 Blowfish PR #2714)
   - 區分 categories/tags 的顯示樣式

2. **CSS 樣式重構** (assets/css/custom/):
   - 模組化 CSS 組織 (design tokens, utilities)
   - 使用 `[data-taxonomy]` selector 區分 taxonomy 類型
   - Glass effect 覆蓋 Blowfish 原生 card 樣式

3. **Taxonomy 管理機制** (script/):
   - SSOT (Single Source of Truth) 機制
   - 自動生成 _index 檔案
   - Pre-commit 驗證腳本

### Problem
目前程式碼存在以下可優化空間：

1. **HTML 模板**：
   - 部分模板保留了過多 Blowfish 原始碼但實際只需最小修改
   - 註解說明不足，未來維護者難以理解覆蓋原因

2. **CSS 樣式**：
   - 選擇器過於具體，降低可維護性
   - 存在重複的樣式規則
   - 部分 CSS 變數命名不夠語意化

3. **Shell 腳本**：
   - 錯誤處理邏輯冗餘
   - 變數命名可以更清晰
   - 部分條件判斷可以簡化

## Goals

### Primary Goals
1. 簡化 HTML 模板覆蓋，保持與 Blowfish 原生邏輯的最高一致性
2. 優化 CSS 選擇器和規則，提升可維護性和效能
3. 重構 Shell 腳本，改善錯誤處理和輸出訊息

### Non-Goals
- 不改變任何功能行為
- 不進行大規模重構或架構調整
- 不引入新的依賴或工具

## Proposed Solution

### Approach
採用保守優化策略，遵循以下原則：

1. **HTML 模板**：
   - 保持最小修改原則
   - 加入清晰的英文註解說明覆蓋原因
   - 確保與 Blowfish 原生模板的結構一致

2. **CSS 樣式**：
   - 簡化選擇器層級
   - 合併重複規則
   - 改善變數命名
   - 優化 media query

3. **Shell 腳本**：
   - 簡化錯誤檢查邏輯
   - 統一輸出格式
   - 改善變數命名

### Scope
- **包含**：所有 dev 分支相較於 main 的程式碼變更
- **排除**：文檔檔案、content 內容檔案

## Impact Analysis

### Benefits
- 提升程式碼可讀性和可維護性
- 降低未來升級 Blowfish 主題的成本
- 改善 CSS 效能（減少選擇器複雜度）
- 增強 Shell 腳本的健壯性

### Risks
- 需要仔細測試確保功能不受影響
- CSS 優化可能需要調整選擇器權重

### Migration Path
無需遷移，直接在 dev 分支優化即可。

## Testing Requirements
優化完成後必須進行以下測試：

1. **視覺回歸測試**（必要）
   - 比對優化前後的頁面截圖
   - 確認無視覺差異

2. **響應式測試**（必要）
   - 測試不同螢幕尺寸的顯示效果
   - 涵蓋 mobile, tablet, desktop 斷點

3. **驗證層級**：
   - **基本驗證**：執行 `hugo` 建置，確認 HTML 正確生成至 `public/` 目錄
   - **進階驗證**：使用 Chrome DevTools 檢查 CSS 選擇器、效能和視覺效果

## Related Changes
- 相關 specs: `theme-overrides`, `card-layout`, `taxonomy-display`
- 前置依賴: 無（當前 dev 分支已包含所有必要變更）

## Approval Checklist
- [ ] 方案符合專案憲法原則
- [ ] 保持與 Blowfish 主題的一致性
- [ ] 所有變更都有適當的測試計劃
- [ ] 文檔更新計劃已確認
