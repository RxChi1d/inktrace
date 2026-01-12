# Implementation Tasks

## 1. 優化 Categories 頁面 (System Glass)
- [x] 1.1 更新 `assets/css/custom/categories.css` 實作高光邊框 (`rgba(255, 255, 255, 0.4)`)
- [x] 1.2 實作「系統選取」Hover 效果（提升亮度、極淡冷灰/藍濾鏡）
- [x] 1.3 調整資料夾圖示使用 currentColor 以確保與標題文字顏色一致
- [x] 1.4 實作 Mobile-first Grid 優化（< 640px 使用 `1fr` 或更小 minmax）

## 2. 優化 Tags 頁面 (Soft Purple Refined)
- [x] 2.1 更新 `assets/css/custom/tags.css` 增加 gap 至 `0.8rem - 1rem` (桌面版)
- [x] 2.2 實作 Mobile-first Gap 優化（< 640px 使用 `0.5rem`）
- [x] 2.3 調整行高 (line-height) 確保標籤雲呼吸感
- [x] 2.4 優化計數器 (Badge) 樣式，降低背景透明度，提升融合感
- [x] 2.5 確保單一標籤頁面標題顏色（H1）保持預設，圖示使用 currentColor 保持一致

## 3. 測試與驗證
- [x] 3.1 驗證 Categories 在 iPhone SE (375px) 等小螢幕上的排版
- [x] 3.2 驗證 Categories 的高光邊框在淺色與深色模式下的質感
- [x] 3.3 驗證 Tags 的間距是否足夠寬鬆舒適（桌面），且在手機上足夠緊湊
- [x] 3.4 驗證 Tags Badge 在不同標籤長度下的顯示效果
- [x] 3.5 確認 Hover 動畫流暢且無卡頓
