# Spec: CSS Optimization

## ADDED Requirements

### Requirement: 選擇器深度 SHALL NOT 超過 3 層
**ID**: CSS-001

CSS 選擇器的巢狀深度 SHALL 保持在 3 層以內，以提升可讀性、可維護性和效能。

#### Scenario: categories.css 簡化深層選擇器
**Given** CSS 規則針對 categories 中的 SVG icon
**When** 撰寫選擇器
**Then** 應使用 `[data-taxonomy="categories"] article h2 svg` (3 層)
**Instead of** `[data-taxonomy="categories"] section.flex.flex-wrap article > h2 > a > span > svg` (7 層)

#### Scenario: 簡化後的選擇器仍保持足夠特異性
**Given** 簡化的選擇器
**When** 套用到頁面
**Then** 應正確選中目標元素
**And** 不應誤中其他元素
**And** 權重足以覆蓋預設樣式

#### Scenario: 避免使用 !important
**Given** 需要覆蓋樣式
**When** 撰寫 CSS
**Then** 應優先調整選擇器特異性
**Instead of** 使用 `!important`

---

### Requirement: 重複樣式規則 MUST 合併
**ID**: CSS-002

相同的樣式規則 SHALL NOT 重複定義，應透過繼承或組合選擇器實現。

#### Scenario: backdrop-filter 應由 light mode 繼承
**Given** categories.css 中的 glass effect
**When** 定義 dark mode 樣式
**Then** `backdrop-filter` 應從 light mode 繼承
**And** dark mode 只需覆蓋 `background-color` 和 `border-color`

**Example**:
```css
/* Good */
[data-taxonomy="categories"] article {
  backdrop-filter: blur(12px);
}

.dark [data-taxonomy="categories"] article {
  background-color: rgba(30, 30, 40, 0.6);
  /* backdrop-filter inherited */
}
```

#### Scenario: 合併相同的 transition 規則
**Given** 多個元素使用相同的 transition
**When** 定義樣式
**Then** 應使用組合選擇器
**Or** 定義可重用的 class

---

### Requirement: Media query SHALL 使用一致斷點
**ID**: CSS-003

所有 media query SHALL 使用專案統一定義的斷點值。

#### Scenario: 使用標準的 Tailwind 斷點
**Given** 需要響應式樣式
**When** 撰寫 media query
**Then** 應使用 `640px` (sm), `768px` (md), `1024px` (lg), `1280px` (xl)
**As defined in** Tailwind CSS 預設配置

#### Scenario: 斷點值應保持一致
**Given** categories.css 和 tags.css 都需要 mobile 斷點
**When** 定義 media query
**Then** 兩者應使用相同的斷點值
**Example**: 都使用 `@media (max-width: 640px)`

---

### Requirement: 顏色值 SHALL 考慮提取為 CSS 變數
**ID**: CSS-004

重複使用超過 3 次的顏色值 SHALL 提取為 CSS 變數，以提升可維護性。

#### Scenario: glass effect 顏色值重複使用
**Given** article-cards.css 中的背景色
**When** 檢查顏色值使用次數
**Then** 如果 `rgba(255, 255, 255, 0.65)` 使用超過 3 次
**Then** 應提取為 `--card-bg-light`

#### Scenario: 單次使用的顏色值保持 inline
**Given** 只使用一次的顏色值
**When** 撰寫 CSS
**Then** 可以保持 inline 形式
**Because** 過度抽象會降低可讀性

#### Scenario: CSS 變數應在 :root 或特定 scope 定義
**Given** 新增 CSS 變數
**When** 決定定義位置
**Then** 全域變數應在 `:root` 或 `00-design-tokens.css`
**And** 模組專用變數可在該模組檔案頂部定義

---

### Requirement: 過度具體的選擇器 MUST 移除
**ID**: CSS-005

選擇器 SHALL 只包含必要的限定條件，移除不影響特異性的冗餘部分。

#### Scenario: 移除中間的結構限定
**Given** 選擇器 `[data-taxonomy="categories"] section.flex.flex-wrap article`
**When** 簡化選擇器
**Then** 可改為 `[data-taxonomy="categories"] article`
**Because** `section.flex.flex-wrap` 不提供額外的必要限定

#### Scenario: 保留必要的上下文
**Given** 需要區分不同上下文的相同元素
**When** 撰寫選擇器
**Then** 應保留足夠的上下文限定
**Example**: `[data-taxonomy="categories"] article h1::before` vs `article h1::before`

---

### Requirement: 註解 MUST 說明設計意圖
**ID**: CSS-006

複雜或非直觀的 CSS 規則 MUST 包含註解說明設計意圖和技術原因。

#### Scenario: glass effect 註解說明原因
**Given** article-cards.css 中的 glass effect
**When** 查看 CSS
**Then** 應有註解說明：
- 為何使用 RGBA 而非 opacity
- backdrop-filter 的瀏覽器支援狀況
- 與 Blowfish 原生樣式的關係

**Example**:
```css
/*
Card visual enhancements for Blowfish native article cards.
Uses RGBA for background-color to maintain text contrast while achieving glass effect.
backdrop-filter supported in all modern browsers (Safari 9+, Chrome 76+, Firefox 103+).
*/
article.overflow-hidden.rounded-lg.border {
  background-color: rgba(255, 255, 255, 0.65);
  backdrop-filter: blur(10px);
}
```

#### Scenario: 選擇器策略註解
**Given** 使用 data attribute 選擇器
**When** 撰寫 CSS
**Then** 應註解說明為何選擇 data attribute 而非 class
**Example**: 說明 `[data-taxonomy]` 是為了避免汙染 Blowfish class 系統

---

### Requirement: Taxonomy badges 選擇器 MUST 優化
**ID**: CSS-007

Taxonomy badges 的顏色區分 SHALL 使用可靠且可維護的選擇器。

#### Scenario: 評估 href 選擇器的可靠性
**Given** 當前使用 `a[href*="/categories/"]` 選擇器
**When** 評估其可靠性
**Then** 應考慮是否有 edge cases (如外部連結包含 "/categories/")
**And** 評估是否應改用 data attribute

#### Scenario: 考慮使用 data attribute 替代
**Given** 需要區分 categories 和 tags badges
**When** 選擇實作方式
**Then** 可考慮在 badge partial 加入 `data-taxonomy-type`
**Or** 保持現有 href 選擇器（如果確認無 edge cases）

#### Scenario: 文檔說明選擇器限制
**Given** 使用 href 選擇器
**When** 撰寫註解
**Then** 應說明已知的限制和假設
**Example**: "Assumes all /categories/ links are taxonomy links"

---

### Requirement: Media query 結構 SHALL 簡化
**ID**: CSS-008

Media query SHALL 使用清晰的結構，避免重複定義。

#### Scenario: 考慮 mobile-first vs desktop-first
**Given** 當前使用 `max-width` (desktop-first)
**When** 評估優化方式
**Then** 可考慮改為 `min-width` (mobile-first)
**Or** 保持一致的現有方式

#### Scenario: 合併相關的 media query
**Given** 多個規則使用相同的斷點
**When** 組織 CSS
**Then** 應考慮將相同斷點的規則合併
**Example**:
```css
/* Instead of */
@media (max-width: 640px) {
  .foo { ... }
}
@media (max-width: 640px) {
  .bar { ... }
}

/* Use */
@media (max-width: 640px) {
  .foo { ... }
  .bar { ... }
}
```

---

## REMOVED Requirements

無移除的需求。

---

## Related Specs
- `card-layout`: Card 樣式規範
- `taxonomy-display`: Taxonomy 顯示規範
- `code-quality`: 程式碼品質標準
