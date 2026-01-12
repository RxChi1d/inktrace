# Spec: Code Quality Standards

## ADDED Requirements

### Requirement: HTML 模板 MUST 包含覆蓋原因註解
**ID**: CQ-001

HTML 模板覆蓋檔案 **MUST** 在頂部包含清晰的英文註解，說明：
1. 覆蓋原因 (Override reason)
2. 基礎模板來源 (Base template source)
3. 具體修改內容 (Modifications)
4. 技術必要性 (Technical necessity)

#### Scenario: term.html 包含完整覆蓋說明
- **WHEN** 開發者開啟 `layouts/_default/term.html`
- **THEN** 應在頂部看到以下格式的註解：
```html
{{/*
  Override reason: Add data-taxonomy attribute for CSS targeting
  Base: themes/blowfish/layouts/_default/term.html (commit: f9eb1d4)
  Modification: Wrap entire content in div with data-taxonomy="{{ .Data.Plural }}"
  Necessity: Enables precise CSS selectors for categories vs tags without polluting article lists
*/}}
```

#### Scenario: article-link/card.html 說明與上游 PR 的關係
- **WHEN** 開發者查看 `layouts/partials/article-link/card.html`
- **THEN** 應看到註解說明與 Blowfish PR #2714 的關聯
- **THEN** 說明未來可能回收此覆蓋的條件

---

### Requirement: CSS 選擇器深度 SHALL NOT 超過 3 層
**ID**: CQ-002

CSS 選擇器的巢狀深度 SHALL 保持在 3 層以內，以提升可讀性和效能。

#### Scenario: categories.css 使用簡化選擇器
- **WHEN** 檢查 `assets/css/custom/categories.css` 的選擇器
- **THEN** 不應存在超過 3 層的選擇器
**Example**:
```css
/* Bad (5 layers) */
[data-taxonomy="categories"] section.flex.flex-wrap article > h2 > a > span > svg

/* Good (3 layers) */
[data-taxonomy="categories"] article h2 svg
```

#### Scenario: 選擇器保持足夠的特異性
- **WHEN** 將簡化後的 CSS 選擇器套用到頁面
- **THEN** 應正確選中目標元素
- **THEN** 不應誤中其他無關元素
- **THEN** 權重足以覆蓋需要覆蓋的樣式

---

### Requirement: HTML 模板 MUST NOT 包含無用元素
**ID**: CQ-003

HTML 模板 SHALL NOT 包含無功能的空元素或無用的 wrapper。

#### Scenario: 移除 article-link 末尾的空 div
- **WHEN** 檢查 `layouts/partials/article-link/*.html` 檔案末尾
- **THEN** 不應存在 `<div class="px-6 pt-4 pb-2"></div>` 這類空元素
- **THEN** 若保留該元素，需在註解中說明技術原因

---

### Requirement: Shell 腳本 MUST 使用函數消除重複邏輯
**ID**: CQ-004

Shell 腳本中重複超過 2 次的邏輯 MUST 抽取為獨立函數。

#### Scenario: generate-taxonomy-index.sh 使用函數驗證翻譯
- **WHEN** 檢查 `script/generate-taxonomy-index.sh` 的翻譯驗證邏輯
- **THEN** zh-TW 和 en 的驗證應使用同一個函數
- **THEN** 函數應接受 language 參數

#### Scenario: 函數命名清晰表達用途
- **WHEN** 閱讀 Shell 腳本中的函數名稱
- **THEN** 應能立即理解函數的功能
**Example**: `validate_translation` 而非 `check_val`

---

### Requirement: CSS 註解 MUST 說明樣式意圖
**ID**: CQ-005

複雜的 CSS 規則 MUST 包含註解說明設計意圖和技術原因。

#### Scenario: article-cards.css 說明 glass effect 原因
- **WHEN** 查看 `assets/css/custom/article-cards.css` 的 glass effect 樣式規則
- **THEN** 應看到註解說明：
- 為何使用 RGBA 值而非 CSS 變數
- backdrop-filter 的瀏覽器支援考量
- 與 Blowfish 原生樣式的關係

#### Scenario: taxonomy CSS 說明選擇器策略
- **WHEN** 查看 `assets/css/custom/categories.css` 中的 `[data-taxonomy="categories"]` 選擇器
- **THEN** 應有註解說明為何使用 data attribute 而非 class

---

### Requirement: CSS 變數命名 SHALL 語意化
**ID**: CQ-006

CSS 變數命名 SHALL 清楚表達用途，避免使用縮寫或不明確的名稱。

#### Scenario: design tokens 使用描述性命名
- **WHEN** 檢查 `assets/css/custom/00-design-tokens.css` 的 CSS 變數命名
- **THEN** 應使用 `--gap-taxonomy` 而非 `--gap-tx`
- **THEN** 應使用 `--spacing-card` 而非 `--sp-c`

#### Scenario: 變數命名遵循 BEM 風格
- **WHEN** 命名新增的 CSS 變數
- **THEN** 應遵循 `--<元件>-<屬性>-<修飾符>` 格式
**Example**: `--card-border-light`, `--taxonomy-gap-mobile`

---

## Related Specs
- `theme-overrides`: HTML 模板覆蓋規範
- `card-layout`: Card 樣式規範
- `taxonomy-display`: Taxonomy 顯示規範
