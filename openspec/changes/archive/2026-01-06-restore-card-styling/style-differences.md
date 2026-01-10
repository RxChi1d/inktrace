# Style Differences: Card Visual Styling Restoration

本文件記錄在 `restore-card-styling` 變更中，相較於原始自訂樣式（Git history: caec243, 417ec0c）的差異項目。

## 完全恢復的效果 ✅

以下視覺效果已透過純 CSS 方式完全恢復，與原始規格一致：

| 效果項目 | 原始規格 | 恢復狀態 |
|---------|---------|---------|
| 毛玻璃背景（淺色模式） | `rgba(255, 255, 255, 0.65)` + `blur(10px)` | ✅ 完全一致 |
| 毛玻璃背景（深色模式） | `rgba(26, 32, 44, 0.7)` + `blur(10px)` | ✅ 完全一致 |
| 預設陰影（淺色模式） | `0 2px 8px rgba(0, 0, 0, 0.05)` | ✅ 完全一致 |
| 預設陰影（深色模式） | `0 2px 8px rgba(0, 0, 0, 0.2)` | ✅ 完全一致 |
| Hover 陰影（淺色模式） | `0 4px 12px rgba(0, 0, 0, 0.1)` | ✅ 完全一致 |
| Hover 陰影（深色模式） | `0 4px 12px rgba(0, 0, 0, 0.3)` | ✅ 完全一致 |
| Hover 背景變色（淺色） | `rgba(255, 255, 255, 0.85)` | ✅ 改為覆蓋色 `rgba(0, 0, 0, 0.03)` |
| Hover 背景變色（深色） | `rgba(45, 55, 72, 0.85)` | ✅ 改為覆蓋色 `rgba(255, 255, 255, 0.04)` |
| 圓角大小 | `rounded-2xl` (1rem / 16px) | ✅ 已恢復 |
| 邊框顏色（預設/hover） | `rgba(0, 0, 0, 0.1/0.15)`、`rgba(255, 255, 255, 0.15/0.25)` | ✅ 已確認一致 |
| 過渡動畫 | `0.3s ease` (background, shadow, border) | ✅ 完全一致 |
| Safari 相容性 | `-webkit-backdrop-filter` 前綴 | ✅ 已實作 |

**備註**:
- 原始 CSS 與現行 CSS 的邊框 RGBA 定義一致（預設與 hover）
- Blowfish 提供 `.bf-border-color` / `.bf-border-color-hover` 工具類別（`themes/blowfish/assets/css/main.css`），若套用於卡片可能影響邊框色
- 原始主分支卡片為 `<a.article-card-hover>`，`a.article-card-hover:hover` 背景色（`rgba(0, 0, 0, 0.03)` / `rgba(255, 255, 255, 0.04)`）因特異性較高而覆蓋 `.article-card-hover:hover`，因此實際 hover 感受以「覆蓋色」為主

## 原始 RGBA 色值清單（A 方案）

因為 Blowfish 變數色差過大，改為直接使用原始 RGBA 色值，以確保視覺一致性。

| 使用項目 | 原始顏色 |
|---------|---------|
| 淺色背景 | `rgba(255, 255, 255, 0.65)` |
| 淺色 hover 背景（原 CSS 定義） | `rgba(255, 255, 255, 0.85)` |
| 深色背景 | `rgba(26, 32, 44, 0.7)` |
| 深色 hover 背景（原 CSS 定義） | `rgba(45, 55, 72, 0.85)` |
| 淺色 hover 覆蓋（實際生效） | `rgba(0, 0, 0, 0.03)` |
| 深色 hover 覆蓋（實際生效） | `rgba(255, 255, 255, 0.04)` |

## 保留差異的部分 ⚠️

目前無保留差異項目。

## 額外修正 ✅

### 3. Article 卡片尾端空白

| 項目 | 原始狀態 | 採用方案 | 狀態 |
|-----|---------|---------|------|
| 尾端 spacer 空白 | `article-link/simple.html` 固定輸出 `<div class="px-6 pt-4 pb-2">` | 以 CSS 將 padding 設為 `0` | ✅ 已實作 |

**技術說明**:
- 不覆蓋 Blowfish 模板，統一移除所有 article 卡片尾端空白
- 避免 standard list 與 card view 視覺不一致

## 已決定的恢復方式（已完成驗證）

### 3. Hover 覆蓋背景色（單層覆蓋）

| 項目 | 原始自訂 | 採用方案 | 狀態 |
|-----|---------|---------|------|
| Hover 覆蓋背景 | `a.article-card-hover:hover { background: rgba(0, 0, 0, 0.03); }` | 直接覆蓋 `article:hover` 背景色 | ✅ 已實作驗證 |

**技術說明**:
- 原始生效規則是 `a.article-card-hover:hover`，其覆蓋色才是實際可視結果
- 現行 Blowfish 結構為 `<article>` 內含 `<a>`（stretched link），因此改為直接在 `article:hover` 套用覆蓋色以還原視覺

## 總結

### 恢復完成度評估

- **完全恢復**：95-100%（核心視覺效果）
- **保留差異**：0-5%（目前無保留差異）
- **待確認項目**：0%（已確認一致）

### 實作策略確認

當前採用**方案 A（務實恢復）**：
- ✅ 優先恢復最重要的視覺效果（毛玻璃、陰影、hover 覆蓋回饋）
- ✅ 與原始設計實際顯示結果一致
- ✅ 完整記錄差異部分，便於未來調整

### 後續行動建議

1. **立即行動**（當前階段）：
   - 實作核心樣式（毛玻璃、陰影、hover 覆蓋回饋）
   - 透過 `hugo server` 驗證渲染效果

2. **視覺驗證**（實作後）：
   - 啟動本地伺服器並檢查不同頁面的卡片外觀
   - 評估是否有其他視覺細節需要再調整

3. **選擇性調整**（根據渲染結果）：
   - 若需進一步微調，可新增局部覆寫
   - 若需要更激進的還原，可建立新的 OpenSpec 變更提案
   - 記錄最終決策與調整原因

## 參考資料

- 原始樣式實作：Git commit `caec243` (`assets/css/posts.css`)
- Hover 覆蓋效果：Git commit `417ec0c` (`assets/css/global.css`)
- Migration Notes: `openspec/changes/archive/2026-01-05-restore-native-cards/migration-notes.md`
- Blowfish 卡片結構：`themes/blowfish/layouts/partials/article-link/simple.html`
