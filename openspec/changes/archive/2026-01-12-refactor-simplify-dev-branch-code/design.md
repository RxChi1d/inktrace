# Design: Simplify Dev Branch Code

## Overview
本設計文件說明如何保守地優化 dev 分支的程式碼，在保持功能完整性和 Blowfish 主題一致性的前提下，提升程式碼品質和可維護性。

## Architectural Context

### Current Architecture
```
inktrace-blowfish/
├── themes/blowfish/          # Git submodule (不可修改)
├── layouts/                  # 覆蓋 Blowfish 模板
│   ├── _default/
│   │   ├── term.html        # 加入 data-taxonomy wrapper
│   │   └── terms.html       # 加入 data-taxonomy wrapper
│   └── partials/
│       ├── article-link/    # 加入 line-clamp classes
│       └── term-link/       # 區分 categories/tags 顯示
├── assets/css/custom/       # 模組化 CSS
│   ├── 00-design-tokens.css
│   ├── article-cards.css
│   ├── categories.css
│   ├── tags.css
│   └── ...
└── script/                  # Taxonomy 管理腳本
    ├── generate-taxonomy-index.sh
    └── validate-taxonomy-terms.sh
```

### Design Principles
1. **最小侵入原則**: HTML 模板保持與 Blowfish 原生邏輯的最高一致性
2. **可維護性優先**: CSS 和 Shell 腳本優化以提升可讀性為主
3. **功能保證**: 所有優化不得改變任何可見的功能行為
4. **註解完整性**: 所有覆蓋和特殊處理都需要清晰的英文註解

## Optimization Strategy

### 1. HTML 模板優化策略

#### 1.1 保守優化原則
- **只做必要的修改**: 確認每個覆蓋都有明確的技術理由
- **保持結構一致**: 不改變 Blowfish 原生的 DOM 結構
- **註解說明**: 每個覆蓋檔案都需要頂部註解說明原因

#### 1.2 優化重點

**term.html 和 terms.html**:
```html
<!-- Before (current) -->
{{ define "main" }}
  <div data-taxonomy="{{ .Data.Plural }}">
  {{ .Scratch.Set "scope" "term" }}
  ...
  </div>
{{ end }}

<!-- After (optimized with comment) -->
{{ define "main" }}
  {{/*
    Override reason: Add data-taxonomy attribute for CSS targeting
    Base: themes/blowfish/layouts/_default/term.html (f9eb1d4)
    Modification: Wrap entire content in div with data-taxonomy="{{ .Data.Plural }}"
    This enables precise CSS selectors for categories vs tags without polluting article lists
  */}}
  <div data-taxonomy="{{ .Data.Plural }}">
  {{ .Scratch.Set "scope" "term" }}
  ...
  </div>
{{ end }}
```

