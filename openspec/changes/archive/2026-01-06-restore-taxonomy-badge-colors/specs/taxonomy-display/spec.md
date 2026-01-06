# Taxonomy Display Specification (Delta)

## ADDED Requirements

### Requirement: Category Badge 顏色區分
Category badges SHALL use green color scheme to distinguish from Tag badges.

#### Scenario: Light mode 下 Category badge 顏色正確
- **WHEN** 在 Light mode 下顯示 Category badge
- **THEN** border 使用 `#22c55e` (green-500)
- **AND** text 使用 `#15803d` (green-700)

#### Scenario: Dark mode 下 Category badge 顏色正確
- **WHEN** 在 Dark mode 下顯示 Category badge
- **THEN** border 使用 `#4ade80` (green-400)
- **AND** text 使用 `#86efac` (green-300)

### Requirement: Tag Badge 顏色區分
Tag badges SHALL use blue color scheme to distinguish from Category badges.

#### Scenario: Light mode 下 Tag badge 顏色正確
- **WHEN** 在 Light mode 下顯示 Tag badge
- **THEN** border 使用 `#0ea5e9` (sky-500)
- **AND** text 使用 `#0369a1` (sky-700)

#### Scenario: Dark mode 下 Tag badge 顏色正確
- **WHEN** 在 Dark mode 下顯示 Tag badge
- **THEN** border 使用 `#38bdf8` (sky-400)
- **AND** text 使用 `#7dd3fc` (sky-300)

### Requirement: 純 CSS 實作
Color differentiation MUST be implemented using pure CSS without modifying any Blowfish theme templates.

#### Scenario: 使用 CSS 屬性選擇器實現顏色區分
- **WHEN** 需要區分 Category 和 Tag badges
- **THEN** 使用 `a[href*="/categories/"]` 選擇器目標 Category badges
- **AND** 使用 `a[href*="/tags/"]` 選擇器目標 Tag badges
- **AND** 使用 `span.flex.cursor-pointer > span` 指向 badge 內層元素（避免誤選 term count）
- **AND** 不修改任何 `themes/blowfish/` 下的檔案

#### Scenario: 與 Blowfish 原生模板相容
- **WHEN** Blowfish 主題升級且 badge 結構與 taxonomy 連結路徑維持不變
- **THEN** 顏色區分功能 SHALL 維持正常運作
- **AND** 若結構或路徑變更，CSS selector SHALL 同步調整

### Requirement: 代碼簡潔性
All unused project-level overrides and dead code MUST be removed.

#### Scenario: 移除專案層級 badge.html
- **WHEN** 清理專案層級覆寫
- **THEN** `layouts/partials/badge.html` 被刪除
- **AND** 所有 badge 呼叫自動 fallback 到 Blowfish 原生版本

#### Scenario: 清理未使用的 CSS class
- **WHEN** 移除專案層級 badge.html
- **THEN** 相關的自訂 CSS class (`.badge-custom`, `.badge-inner`, `.badge-category`, `.badge-tag`) 被移除
- **AND** `assets/css/custom/global.css` 中的未使用樣式被清理
