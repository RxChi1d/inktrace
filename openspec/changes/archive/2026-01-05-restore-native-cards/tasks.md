# 任務：恢復原生卡片行為

1.  [x] **建立遷移備註** <!-- id: 0 -->
    -   建立 `openspec/changes/restore-native-cards/migration-notes.md`，記錄後續需要補回的功能（摘要行數限制、標籤顏色）。

2.  [x] **移除自訂版面** <!-- id: 1 -->
    -   刪除 `layouts/partials/article-link/simple.html`。
    -   刪除 `layouts/partials/article-meta/basic.html`。
    -   *理由*: 讓 Hugo 回退至 Blowfish 主題原生檔案，確保 100% 原生行為。

3.  [x] **盤點覆寫範圍** <!-- id: 2 -->
    -   檢查 `layouts/partials/article-link/` 與 `layouts/partials/article-meta/` 是否仍有其他覆寫檔案。
    -   若有殘留覆寫，確認是否會影響原生卡片結構，並記錄或移除。

4.  [x] **清理設定** <!-- id: 3 -->
    -   編輯 `config/_default/params.toml`。
    -   移除 `showCategories` 鍵。
    -   移除 `showTags` 鍵。

5.  [x] **盤點文件與引用** <!-- id: 4 -->
    -   使用 `rg` 搜尋全專案是否仍出現 `showCategories` 或 `showTags` 的文件說明或範例。
    -   若有，更新相關文件以反映移除後的設定。

6.  [x] **盤點自訂 CSS 殘留** <!-- id: 5 -->
    -   檢查 `assets/css/custom/` 是否仍有與徽章顏色、摘要行數限制或 `article-card-hover` 相關的樣式。
    -   若未再被使用，移除或在遷移備註中註記保留原因。

7.  [x] **補充卡片視覺差異紀錄** <!-- id: 6 -->
    -   在 migration notes 中補充原生與自訂卡片的視覺差異（背景、hover、圓角、邊框）。

8.  [x] **驗證** <!-- id: 8 -->
    -   在本地建置網站（`hugo`）。
    -   驗證首頁與列表頁的文章卡片可完整點擊（透過 Stretched Link）。
    -   驗證渲染後 HTML 的卡片容器未被 `<a>` 標籤包住。
    -   驗證文章標題 `<a>` 含有 stretched-link 類別（例如 `before:inset-0`）。
    -   驗證分類/標籤徽章為可點擊連結（標準 `<a>`）且使用預設顏色。
    -   驗證點擊徽章不會觸發父層卡片連結（z-index 處理）。
    -   驗證縮圖以 `<img>` 標籤載入正常。
