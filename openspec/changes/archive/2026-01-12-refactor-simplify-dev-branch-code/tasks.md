# Tasks: Simplify Dev Branch Code

## Phase 1: HTML 模板優化 (保守優化)

### Task 1.1: 優化 taxonomy 頁面模板
**檔案**: `layouts/_default/term.html`, `layouts/_default/terms.html`

- [x] 確認 `data-taxonomy` wrapper 是否為最小必要修改
- [x] 加入註解說明覆蓋原因 (英文)
- [x] 驗證與 Blowfish 原生模板的差異僅限於必要部分
- [x] 測試 categories 和 tags 頁面顯示正常

**驗證**:
- 執行 `hugo server` 檢查 `/categories/` 和 `/tags/` 頁面
- 確認 `data-taxonomy` 屬性正確套用

### Task 1.2: 優化 term-link/text.html 模板
**檔案**: `layouts/partials/term-link/text.html`

- [x] 簡化 categories 條件判斷邏輯
- [x] 確認 SVG icon 實作是否為最佳方案
- [x] 加入註解說明 Post/Posts 單複數保留原因
- [x] 驗證 inline categories 和 tags 顯示正常

**驗證**:
- 檢查 `/categories/` 列表頁的 card 樣式
- 檢查 `/tags/` 列表頁的 inline 樣式

### Task 1.3: 優化 article-link 系列模板
**檔案**:
- `layouts/partials/article-link/card.html`
- `layouts/partials/article-link/card-related.html`
- `layouts/partials/article-link/simple.html`
- `layouts/partials/article-link/_shortcode.html`

- [x] 確認新增的 class 命名是否符合 BEM 規範
- [x] 檢查 `line-clamp-*` 套用邏輯是否可簡化
- [x] 移除末尾的空 div (`<div class="px-6 pt-4 pb-2"></div>`)
- [x] 加入註解說明與 Blowfish PR #2714 的關聯

**驗證**:
- 檢查文章列表頁的 summary 截斷是否正常
- 測試 card view 和 simple view
- 確認相關文章區塊顯示正常

---

## Phase 2: CSS 樣式優化 (積極優化)

### Task 2.1: 優化 design tokens
**檔案**: `assets/css/custom/00-design-tokens.css`

- [x] 檢查 CSS 變數命名是否語意化
- [x] 驗證 responsive spacing 是否需要更多斷點
- [x] 考慮是否應移至獨立的 tokens 檔案

**驗證**:
- 測試不同螢幕尺寸的間距效果

### Task 2.2: 優化 taxonomy CSS
**檔案**: `assets/css/custom/categories.css`, `assets/css/custom/tags.css`

- [x] 簡化選擇器層級（減少巢狀深度）
- [x] 合併重複的樣式規則
- [x] 移除過度具體的選擇器
- [x] 優化 media query (考慮合併或使用 min-width only)
- [x] 檢查顏色值是否應改用 CSS 變數

**範例優化**:
```css
/* Before */
[data-taxonomy="categories"] section.flex.flex-wrap article > h2 > a > span > svg {
  margin-inline-end: 1rem;
}

/* After */
[data-taxonomy="categories"] article svg {
  margin-inline-end: 1rem;
}
```

**驗證**:
- 視覺回歸測試 (比對優化前後截圖)
- 測試 light/dark mode
- 測試 hover states

### Task 2.3: 優化 article cards CSS
**檔案**: `assets/css/custom/article-cards.css`

- [x] 檢查 glass effect 樣式是否可簡化
- [x] 驗證 RGBA 值是否應改用 CSS 變數
- [x] 確認 transition 屬性是否有重複定義
- [x] 移除註解中提到的 "trailing spacer" 是否還需要保留

**驗證**:
- 測試 card hover 效果
- 確認 glass effect 在不同背景下的顯示

### Task 2.4: 優化 taxonomy badges CSS
**檔案**: `assets/css/custom/taxonomy-badges.css`

- [x] 驗證 `a[href*="/categories/"]` selector 的可靠性
- [x] 考慮是否應使用 data attribute 替代 href 選擇
- [x] 檢查顏色值是否應使用 CSS 變數
- [x] 簡化 dark mode 規則

**驗證**:
- 測試文章頁面的 category/tag badges 顏色
- 確認 dark mode 切換正常

### Task 2.5: 優化 line-clamp utilities
**檔案**: `assets/css/custom/line-clamp-utilities.css`

- [x] 確認是否需要獨立檔案或可合併至其他檔案
- [x] 檢查註解是否足夠清晰

**驗證**:
- 測試 `.line-clamp-5` 在不同瀏覽器的顯示

---

## Phase 3: Shell 腳本優化 (積極優化)

### Task 3.1: 優化 generate-taxonomy-index.sh
**檔案**: `script/generate-taxonomy-index.sh`

- [x] 簡化錯誤檢查邏輯（合併重複的 yq 檢查）
- [x] 改善變數命名（如 `title_zh_tw` → `title_zh`）
- [x] 統一輸出訊息格式
- [x] 簡化 `generate_index_file` 函數的條件判斷
- [x] 考慮是否需要 verbose mode 選項

**優化範例**:
```bash
# Before
if [ -z "$title_zh_tw" ] || [ "$title_zh_tw" = "null" ]; then
  echo -e "${YELLOW}Warning: Missing zh-TW translation...${NC}"
  title_zh_tw="$term"
  missing_translation=1
fi

# After (可能的簡化)
title_zh_tw="${title_zh_tw:-$term}"
[ -z "$title_zh_tw" ] || [ "$title_zh_tw" = "null" ] && missing_translation=1
```

