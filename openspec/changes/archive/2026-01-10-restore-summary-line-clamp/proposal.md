# Change: 補回 Summary Line Clamp（暫時覆蓋 Blowfish 模板）

## Why
Blowfish PR #2714 尚未合併，導致列表頁摘要（Summary）缺少行數截斷（line-clamp）功能。為避免摘要過長破壞卡片排版與閱讀節奏，本變更將以最小覆蓋方式先行補回該功能，並保持與上游 PR 的實作一致，待上游合併後再移除自訂覆蓋。

## What Changes
- 依 PR #2714 的差異內容，覆蓋並調整 `article-link` 相關 partial（以 `cp` 從 Blowfish 原生模板複製後再修改）：
  - `layouts/partials/article-link/card.html`
  - `layouts/partials/article-link/card-related.html`
  - `layouts/partials/article-link/simple.html`
  - `layouts/partials/article-link/_shortcode.html`
- 新增自訂 CSS（專案層級）補上 `.line-clamp-5` utility，避免改動 `themes/blowfish/` 的編譯檔。
- 更新 `BLOWFISH-OVERRIDES.md`，記錄本次新增覆蓋模板與其必要性。
- 更新 `MIGRATION_STATUS.md`，將 Summary Line Clamp 從等待上游移至已完成，並加註「暫時覆蓋，等待上游更新後回收」。

## Impact
- Affected specs: `card-layout`（新增摘要截斷需求）、`theme-overrides`（更新覆蓋清單）。
- Affected code: `layouts/partials/article-link/*`、`assets/css/custom/*`、`BLOWFISH-OVERRIDES.md`、`MIGRATION_STATUS.md`。
- 注意事項：所有調整需以 PR #2714 為準，且不得修改 `themes/blowfish/` 內任何檔案。
