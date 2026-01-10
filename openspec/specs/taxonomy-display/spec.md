# taxonomy-display Specification

## Purpose
TBD - created by archiving change restore-native-cards. Update Purpose after archive.
## Requirements
### Requirement: Custom Visibility Parameters Removal
The system SHALL NOT support `showCategories` and `showTags` configuration parameters.

#### Scenario: Configuration Cleanup
-   **Given** the `config/_default/params.toml` file.
-   **When** examined.
-   **Then** `showCategories` and `showTags` keys MUST be absent.

### Requirement: Taxonomy Badge Links
Taxonomy badges MUST be rendered as standard HTML Anchor tags (`<a>`).

#### Scenario: Badge Interactivity
-   **Given** a taxonomy badge on an article card.
-   **When** inspected.
-   **Then** it MUST be an `<a>` tag with an `href` attribute pointing to the taxonomy term page.
-   **And** it MUST NOT use `onclick` JavaScript handlers for navigation.

#### Scenario: Click Behavior
-   **Given** a taxonomy badge.
-   **When** clicked.
-   **Then** the browser navigates to the taxonomy term page.
-   **And** the click MUST NOT trigger the parent card's article link (z-index handling).

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

### Requirement: Tags Terms Inline Layout
Tags 的 taxonomy 列表頁 MUST 呈現 inline tag cloud 佈局，且單一 tag item 不得被強制固定寬度。

#### Scenario: Tags 列表為 inline tag cloud
- **WHEN** 使用 `terms` 模板渲染 tags 列表頁
- **THEN** tag items 必須以 inline 方式流動排列
- **AND** tag items 不得被 `w-full`/`sm:w-1/2` 類型的固定寬度 class 限制

### Requirement: Categories Terms Card Layout
Categories 的 taxonomy 列表頁 MUST 呈現卡片式 grid 佈局，並顯示 icon 與 Post/Posts 單複數文字。

#### Scenario: Categories 列表為卡片式 grid
- **WHEN** 使用 `terms` 模板渲染 categories 列表頁
- **THEN** 每個 category 必須以卡片形式排列在 grid 佈局中
- **AND** 卡片內需顯示 category icon 與文章數量（Post/Posts 單複數）

### Requirement: Icon 顏色隨主題切換
Taxonomy icon MUST 隨深/淺色模式切換而同步變化。

#### Scenario: 深色模式 icon 顏色一致
- **WHEN** 站點切換為 dark mode
- **THEN** taxonomy icon 顏色 MUST 與對應文字顏色一致
- **AND** 不得出現 icon 顏色固定不變的情況

### Requirement: Categories Icon 與文字間距
Categories 卡片內 icon 與文字 MUST 保持清楚的視覺間距，避免 icon 緊貼文字影響可讀性。

#### Scenario: Icon 與文字間距一致
- **WHEN** 顯示 categories 列表頁卡片
- **THEN** icon 與分類文字之間 MUST 有一致的間距
- **AND** 間距需足以避免 icon 與文字視覺黏連

### Requirement: Term 文章列表不受影響
Taxonomy 列表頁的樣式 MUST NOT 影響 term 文章列表頁的文章卡片樣式。

#### Scenario: Term 頁面樣式隔離
- **WHEN** 進入任一 taxonomy term 文章列表頁
- **THEN** 文章卡片的間距與排版 MUST 維持 Blowfish 原生樣式
- **AND** taxonomy list 的 CSS 不得汙染 term 文章列表

