# Change: Refine Categories and Tags Styling (System Glass & Soft Purple)

## Why
目前 Categories 和 Tags 分類頁面存在視覺與體驗上的斷層：
1. **Categories 缺乏質感**：現有的灰色玻璃卡片設計較為單調，邊框質感不足，缺乏現代作業系統（如 macOS/Windows 11）的精緻感。
2. **Tags 排版擁擠**：標籤之間的間距過小，視覺上容易形成閱讀壓力，且計數器（Badge）對比度過高，搶了標籤主體的風頭。
3. **視覺邏輯不清晰**：需要區分「Categories = 系統結構（資料夾）」與「Tags = 屬性標記（便利貼）」的視覺語彙，而不是單純統一顏色或完全割裂。

## What Changes
採用 **"System Glass" (系統玻璃)** 與 **"Soft Purple" (柔和紫)** 雙軌設計語言，提升分類頁面的質感與邏輯清晰度：

### 1. Categories：系統結構質感 (System Glass)
*   **設計隱喻**：維持「檔案總管」或「系統資料夾」的冷靜、客觀感。
*   **配色邏輯**：保持 **中性灰/透白** 基調，不引入鮮豔色相。
*   **質感升級**：
    *   **高光邊框**：將原本的黑透邊框改為 **白透高光邊框** (`rgba(255, 255, 255, 0.4)`)，模擬光線打在玻璃邊緣的質感。
    *   **選取狀態 (Hover)**：模擬系統檔案被選取的狀態（亮度提升 + 極淡冷灰/藍濾鏡），而非變色。
    *   **圖示細節**：微調資料夾圖示的透明度與亮度，使其更融入系統背景。
*   **響應式優化**：針對手機版 (< 640px) 優化 Grid 設定，避免卡片過窄或留白過多。

### 2. Tags：屬性標記質感 (Soft Purple)
*   **設計隱喻**：維持「便利貼」或「標記」的裝飾性、多樣性。
*   **配色邏輯**：延續 **柔和紫** (`#4F46E5` / `#a78bfa`) 主題。
*   **排版優化**：
    *   **增加間距**：將 gap 增加至 `0.8rem - 1rem`，增加呼吸感。
    *   **計數器融合**：降低計數器背景透明度，使其像影子般跟隨，不搶視覺焦點。
    *   **行高調整**：確保多行標籤排列時舒適不擁擠。

### 3. 實作方式
*   **純 CSS 方案**：不修改 HTML 模板，僅透過 `categories.css` 和 `tags.css` 調整。
*   **不引入全域 Tokens**：直接在對應的 CSS 檔案中定義局部變數或直接使用數值，保持模組獨立性（除非確有共用需求）。

## Impact
- **Affected specs**: `taxonomy-display`
- **Affected code**:
  - `assets/css/custom/categories.css` (重構質感)
  - `assets/css/custom/tags.css` (優化排版與細節)
- **No template changes required**
