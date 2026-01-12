# Change: 恢復文章卡片視覺樣式（Restore Card Visual Styling）

## Why
在執行 `restore-native-cards` 遷移後，文章列表卡片回歸至 Blowfish 原生結構，但失去了原有的自訂視覺增強效果（毛玻璃背景、陰影、hover 變色等）。這些視覺效果對於提升使用者體驗至關重要，需要在不破壞 Blowfish 原生 HTML 結構的前提下，透過純 CSS 方式恢復核心視覺效果。

## What Changes
- 建立新的 CSS 模組 `assets/css/custom/article-cards.css`，針對 Blowfish 原生卡片結構添加視覺增強樣式
- 恢復毛玻璃背景效果（`backdrop-filter` + 半透明背景色），以原始卡片顏色為基準，直接使用原始 RGBA 色值
- 恢復陰影系統（預設與 hover 狀態的雙層陰影）
- 恢復 hover 視覺回饋（覆蓋背景、陰影、邊框變化）與平滑過渡動畫
- 以卡片本體 hover 覆蓋背景色，避免依賴 `<a>` 包裹結構與疊加層
- 支援深色模式（`.dark` 前綴）
- 建立差異記錄文件 `openspec/changes/restore-card-styling/style-differences.md`，明確記載無法完全恢復的部分（邊框寬度、圓角大小、邊框顏色）

## Impact
- **影響的規格**: `card-layout`
- **影響的檔案**:
  - 新增：`assets/css/custom/article-cards.css`
  - 新增：`openspec/changes/restore-card-styling/style-differences.md`
- **相容性**: 透過 CSS 選擇器 `article.overflow-hidden.rounded-lg.border` 精準定位，不修改 HTML 結構，與 Blowfish 主題更新相容
- **風險**:
  - 選擇器依賴 Blowfish 的 class 命名慣例，主題大幅更新時可能需要調整
  - 某些視覺規格（邊框寬度、圓角）保留 Blowfish 原生規格，與原自訂版本存在差異

## Implementation Strategy
採用**方案 A（務實恢復）**：
- 優先恢復最重要的視覺效果（毛玻璃、陰影、hover 視覺回饋）
- 以原始卡片顏色為基準，直接使用原始 RGBA 色值，確保視覺一致性
- 接受與 Blowfish 原生規格的差異（邊框、圓角），避免維護成本
- 完整記錄差異部分，便於未來根據實際渲染結果進行調整
