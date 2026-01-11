# taxonomy-display Spec Delta

## ADDED Requirements

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

## MODIFIED Requirements

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
