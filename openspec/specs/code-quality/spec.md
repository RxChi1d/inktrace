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
**Given** 覆蓋檔案 `layouts/_default/term.html`
**When** 開發者開啟檔案
**Then** 應在頂部看到以下格式的註解：
```html
{{/*
  Override reason: Add data-taxonomy attribute for CSS targeting
  Base: themes/blowfish/layouts/_default/term.html (commit: f9eb1d4)
  Modification: Wrap entire content in div with data-taxonomy="{{ .Data.Plural }}"
  Necessity: Enables precise CSS selectors for categories vs tags without polluting article lists
*/}}
```

#### Scenario: article-link/card.html 說明與上游 PR 的關係
**Given** 覆蓋檔案 `layouts/partials/article-link/card.html`
**When** 開發者查看檔案
**Then** 應看到註解說明與 Blowfish PR #2714 的關聯
**And** 說明未來可能回收此覆蓋的條件

---

### Requirement: CSS 選擇器深度 SHALL NOT 超過 3 層
**ID**: CQ-002

CSS 選擇器的巢狀深度 SHALL 保持在 3 層以內，以提升可讀性和效能。

#### Scenario: categories.css 使用簡化選擇器
**Given** CSS 檔案 `assets/css/custom/categories.css`
**When** 檢查選擇器
**Then** 不應存在超過 3 層的選擇器
**Example**:
```css
/* Bad (5 layers) */
[data-taxonomy="categories"] section.flex.flex-wrap article > h2 > a > span > svg

/* Good (3 layers) */
[data-taxonomy="categories"] article h2 svg
```

#### Scenario: 選擇器保持足夠的特異性
**Given** 簡化後的 CSS 選擇器
**When** 套用到頁面
**Then** 應正確選中目標元素
**And** 不應誤中其他無關元素
**And** 權重足以覆蓋需要覆蓋的樣式

---

### Requirement: HTML 模板 MUST NOT 包含無用元素
**ID**: CQ-003

HTML 模板 SHALL NOT 包含無功能的空元素或無用的 wrapper。

#### Scenario: 移除 article-link 末尾的空 div
**Given** 模板檔案 `layouts/partials/article-link/*.html`
**When** 檢查檔案末尾
**Then** 不應存在 `<div class="px-6 pt-4 pb-2"></div>` 這類空元素
**Unless** 有明確的技術原因並在註解中說明

---

### Requirement: Shell 腳本 MUST 使用函數消除重複邏輯
**ID**: CQ-004

Shell 腳本中重複超過 2 次的邏輯 MUST 抽取為獨立函數。

#### Scenario: generate-taxonomy-index.sh 使用函數驗證翻譯
**Given** 腳本 `script/generate-taxonomy-index.sh`
**When** 檢查翻譯驗證邏輯
**Then** zh-TW 和 en 的驗證應使用同一個函數
**And** 函數應接受 language 參數

#### Scenario: 函數命名清晰表達用途
**Given** Shell 腳本中的函數
**When** 閱讀函數名稱
**Then** 應能立即理解函數的功能
**Example**: `validate_translation` 而非 `check_val`

---

### Requirement: CSS 註解 MUST 說明樣式意圖
**ID**: CQ-005

複雜的 CSS 規則 MUST 包含註解說明設計意圖和技術原因。

#### Scenario: article-cards.css 說明 glass effect 原因
**Given** CSS 檔案 `assets/css/custom/article-cards.css`
**When** 查看 glass effect 樣式規則
**Then** 應看到註解說明：
- 為何使用 RGBA 值而非 CSS 變數
- backdrop-filter 的瀏覽器支援考量
- 與 Blowfish 原生樣式的關係

#### Scenario: taxonomy CSS 說明選擇器策略
**Given** CSS 檔案 `assets/css/custom/categories.css`
**When** 查看 `[data-taxonomy="categories"]` 選擇器
**Then** 應有註解說明為何使用 data attribute 而非 class

---

### Requirement: CSS 變數命名 SHALL 語意化
**ID**: CQ-006

CSS 變數命名 SHALL 清楚表達用途，避免使用縮寫或不明確的名稱。

#### Scenario: design tokens 使用描述性命名
**Given** CSS 檔案 `assets/css/custom/00-design-tokens.css`
**When** 檢查 CSS 變數命名
**Then** 應使用 `--gap-taxonomy` 而非 `--gap-tx`
**And** 應使用 `--spacing-card` 而非 `--sp-c`

#### Scenario: 變數命名遵循 BEM 風格
**Given** 新增的 CSS 變數
**When** 命名變數
**Then** 應遵循 `--<元件>-<屬性>-<修飾符>` 格式
**Example**: `--card-border-light`, `--taxonomy-gap-mobile`

---

## Related Specs
- `theme-overrides`: HTML 模板覆蓋規範
- `card-layout`: Card 樣式規範
- `taxonomy-display`: Taxonomy 顯示規範
