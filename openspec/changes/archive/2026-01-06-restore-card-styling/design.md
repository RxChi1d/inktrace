# Design Document: Restore Card Visual Styling

## Context
在 `restore-native-cards` 遷移中，文章列表卡片從自訂 HTML 結構回歸至 Blowfish 原生結構，移除了 `article-card-hover` class 作為樣式鉤子。原自訂樣式包含毛玻璃背景、陰影與 hover 變色效果，這些視覺增強對於使用者體驗至關重要。

當前 Blowfish 原生卡片結構：
```html
<article class="flex flex-col md:flex-row relative overflow-hidden rounded-lg border border-neutral-300 dark:border-neutral-600">
```

原自訂結構（已移除）：
```html
<article class="... border-2 rounded-2xl border-neutral-200 dark:border-neutral-700 article-card-hover">
```

### Stakeholders
- **內容創作者**：需要視覺吸引力的文章列表
- **讀者**：期望流暢的互動體驗（hover 回饋）
- **維護者**：希望減少與 Blowfish 主題升級的衝突

## Goals / Non-Goals

### Goals
1. 透過純 CSS 恢復核心視覺效果，無需修改 Blowfish HTML 結構
2. 保持與 Blowfish 主題的設計一致性（不改結構與邊框規格）
3. 完整支援深色模式
4. 記錄所有無法完全恢復的差異部分

### Non-Goals
1. 不強制還原與 Blowfish 原生規格衝突的樣式（如邊框寬度、圓角大小）
2. 不修改 Blowfish 主題檔案或 HTML 結構
3. 不建立新的自訂 class 或 data attributes

## Decisions

### Decision 1: CSS 選擇器策略
**選擇**: 使用 `article.overflow-hidden.rounded-lg.border` 作為主選擇器

**理由**:
- 這個 class 組合在 Blowfish 中唯一且明確標識卡片元素
- 不依賴自訂 class，與主題原生結構相容
- 特異性足夠高，避免誤傷其他元素

**風險**: 若 Blowfish 未來改變 class 命名，選擇器會失效

**緩解**:
- 在 CSS 檔案頂部註解中清楚標記選擇器依賴性
- Blowfish 使用 Tailwind，class 命名遵循語義化，不太可能大幅改變
- 即使改變，調整選擇器即可，無需重構

### Decision 2: 覆寫圓角、保留邊框寬度
**選擇**: 將卡片圓角改回 `1rem`（`rounded-2xl`），邊框寬度維持 Blowfish 原生 `1px`，並保留原始邊框顏色（含 hover）

**理由**:
- 使用者偏好較大圓角，但希望邊框粗細維持原生尺寸
- 圓角變更對視覺影響明顯，邊框寬度差異可接受
- 覆寫範圍僅限 article 卡片，影響可控

**替代方案考量**:
- **方案 A（放棄）**: 保留 Blowfish 原生邊框寬度與圓角
  - 優點：維護成本低
  - 缺點：與原始設計不一致
- **方案 B（放棄）**: 強制覆寫寬度與圓角為原自訂規格（`border-2` + `rounded-2xl`）
  - 優點：視覺完全一致
  - 缺點：邊框粗細不符合當前需求

### Decision 3: 以原始卡片顏色為基準直接使用原始 RGBA
**選擇**: 背景與 hover 背景直接使用原始 RGBA 色值，確保與原設計一致；陰影色維持原始 RGBA 以保留層次

**理由**:
- 使用原始色值可維持視覺一致性
- 變數化導致色差過大，影響設計意圖
- 變更範圍維持在 CSS 層，避免影響結構

**實作範例**:
```css
background-color: rgba(255, 255, 255, 0.65);
background-color: rgba(26, 32, 44, 0.7);
```

### Decision 4: CSS 載入順序與檔名
**選擇**: `custom/` 目前無卡片樣式衝突，載入順序不敏感，維持 `article-cards.css` 檔名，不加數字前綴

**理由**:
- 既有 `assets/css/custom/*.css` 中沒有卡片相關樣式覆寫
- 依檔名排序的載入策略足以維持一致性
- 減少命名調整造成的維護成本

### Decision 5: Hover 改為「覆蓋式背景」而非疊加層
**選擇**: hover 時直接覆蓋卡片 `background-color`，使用原始連結 hover 的色值（`rgba(0, 0, 0, 0.03)` / `rgba(255, 255, 255, 0.04)`），不再使用 `::before` 疊加層

**理由**:
- 原始主分支實際生效的 hover 背景為 `a.article-card-hover:hover`（特異性較高），因此「覆蓋式」才是實際視覺結果
- 疊加層會與基底背景混色，導致白不夠白、黑不夠黑的視覺偏差
- 不依賴 `<a>` 結構，可直接套用在原生 `article` 卡片上

**實作重點**:
- `article:hover` 設定 `background-color` 為 `rgba(0, 0, 0, 0.03)`
- `.dark article:hover` 設定 `background-color` 為 `rgba(255, 255, 255, 0.04)`
- 保留陰影與邊框 hover 變化以維持層次感

### Decision 6: 移除 hover 疊加層與層級調整
**選擇**: 不再使用 `::before` 疊加層，移除相關 `z-index` 與 `pointer-events` 設定

**理由**:
- 覆蓋式背景不需要額外疊加層
- 簡化層級與互動設定，降低維護成本