**驗證**:
- 執行腳本並檢查輸出
- 測試錯誤情境（缺少 yq, SSOT 檔案不存在等）

### Task 3.2: 優化 validate-taxonomy-terms.sh
**檔案**: `script/validate-taxonomy-terms.sh`

- [x] 簡化 front matter 解析邏輯
- [x] 合併重複的 term validation 函數
- [x] 改善錯誤訊息的一致性
- [x] 簡化 `term_exists` 函數的 return code 處理
- [x] 考慮將 front matter 解析抽取為獨立函數

**優化重點**:
- 減少巢狀 if 條件
- 統一錯誤訊息格式
- 簡化變數狀態追蹤 (如 `categories="open"/"closed"`)

**驗證**:
- 測試正常的 commit 流程
- 測試各種錯誤情境（大小寫錯誤、缺少翻譯等）
- 確認 pre-commit hook 正常運作

---

## Phase 4: 整合測試與驗證

### Task 4.1: 基本驗證（Hugo 建置）
- [x] 執行 `hugo` 建置專案
- [x] 確認建置無錯誤
- [x] 檢查 `public/` 目錄生成的 HTML 檔案
- [x] 驗證關鍵頁面的 HTML 結構正確

**驗證檔案**:
- `public/index.html` (首頁)
- `public/categories/index.html` (分類列表)
- `public/tags/index.html` (標籤列表)
- `public/categories/<term>/index.html` (分類頁面)

### Task 4.2: 視覺回歸測試
- [x] 啟動 `hugo server`
- [x] 截取優化前的頁面截圖（使用 Chrome DevTools Device Toolbar）
- [x] 執行優化
- [x] 重新啟動 `hugo server`
- [x] 截取優化後的相同頁面截圖
- [x] 比對確認無視覺差異

**測試頁面**:
- `/` (首頁)
- `/categories/` (分類列表)
- `/tags/` (標籤列表)
- `/categories/<term>/` (分類文章列表)
- `/tags/<term>/` (標籤文章列表)
- `/posts/<article>/` (文章頁面)

### Task 4.3: 響應式測試（不同螢幕尺寸）
使用 Chrome DevTools Device Toolbar 測試以下尺寸：

**Mobile (< 640px)**:
- [x] iPhone SE (375x667)
- [x] iPhone 12 Pro (390x844)
- [x] 驗證 categories grid 改為單欄
- [x] 驗證 tags 間距縮小至 0.5rem

**Tablet (640px - 1024px)**:
- [x] iPad (768x1024)
- [x] iPad Pro (1024x1366)
- [x] 驗證 categories grid 正常顯示
- [x] 驗證 taxonomy gap 為 0.75rem

**Desktop (> 1024px)**:
- [x] 1280x720
- [x] 1920x1080
- [x] 驗證 categories grid 多欄布局
- [x] 驗證 taxonomy gap 為 1rem

### Task 4.4: 功能測試
- [x] 測試 card view 和 simple view 切換
- [x] 測試 dark mode 切換
- [x] 測試 summary line clamp 功能
- [x] 驗證 taxonomy badges 顏色正確

### Task 4.5: 進階驗證（Chrome DevTools）

**CSS 選擇器檢查**:
- [x] 開啟 Chrome DevTools → Elements
- [x] 檢查優化後的選擇器是否正確套用
- [x] 驗證選擇器權重足夠（Computed styles）
- [x] 確認無意外的樣式覆蓋

**效能分析**:
- [x] 開啟 Chrome DevTools → Performance
- [x] 錄製頁面載入過程
- [x] 檢查 CSS Recalculate Style 時間
- [x] 比對優化前後的效能數據

**網路分析**:
- [x] 開啟 Chrome DevTools → Network
- [x] 比對 CSS 檔案大小（優化前後）
- [x] 測量總載入時間
- [x] 驗證無多餘的資源請求

### Task 4.6: 程式碼品質檢查
- [x] 執行 `hugo` 確認無建置錯誤
- [x] 檢查所有 Shell 腳本可執行
- [x] 驗證所有註解為英文
- [x] 確認符合專案 coding conventions
- [x] 執行 `openspec validate refactor-simplify-dev-branch-code` 確認符合規格

---

## Dependencies
- Task 1.x → Task 4.1, 4.2, 4.3 (HTML 優化完成後才能測試)
- Task 2.x → Task 4.1, 4.2, 4.3, 4.5 (CSS 優化完成後才能測試)
- Task 3.x → Task 4.4 (Shell 優化完成後才能測試)
- Task 4.1 (基本驗證) → Task 4.2, 4.3, 4.4, 4.5 (建置成功後才能進行其他測試)
- Task 4.2, 4.3, 4.4, 4.5 → Task 4.6 (所有測試通過後進行最終檢查)

## Parallel Work
- Task 1.x, 2.x, 3.x 可以平行進行（不同檔案類型）
- Task 1.1 和 1.2 可以平行進行
- Task 2.1, 2.2, 2.3, 2.4, 2.5 可以平行進行

## Rollback Plan
- 所有變更都在 dev 分支進行
- 可隨時 `git reset --hard` 回到優化前的 commit
- 建議在開始優化前建立 tag: `git tag pre-simplification`
