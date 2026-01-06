# Implementation Tasks

## 1. 建立差異記錄文件
- [x] 1.1 建立 `style-differences.md`，記錄完全恢復、部分差異與無法恢復的樣式項目
- [x] 1.2 包含原始 CSS 規格與現行 Blowfish 規格的對比表格
- [x] 1.3 說明保留差異的技術原因與維護性考量
- [x] 1.4 列出原始 RGBA 色值清單（淺色/深色/hover/覆蓋）
- [x] 1.5 說明採用原始 RGBA 的理由（視覺一致性優先）

## 2. 實作 CSS 模組
- [x] 2.1 建立 `assets/css/custom/article-cards.css`
- [x] 2.2 在檔案頂部添加詳細註解，說明選擇器策略與差異項目
- [x] 2.3 實作毛玻璃背景效果（`backdrop-filter: blur(10px)` + 原始 RGBA 半透明背景色）
- [x] 2.4 實作陰影系統（預設狀態：`box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05)`）
- [x] 2.5 實作 hover 陰影增強（`box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1)`）
- [x] 2.6 hover 背景改為覆蓋色（淺色 `rgba(0, 0, 0, 0.03)` / 深色 `rgba(255, 255, 255, 0.04)`）
- [x] 2.7 添加平滑過渡動畫（`transition: background-color 0.3s ease, box-shadow 0.3s ease, border-color 0.3s ease`）
- [x] 2.8 實作深色模式樣式（`.dark` 前綴，使用原始 RGBA）
- [x] 2.9 確保 Safari 相容性（`-webkit-backdrop-filter` 前綴）
- [x] 2.10 確認 `custom/` 載入順序不敏感，維持 `article-cards.css` 檔名（不加數字前綴）
- [x] 2.11 移除 `article::before` hover 疊加層
- [x] 2.12 移除疊加層相關層級與互動設定（`z-index` / `pointer-events`）
- [x] 2.13 保留 hover 過渡動畫（背景、陰影、邊框）

## 3. 驗證與測試
- [x] 3.1 啟動 Hugo Server (`hugo server`) 並檢查淺色模式卡片渲染
- [x] 3.2 切換至深色模式並檢查卡片渲染
- [x] 3.3 測試 hover 效果流暢度（覆蓋背景、陰影變化、邊框變化）
- [x] 3.4 在不同頁面（首頁、Posts 列表、分類頁）驗證樣式一致性
- [x] 3.5 使用瀏覽器開發者工具確認選擇器精準度（未誤傷其他元素）
- [x] 3.6 測試響應式表現（桌面、平板、手機）
- [x] 3.7 確認覆蓋背景在淺色/深色 hover 都符合原始覆蓋色且不影響文字可讀性
- [x] 3.8 確認 hover 覆蓋不影響卡片點擊區與標題連結互動
- [x] 3.9 執行 `openspec validate restore-card-styling --strict`

## 4. 文件更新
- [x] 4.1 更新 `openspec/changes/archive/2026-01-05-restore-native-cards/migration-notes.md`，標記「Card Visual Styling」已處理
- [x] 4.2 在 migration notes 中添加指向 `restore-card-styling` 變更的參考連結

## 5. 後續行動項目（根據渲染結果決定）
- [x] 5.1 評估是否需要調整邊框寬度（從 1px 增加至 2px）
- [x] 5.2 評估是否需要調整圓角大小（從 `rounded-lg` 改為 `rounded-2xl`）
- [x] 5.3 評估是否需要調整邊框顏色（從 `border-neutral-300/600` 改為 `border-neutral-200/700`）
- [x] 5.4 若仍需微調色值，提出後續變更

## 6. 邊框顏色差異調查（不改碼）
- [x] 6.1 使用瀏覽器開發者工具確認卡片邊框的實際 `border-color`（淺色/深色/hover）
- [x] 6.2 確認套用邊框的元素是否為 `article.overflow-hidden.rounded-lg.border`（避免誤判到其他元素）
- [x] 6.3 檢查 `article-cards.css` 是否有載入（確認自訂 bundle 是否包含此檔案）
- [x] 6.4 檢查是否有其他樣式覆寫邊框（例如 `border-neutral-*`、`ring-*`、`outline` 或 `border` shorthand）
- [x] 6.5 確認生效規則來源（開發者工具的 Rules 面板，是否命中 `article-cards.css`）
- [x] 6.6 檢查是否有 `.bf-border-color` / `.bf-border-color-hover` 類別被套用（或在 hover 時生效）
- [x] 6.7 若計算值正確但視覺仍偏差，評估是否為邊框寬度或背景混色造成（已確認一致）
- [x] 6.8 根據調查結論決定後續修正策略（已確認無需調整邊框顏色）

## 7. Hover 背景色校正（不改碼）
- [x] 7.1 釐清問題來源：主要 hover 背景過亮（深色）/過淡（淺色）
- [x] 7.2 對照原始設計的 DOM 與 CSS：主卡片為 `<a.article-card-hover>`，`a.article-card-hover:hover` 的背景色因更高特異性覆蓋 `.article-card-hover:hover`
- [x] 7.3 定義調整策略：hover 背景改為覆蓋色，移除疊加層
- [x] 7.4 更新 CSS：改為覆蓋式背景色，保留陰影/邊框變化
- [x] 7.5 更新規格與差異文件，反映「覆蓋式 hover」
- [x] 7.6 重新驗證 hover 效果（淺色/深色）

## 8. Article 卡片尾端空白修正
- [x] 8.1 調查空白來源：確認 `article-link/simple.html` 內的尾端 spacer div
- [x] 8.2 以 CSS 移除所有 article 卡片尾端 padding（不覆蓋模板）
- [x] 8.3 套用到 standard list、card view、related cards，確保一致性

## 9. 邊框與圓角恢復
- [x] 9.1 將卡片邊框寬度維持 `1px`（沿用原始實際顯示）
- [x] 9.2 將卡片圓角改回 `1rem`（`rounded-2xl` 規格）
- [x] 9.3 更新差異文件，移除邊框寬度差異、移除圓角差異