### Decision 7: Article 卡片尾端空白以 CSS 統一壓掉
**選擇**: 不覆蓋 Blowfish 模板，改以 CSS 移除所有 article 卡片的尾端 spacer padding

**理由**:
- `article-link/simple.html` 固定輸出尾端 spacer div，造成卡片底部空白
- 以 CSS 方式維持主題可升級性，避免模板覆寫成本
- 統一 standard list、card view、related cards 的卡片版面，避免視覺不一致

**實作重點**:
- 目標元素：`article.overflow-hidden.rounded-lg.border > div.px-6.pt-4.pb-2`
- 調整方式：`padding: 0;`

## Technical Specifications

### 原始樣式規格（Git History: caec243）

#### 淺色模式
```css
.article-card-hover {
  background-color: rgba(255, 255, 255, 0.65);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(0, 0, 0, 0.1);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  transition: background-color 0.3s ease, transform 0.2s ease, box-shadow 0.3s ease, border-color 0.3s ease;
}

.article-card-hover:hover {
  background-color: rgba(255, 255, 255, 0.85);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: rgba(0, 0, 0, 0.15);
}
```

#### 深色模式
```css
.dark .article-card-hover {
  background-color: rgba(26, 32, 44, 0.7);
  border: 1px solid rgba(255, 255, 255, 0.15);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.dark .article-card-hover:hover {
  background-color: rgba(45, 55, 72, 0.85);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  border-color: rgba(255, 255, 255, 0.25);
}
```

#### 額外的 Hover 覆蓋效果（Git History: 417ec0c）
```css
a.article-card-hover:hover {
  background-color: rgba(0, 0, 0, 0.03);
  transition: background-color 0.3s ease;
}

.dark a.article-card-hover:hover {
  background-color: rgba(255, 255, 255, 0.04);
  transition: background-color 0.3s ease;
}
```

### 新選擇器適配後的樣式

#### 主選擇器
```css
article.overflow-hidden.rounded-lg.border
```

#### 檢查事項
- [ ] 確認當前 Blowfish 卡片元素仍為 `article.overflow-hidden.rounded-lg.border`
- [ ] 確認 hover 規則直接套用在 `article` 本體（不依賴 `<a>` 包裹）

## Risks / Trade-offs

### Risk 1: 選擇器脆弱性
**風險**: Blowfish 主題更新改變 class 命名慣例

**影響**: 樣式失效，卡片回到原生外觀

**緩解**:
- 在 CSS 檔案頂部清楚標記依賴性
- 定期追蹤 Blowfish 更新日誌
- 使用 Git 追蹤樣式變化，便於快速修復

### Risk 2: 瀏覽器相容性（`backdrop-filter`）
**風險**: 舊版瀏覽器不支援 `backdrop-filter` 屬性

**影響**: 無毛玻璃效果，但背景色提供降級方案

**緩解**:
- 添加 `-webkit-backdrop-filter` 前綴（Safari）
- 半透明背景色作為 fallback
- 現代瀏覽器支援度 > 95%

### Trade-off: 視覺完整性 vs. 維護性
**選擇**: 優先維護性，接受部分視覺差異

**放棄**: 完全一致的邊框寬度、圓角大小、邊框顏色

**獲得**: 低維護成本、與 Blowfish 更新相容、CSS 特異性穩定

**評估**: 根據實際渲染結果，可在未來調整策略

## Migration Plan

### Phase 1: 基礎實作（當前階段）
1. 建立 `article-cards.css` 並實作核心樣式
2. 建立 `style-differences.md` 記錄差異
3. 透過 `hugo server` 驗證淺色與深色模式

### Phase 2: 視覺驗證（實作後）
1. 檢查不同頁面的卡片渲染（首頁、Posts、分類）
2. 測試 hover 互動流暢度
3. 確認選擇器精準度（無誤傷）
4. 評估是否需要調整邊框規格

### Phase 3: 根據反饋調整（可選）
若視覺差異不可接受：
1. 在 `style-differences.md` 中標記需調整項目
2. 評估覆寫邊框規格的成本與收益
3. 實作 CSS 覆寫（`border-width: 2px; border-radius: 1rem;`）
4. 測試特異性衝突與響應式表現
5. 若仍需微調色彩，另提變更或局部調整色值

### Rollback Plan
若樣式衝突或效果不佳：
1. 移除 `assets/css/custom/article-cards.css`
2. Hugo 會自動回到 Blowfish 原生樣式
3. 無需修改 HTML 或 Git 歷史

## Open Questions

1. **選擇器是否會誤傷其他元素？**
   - 需透過瀏覽器開發者工具驗證 `article.overflow-hidden.rounded-lg.border` 的選取範圍
   - 確認只選中卡片元素，未影響其他 article

2. **Hover 覆蓋色的視覺與可讀性是否符合預期？**
   - 確認覆蓋色不會影響文字可讀性或點擊區
   - 確認覆蓋色與原本連結 hover 的視覺一致

3. **實際渲染後的視覺差異是否可接受？**
   - 邊框寬度差異（1px vs 2px）
   - 圓角差異（`rounded-lg` 0.5rem vs `rounded-2xl` 1rem）
   - 邊框顏色差異（`neutral-300/600` vs `neutral-200/700`）

這些問題將在實作與測試階段解答，並記錄於 `style-differences.md`。
