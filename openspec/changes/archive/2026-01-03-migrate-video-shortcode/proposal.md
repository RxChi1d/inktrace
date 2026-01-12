# Proposal: 遷移至 Blowfish 原生 Video Shortcode

## Why
專案目前維護一個自訂的 `video` shortcode (`layouts/shortcodes/video.html`) 和自訂樣式 (`assets/css/custom/video-shortcode.css`)。隨著升級至 Blowfish v2.96.0，主題現在原生提供了一個穩健、響應式且功能豐富的 `video` shortcode。保留自訂實作會增加維護成本、造成潛在衝突，並阻礙使用主題的原生功能（如長寬比控制和資源處理）。

## 驗證發現 (Verification Findings)
- **Title 參數**: 經全站搜尋，確認目前沒有文章使用 `title` 參數，因此無需處理標題顯示的遷移。
- **Class 參數**: 在 `content/posts/paper-survey/NSF.md` 中發現使用 `class="grid-w50"` 配合 `gallery` 使用。
    - 自訂實作會將 `class` 加在 `<figure>` 上，使 `gallery` 排版生效。
    - **原生實作不支援 `class` 參數**，直接切換會導致 `grid-w50` 失效，破壞排版。
    - **解決方案**: 需將這些 `video` shortcode 用 `<div class="grid-w50">...</div>` 包裹。

## What Changes
1.  **修改內容**: 更新 `content/posts/paper-survey/NSF.md`，將帶有 `class` 的 `video` shortcode 改寫為 `div` 包裹形式。
2.  **刪除檔案**: 
    - `layouts/shortcodes/video.html`
    - `assets/css/custom/video-shortcode.css`

## 影響 (Impact)
- **視覺變更**:
    - 除非指定 `ratio`，否則影片將預設為全寬 (`w-full`) 且長寬比為 16:9。
    - `NSF.md` 的排版將透過 `div` 包裹維持原樣。
- **效益**:
    - 減少程式碼庫大小。
    - 更好地整合主題的深色模式和設計系統。
    - 可使用新功能如 `ratio` (長寬比)、`fit` (object-fit) 和時間片段 (`#t=`)。

## 風險 (Risks)
- 若有遺漏的 `class` 使用案例（非標準格式），可能會導致部分排版跑版。但已透過正則表達式和人工檢查盡量降低此風險。

## 計畫 (Plan)
1.  修改 `content/posts/paper-survey/NSF.md`，處理 `class="grid-w50"`。
2.  刪除自訂 video shortcode 檔案與樣式。
3.  驗證網站構建與 `NSF.md` 的顯示效果。