**article-link/*.html**:
- 確認新增的 class 是否符合命名規範
- 移除無用的空 div
- 加入註解說明與 Blowfish PR #2714 的關係

```html
<!-- Before -->
<div class="px-6 pt-4 pb-2"></div>  <!-- 無用的 spacer -->

<!-- After -->
<!-- Removed empty spacer div (not needed with current layout) -->
```

#### 1.3 驗證策略
- 使用 `diff` 比對優化前後與 Blowfish 原生模板的差異
- 確保差異僅限於必要的修改（data attributes, classes, comments）

### 2. CSS 優化策略

#### 2.1 選擇器簡化原則
- **減少巢狀深度**: 最多 3 層
- **避免過度具體**: 只保留必要的限定條件
- **使用語意化命名**: 優先使用 class 而非複雜的組合選擇器

#### 2.2 優化範例

**Before**:
```css
[data-taxonomy="categories"] section.flex.flex-wrap article > h2 > a > span > svg {
  margin-inline-end: 1rem;
}
```

**After**:
```css
/* Simplified: target SVG within category article headers */
[data-taxonomy="categories"] article h2 svg {
  margin-inline-end: 1rem;
}
```

**Rationale**:
- 移除中間的 `> a > span` 層級（不必要的限定）
- 保留足夠的上下文（`article h2`）確保選擇器不會誤中其他元素
- 減少選擇器權重，提升 CSS 效能

#### 2.3 重複規則合併

**Before**:
```css
[data-taxonomy="categories"] article {
  background-color: rgba(255, 255, 255, 0.65);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.dark [data-taxonomy="categories"] article {
  background-color: rgba(30, 30, 40, 0.6);
}
```

**After**:
```css
[data-taxonomy="categories"] article {
  background-color: rgba(255, 255, 255, 0.65);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.dark [data-taxonomy="categories"] article {
  background-color: rgba(30, 30, 40, 0.6);
  /* backdrop-filter inherited from light mode */
}
```

#### 2.4 CSS 變數考量
**現狀**: 部分顏色值直接寫死在 CSS 中
**建議**: 考慮提取為 CSS 變數（但需權衡複雜度）

```css
/* Option 1: Keep inline (simpler, current approach) */
border-color: rgba(0, 0, 0, 0.1);

/* Option 2: Use CSS variables (more maintainable for repeated values) */
:root {
  --card-border-light: rgba(0, 0, 0, 0.1);
}
border-color: var(--card-border-light);
```

**決策**: 優先保持簡單，除非同一顏色值重複超過 3 次才提取為變數。

#### 2.5 Media Query 優化

**Before**:
```css
@media (max-width: 640px) {
  [data-taxonomy="categories"] section.flex.flex-wrap {
    grid-template-columns: 1fr;
  }
}
```

**After**:
```css
/* Mobile-first approach (if refactoring entire file) */
[data-taxonomy="categories"] section.flex.flex-wrap {
  grid-template-columns: 1fr; /* Mobile default */
}

@media (min-width: 641px) {
  [data-taxonomy="categories"] section.flex.flex-wrap {
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  }
}
```

**決策**: 保守起見，維持現有的 `max-width` 方式，除非進行全面重構。

### 3. Shell 腳本優化策略

#### 3.1 錯誤處理簡化

**Before**:
```bash
if [ -z "$title_zh_tw" ] || [ "$title_zh_tw" = "null" ]; then
    echo -e "${YELLOW}Warning: Missing zh-TW translation for $taxonomy/$term, using term as fallback${NC}"
    title_zh_tw="$term"
    missing_translation=1
fi

if [ -z "$title_en" ] || [ "$title_en" = "null" ]; then
    echo -e "${YELLOW}Warning: Missing en translation for $taxonomy/$term, using term as fallback${NC}"
    title_en="$term"
    missing_translation=1
fi
```

**After** (可能的優化):
```bash
# Function to validate and set translation
validate_translation() {
    local lang=$1
    local value=$2
    local term=$3

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo -e "${YELLOW}Warning: Missing $lang translation for $taxonomy/$term, using term as fallback${NC}"
        echo "$term"
        return 1
    fi
    echo "$value"
    return 0
}

title_zh_tw=$(validate_translation "zh-TW" "$title_zh_tw" "$term") || missing_translation=1
title_en=$(validate_translation "en" "$title_en" "$term") || missing_translation=1
```

**Trade-off 分析**:
- **優點**: 減少重複程式碼，更易維護
- **缺點**: 增加函數呼叫開銷（但在 shell 腳本中影響可忽略）
- **決策**: 採用函數抽取，提升可讀性

#### 3.2 變數命名改善

**Before**:
```bash
title_zh_tw=$(get_translation "zh-TW" "$taxonomy" "$term")
title_en=$(get_translation "en" "$taxonomy" "$term")
```

**After**:
```bash
# Keep zh_tw suffix for clarity (zh-TW is the full locale code)
title_zh=$(get_translation "zh-TW" "$taxonomy" "$term")
title_en=$(get_translation "en" "$taxonomy" "$term")
```

**決策**: 保留 `_zh_tw` 以明確對應 locale code，但可接受簡化為 `_zh`。

#### 3.3 Front Matter 解析優化

**Current approach** (validate-taxonomy-terms.sh):
使用狀態機模式 (`categories="open"/"closed"`) 追蹤解析狀態。

**Alternative approach**:
使用 `yq` 直接解析 front matter（需要 yq v4+）

```bash
# Alternative: Use yq for front matter parsing
categories=$(yq eval '.categories[]' "$file" 2>/dev/null | tr '\n' ',')
tags=$(yq eval '.tags[]' "$file" 2>/dev/null | tr '\n' ',')
```

**Trade-off**:
- **優點**: 程式碼更簡潔，更健壯
- **缺點**: 依賴 yq 版本，可能在某些 YAML 格式下失效
- **決策**: 保守起見，維持現有的手動解析邏輯，但簡化狀態追蹤

## Implementation Sequence

### Phase 1: HTML 模板 (低風險)
1. 加入註解
2. 移除無用程式碼
3. 驗證功能

### Phase 2: CSS 樣式 (中風險)
1. 簡化選擇器
2. 合併重複規則
3. 視覺回歸測試

### Phase 3: Shell 腳本 (低風險)
1. 抽取重複函數
2. 改善錯誤訊息
3. 功能測試

### Phase 4: 整合驗證 (必要)
1. 全面功能測試
2. 視覺回歸測試
3. 效能測試

## Risk Mitigation

### CSS 選擇器權重問題
**Risk**: 簡化選擇器可能導致權重不足，被其他樣式覆蓋
**Mitigation**:
- 在簡化前記錄原始權重
- 使用 DevTools 驗證新選擇器是否生效
- 必要時保留部分限定條件

### Shell 腳本行為改變
**Risk**: 重構可能引入 bug
**Mitigation**:
- 準備完整的測試案例（正常 + 錯誤情境）
- 保留原始腳本作為 `.bak` 備份
- 逐函數測試

### 視覺回歸
**Risk**: CSS 優化導致視覺差異
**Mitigation**:
- 截圖比對（before/after）
- 測試多種螢幕尺寸
- 測試 light/dark mode

## Testing Strategy

### 測試層級

本次優化採用**兩級驗證策略**：

#### Level 1: 基本驗證
**目的**: 確保 Hugo 建置成功，HTML 正確生成

**工具**: Hugo CLI
**步驟**:
1. 執行 `hugo` 建置專案
2. 檢查 `public/` 目錄結構
3. 驗證關鍵 HTML 檔案存在且結構正確

**通過條件**:
- 無建置錯誤
- 所有必要的 HTML 檔案已生成
- HTML 結構符合預期

#### Level 2: 進階驗證
**目的**: 確保視覺效果、響應式布局和效能符合預期

**工具**: Chrome DevTools
**步驟**:

1. **視覺回歸測試**:
   - 使用 `hugo server` 啟動開發伺服器
   - 截取優化前後的頁面截圖
   - 逐一比對確認無差異

2. **響應式測試**:
   - 使用 Chrome DevTools Device Toolbar
   - 測試 Mobile, Tablet, Desktop 三種尺寸
   - 驗證斷點行為（640px, 1024px）

3. **效能分析**:
   - 使用 Performance 面板錄製載入過程
   - 檢查 CSS Recalculate Style 時間
   - 比對優化前後數據

4. **CSS 選擇器檢查**:
   - 使用 Elements 面板檢查套用的樣式
   - 驗證選擇器權重（Computed styles）
   - 確認無意外的樣式覆蓋

### 測試覆蓋範圍

**必測頁面**:
- `/` - 首頁
- `/categories/` - 分類列表
- `/tags/` - 標籤列表
- `/categories/<term>/` - 單一分類頁
- `/tags/<term>/` - 單一標籤頁
- `/posts/<article>/` - 文章頁

**測試尺寸**:
- Mobile: iPhone SE (375x667), iPhone 12 Pro (390x844)
- Tablet: iPad (768x1024), iPad Pro (1024x1366)
- Desktop: 1280x720, 1920x1080

**測試條件**:
- Light mode / Dark mode
- Card view / Simple view
- 不同瀏覽器（Chrome 必測，Firefox/Safari 選測）

## Success Criteria

1. **功能完整性**: 所有頁面功能與優化前完全一致
2. **程式碼品質**:
   - HTML 模板註解完整
   - CSS 選擇器平均深度 ≤ 3
   - Shell 腳本無重複邏輯
3. **效能**: CSS 檔案大小減少或持平
4. **可維護性**: 新開發者能快速理解覆蓋原因
5. **測試通過**:
   - 基本驗證：Hugo 建置成功
   - 進階驗證：視覺回歸、響應式、效能測試全部通過

## Future Considerations

### CSS Variables System
未來可考慮建立完整的 design tokens 系統：
```css
:root {
  /* Colors */
  --color-card-bg-light: rgba(255, 255, 255, 0.65);
  --color-card-bg-dark: rgba(30, 30, 40, 0.6);

  /* Spacing */
  --spacing-taxonomy-gap: 0.5rem;

  /* Effects */
  --effect-glass-blur: 12px;
}
```

**當前決策**: 不在此次優化中引入，保持簡單。

### Automated Visual Testing
未來可考慮使用 Percy 或 Chromatic 進行自動化視覺回歸測試。

**當前決策**: 手動截圖比對即可。

## References
- Blowfish PR #2714: Summary Line Clamp
- BLOWFISH-OVERRIDES.md: 覆蓋模板清單
- OpenSpec specs: `theme-overrides`, `card-layout`, `taxonomy-display`
