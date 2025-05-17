# Layouts 目錄檔案功能與用途

以下是 `layouts/` 目錄下檔案的功能與用途說明：

## _default/

- **baseof.html**:
  這是 Hugo 網站的基礎模板。它定義了基本的 HTML 結構（`<!DOCTYPE html>`, `<html>`, `<head>`, `<body>`），並引入了網站所需的通用 partials，例如 `head.html`, `header.html`, `footer.html`。它也定義了主要的內容區塊 `{{ block "main" . }}{{ end }}`，供其他模板覆寫。此外，它還包含了數學渲染、滾動到頂部、搜尋功能和 Buy Me A Coffee 小部件的邏輯。

- **single.html**:
  這是用於渲染單一頁面（例如部落格文章）的模板。它擴展了 `baseof.html` 模板，並在 "main" 區塊中定義了單一頁面的佈局。它包含了顯示 Hero 區塊、麵包屑、文章標題和元資訊、作者詳細資訊、目錄、文章內容、回覆郵件連結、系列導航、分享連結、相關文章、文章分頁和評論區塊的邏輯。

- **term.html**:
  這是用於渲染分類或標籤等 Taxonomy Term 頁面的模板。它擴展了 `baseof.html` 模板，並在 "main" 區塊中定義了 Term 頁面的佈局。它包含了顯示 Hero 區塊、麵包屑、Term 標題、Term 元資訊、Term 內容以及與該 Term 相關聯的頁面列表。頁面列表支援簡單列表或卡片視圖，並可按年份分組。

- **_markup/render-blockquote.html**:
  這是 Markdown 中用於渲染 Blockquote 的 Render Hook。它增強了預設的 Blockquote 渲染，以支援具有不同類型（note, info, tip, important, warning, caution, danger, error, success, check）、自訂標題和可選摺疊行為的自訂警示/提示區塊。它包含了根據警示類型選擇適當圖標的邏輯。

## categories/

- **term.html**:
  這是用於渲染單一分類 Term 頁面的模板。它與 `_default/term.html` 非常相似，但專門在標題中包含一個用於分類的 SVG 圖標。它擴展了 `baseof.html` 模板，並在 "main" 區塊中定義了佈局，顯示 Hero 區塊、麵包屑、帶有圖標的分類 Term 標題、Term 元資訊、Term 內容以及與該分類 Term 相關聯的頁面列表，並提供不同的視圖和分組選項。

- **terms.html**:
  這是用於渲染主要分類列表頁面的模板。它擴展了 `baseof.html` 模板，並在 "main" 區塊中定義了佈局。它包含了顯示 Hero 區塊、麵包屑、頁面標題（可能是「分類」）和頁面內容的邏輯。然後，它列出了所有分類 Term，並提供指向其各自 Term 頁面的連結以及每個分類中的文章計數。每個分類項目都包含一個 SVG 圖標。

## partials/

- **badge.html**:
  這是用於渲染徽章的 Partial 模板。它接受文字和可選的類型（category 或 tag）作為輸入。它根據類型應用不同的 CSS 類別來設定徽章樣式，並顯示提供的文字，可能使用 `i18n` 進行本地化。

- **head.html**:
  這是負責生成 HTML 文件 `<head>` 區塊的 Partial 模板。它包含了字元集、語言、視口和相容性的 Meta 標籤。它根據頁面上下文和網站參數動態設定頁面標題、描述和關鍵字。它還處理 Canonical 連結、替代輸出格式，並捆綁 CSS 和 JavaScript 資源（包括自訂 CSS、搜尋、程式碼複製、RTL 支援和行動選單腳本）。此外，它還包含了 Favicons、網站驗證 Meta 標籤、Open Graph 和 Twitter Cards Meta 標籤、Schema Markup、作者資訊、供應商腳本、分析和 Firebase 初始化邏輯。

- **math.html**:
  這是包含用於使用 MathJax 渲染數學表達式所需 JavaScript 的 Partial 模板。它配置 MathJax 使用 AMS 標記法處理方程式，設定標記位置和縮進，並定義顯示和行內數學的分隔符號。它還載入 `ams` 套件並指定在處理期間要跳過的 HTML 標籤。

