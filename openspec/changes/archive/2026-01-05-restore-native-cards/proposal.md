# Proposal: Restore Native Card Behavior

## Summary
本提案旨在將專案的文章卡片行為與參數設定回歸 Blowfish 主題的原生邏輯。主要目標是修復目前自訂實作造成的 HTML 結構問題（巢狀連結），並移除未使用的自訂參數。

## Problem
1.  **HTML 結構衝突**：目前的卡片設計將整個卡片包裹在一個 `<a>` 標籤中，這迫使內部的 Taxonomy Badge 使用 `<span>` 加上 `onclick` JS 事件來模擬連結，以避免 HTML 禁止的巢狀連結（Nested Links）。
2.  **維護成本增加**：偏離主題原生設計導致需要維護複雜的自訂 Layout (`simple.html`, `basic.html`)，且容易與上游主題更新產生衝突。
3.  **參數冗餘**：`showCategories` 與 `showTags` 參數在當前設定下未被實際使用，且與原生 `showTaxonomies` 邏輯重疊。

## Solution
1.  **移除自訂 Layout**：直接刪除專案中的 `layouts/partials/article-link/simple.html` 與 `layouts/partials/article-meta/basic.html`，讓 Hugo 自動使用 Blowfish 主題提供的原生��案。這將自動恢復 Stretched Link 卡片結構與標準 Taxonomy 連結。
2.  **移除自訂參數**：移除 `config/_default/params.toml` 中的 `showCategories` 與 `showTags`，完全採用原生的 `showTaxonomies` 與 `showCategoryOnly` 控制邏輯。

## Impact
-   **視覺影響**：Taxonomy Badge 將暫時失去分類（綠色）與標籤（藍色）的顏色區分，統一回歸主題預設樣式（已記錄於 migration-notes.md）。
-   **功能影響**：
    -   Summary Line Clamp 功能將暫時移除（已記錄於 migration-notes.md）。
    -   圖片載入將回歸原生 `<img>` 標籤（支援 Lazy Loading）。
    -   卡片點擊行為維持不變（透過 CSS Stretched Link）。
-   **程式碼影響**：移除自訂覆寫檔案，消除技術債，未來可直接受益於主題更新。

## Risk
-   **低**：回歸主題原生邏輯是標準化過程，風險主要在於確認所有連結在重構後是否依然有效。