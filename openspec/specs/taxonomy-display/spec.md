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
所有視覺優化 MUST 透過純 CSS 實現，不得修改 HTML 模板。

#### Scenario: 依賴現有 HTML 結構
- **WHEN** 實作視覺優化
- **THEN** MUST 使用現有的 `data-taxonomy` 屬性進行選擇器定位
- **AND** MUST 使用現有的 HTML 元素結構（article, h2, a, span）
- **AND** NOT 修改 `layouts/_default/terms.html` 或 `layouts/_default/term.html`

#### Scenario: 局部變數管理
- **WHEN** 定義顏色或間距
- **THEN** 優先在 `categories.css` 和 `tags.css` 內部定義 CSS 變數或直接使用
- **AND** 避免產生不必要的全域依賴

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

### Requirement: Categories 系統玻璃質感 (System Glass)
Categories 頁面 MUST 呈現現代作業系統檔案總管的精緻質感，維持中性色調但提升細節。

#### Scenario: 高光邊框設計
- **WHEN** 渲染 Categories 卡片
- **THEN** 邊框顏色 MUST 為半透明白色（High-light）如 `rgba(255, 255, 255, 0.4)`
- **AND** NOT 使用深色或黑色半透明邊框
- **AND** 模擬光線照射玻璃邊緣的質感

#### Scenario: 系統選取狀態 Hover
- **WHEN** 使用者 Hover 卡片
- **THEN** 卡片亮度 MUST 提升（Brightness increase）
- **AND** 可選疊加極淡的冷灰或系統藍濾鏡（如 `rgba(200, 220, 255, 0.1)`）
- **AND** 陰影加深但保持柔和
- **AND** NOT 改變主要色相為鮮豔顏色（如紫色）

#### Scenario: 中性化資料夾圖示
- **WHEN** 渲染標題旁的資料夾圖示
- **THEN** 圖示顏色 MUST 使用 `currentColor` 保持中性灰或與文字同色系
- **AND** 可透過透明度（Opacity 0.8）增加層次感
- **AND** NOT 使用紫色或其他強調色

### Requirement: Categories 行動裝置適配
Categories Grid 在小尺寸螢幕上 MUST 優化排版以避免過於擁擠或浪費空間。

#### Scenario: 手機版單欄或緊湊雙欄
- **WHEN** 視窗寬度 < 640px
- **THEN** Grid 列寬設定 MUST 調整為適應手機寬度（建議 `1fr` 或 `minmax(160px, 1fr)`）
- **AND** 確保卡片內容不會貼邊過緊

### Requirement: Tags 柔和紫排版優化 (Soft Purple Refined)
Tags 頁面維持柔和紫配色，但 MUST 大幅優化排版空間感與細節。

#### Scenario: 寬鬆呼吸感間距 (Desktop)
- **WHEN** 渲染 Tags 列表在桌面版 (> 640px)
- **THEN** 標籤之間的 Gap MUST 至少為 `1rem` (16px)
- **AND** 行高 (line-height) MUST 足夠，避免上下行擁擠

#### Scenario: 緊湊聚合間距 (Mobile)
- **WHEN** 渲染 Tags 列表在手機版 (< 640px)
- **THEN** 標籤之間的 Gap MUST 縮小為 `0.5rem` (8px)
- **AND** 確保標籤雲在小螢幕上排列緊湊，提高空間利用率

#### Scenario: 融合式計數器 (Badge)
- **WHEN** 渲染 Tag 內的數量計數器
- **THEN** 背景色透明度 MUST 降低（如 `rgba(79, 70, 229, 0.1)`）
- **AND** 視覺上呈現「跟隨的影子」而非「突出的按鈕」
- **AND** 文字顏色保持與主色調一致但清晰��讀

#### Scenario: 單一標籤頁面標題保持中性
- **WHEN** 渲染單一標籤頁面（Term Page）的標題（H1）
- **THEN** 標題顏色 MUST 保持預設文字顏色（通常為黑色或深灰）
- **AND** 標題圖示 MUST 使用 `currentColor` 以精確匹配標題文字顏色
- **AND** NOT 使用紫色或其他強調色，避免與內容產生視覺衝突