- **toc.html**:
  這是用於顯示文章目錄 (TOC) 的 Partial 模板。它使用 `<details>` 和 `<summary>` 標籤使 TOC 在較小的螢幕上可摺疊。它顯示生成的目錄 HTML (`.TableOfContents`)，並包含處理滾動行為和根據使用者滾動位置在 TOC 中突出顯示當前區塊的 JavaScript，並提供一個隱藏非焦點子項目的「智慧 TOC」選項。

- **article-link/simple.html**:
  這是用於渲染文章簡單連結的 Partial 模板，通常用於文章列表（例如在 Taxonomy Term 頁面或首頁）。它顯示文章標題、元資訊（使用 `article-meta/basic.html`），以及可選的摘要。它還包含了顯示特色圖片和處理外部連結的邏輯。樣式會根據網站參數中是否啟用卡片視圖進行調整。

- **article-meta/basic.html**:
  這是用於顯示文章元資訊的 Partial 模板。它可以在不同的上下文（單一頁面或列表）中使用。它包含了根據網站和頁面參數有條件地顯示發布日期、最後修改日期、字數、閱讀時間、瀏覽次數、按讚數、編輯連結和 Zen Mode 連結的邏輯。它還使用 `badge.html` Partial 顯示作者徽章和 Taxonomy Terms（分類和標籤）作為可點擊的徽章。

- **home/custom.html**:
  這是用於自訂首頁佈局的 Partial 模板。它包含了背景圖片、作者個人資料（圖片、姓名、標題、社交連結和內容）以及部落格標題和描述的區塊。它還包含了 `recent-articles/main.html` Partial 以顯示最新文章。該佈局設計為響應式，在中等螢幕及以上尺寸時，個人資料和部落格資訊的對齊方式不同。

- **home/profile.html**:
  這是用於個人資料風格首頁佈局的 Partial 模板。它與 `layouts/partials/home/custom.html` 非常相似，但缺少背景圖片區塊。它包含了作者個人資料（圖片、姓名、標題、社交連結和內容）以及部落格標題和描述的區塊。它還包含了 `recent-articles/main.html` Partial 以顯示最新文章。該佈局設計為響應式，在中等螢幕及以上尺寸時，個人資料和部落格資訊的對齊方式不同。

- **term-link/card.html**:
  這是用於以卡片格式渲染 Taxonomy Term 頁面連結的 Partial 模板。它顯示 Term 標題、可選的特色圖片，以及與該 Term 相關聯的項目計數作為徽章。在啟用卡片視圖的 Term 列表頁面中使用。

- **term-link/text.html**:
  這是用於以簡單文字格式渲染 Taxonomy Term 頁面連結的 Partial 模板。它將 Term 標題顯示為連結，並可選地顯示與該 Term 相關聯的項目計數。在未啟用卡片視圖的 Term 列表頁面中使用。

## posts/

- **list.html**:
  這是用於渲染文章列表的模板。它擴展了 `baseof.html` 模板，並在 "main" 區塊中定義了文章列表的佈局。它包含了顯示 Hero 區塊、麵包屑、頁面標題（可能是「文章」）和頁面內容的邏輯。然後，它列出了文章，提供時間軸視圖或卡片視圖選項，並可按年份分組或按權重排序。時間軸視圖使用 `article-link/simple.html` Partial，卡片視圖使用 `article-link/card.html` Partial。它還包含分頁功能。

## tags/

- **term.html**:
  這是用於渲染單一標籤 Term 頁面的模板。它與 `_default/term.html` 和 `layouts/categories/term.html` 非常相似，但專門在標題中包含一個用於標籤的 SVG 圖標。它擴展了 `baseof.html` 模板，並在 "main" 區塊中定義了佈局，顯示 Hero 區塊、麵包屑、帶有圖標的標籤 Term 標題、Term 元資訊、Term 內容以及與該標籤 Term 相關聯的頁面列表，並提供不同的視圖和分組選項。

- **terms.html**:
  這是用於渲染主要標籤列表頁面的模板。它擴展了 `baseof.html` 模板，並在 "main" 區塊中定義了佈局。它包含了顯示 Hero 區塊、麵包屑、頁面標題（可能是「標籤」）和頁面內容的邏輯。然後，它列出了所有標籤 Term，並提供指向其各自 Term 頁面的連結以及每個標籤中的文章計數。
