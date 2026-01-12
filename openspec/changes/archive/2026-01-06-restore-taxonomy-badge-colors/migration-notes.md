# Migration Notes: Taxonomy Badge i18n

本次變更移除專案層級 `layouts/partials/badge.html`，改回 Blowfish 原生 badge。這會帶來以下行為差異：

## 影響摘要

- **badge 內建 i18n 將被移除**
  - Blowfish 原生 badge 只輸出字串，不會執行 `i18n`。
  - taxonomy badges 的文字來源為 `.LinkTitle`，其值不會自動對應 i18n key。

## 遷移建議（未納入本次變更）

若未來要顯示翻譯後的 taxonomy 名稱，建議採用 Hugo 的 term content 機制：

1. 為 taxonomy term 建立多語 `_index.md`：
   - `content/categories/<term>/_index.zh-tw.md`
   - `content/categories/<term>/_index.en.md`
   - `content/tags/<term>/_index.zh-tw.md`
   - `content/tags/<term>/_index.en.md`

2. 在 front matter 設定 `title` 或 `linkTitle`：
   - `.LinkTitle` 會依語言自動帶出翻譯名稱

## 後續擴充方向（可選）

- 若要維持 i18n key 的使用方式，可另開變更：
  - 在 taxonomy 渲染前先做 i18n 轉譯（透過自訂 partial）
  - 或建立專案層級擴充點來處理 taxonomy label 的翻譯
- **下一個功能建議**：新增「Taxonomy 翻譯支援」變更，統一規範 term `_index.md` 多語標題的建立流程

本次變更僅針對顏色區分恢復，i18n 翻譯維持現況。
