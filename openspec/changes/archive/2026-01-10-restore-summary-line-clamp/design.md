## Context
Summary Line Clamp 功能已在 Blowfish PR #2714 完成，但尚未合併到主分支。為維持列表頁摘要的可讀性與排版穩定性，需要在專案端暫時補回該功能，並確保後續可無痛回收自訂覆蓋。

## Goals / Non-Goals
- Goals:
  - 依 PR #2714 的實作方式補回摘要行數限制。
  - 以最小覆蓋方式維持與 Blowfish 原生模板一致。
  - 不修改 `themes/blowfish/`。
  - 清楚記錄覆蓋模板，便於上游合併後移除。
- Non-Goals:
  - 不新增 JavaScript 截斷邏輯。
  - 不改變摘要內容生成或語意。
  - 不調整與 Summary 無關的卡片視覺樣式。

## Decisions
- Decision: 依 PR #2714 複製並覆蓋 4 個 `article-link` partial。
  - `card.html`、`card-related.html` 使用 `line-clamp-5`。
  - `simple.html` 使用 `line-clamp-3`。
  - `_shortcode.html` 依 `compactSummary` 決定是否套用 `line-clamp-3`。
- Decision: 新增 `article-link--*` 與 `article-link__summary` class，與 PR 對齊，方便後續維護與回收。
- Decision: 以專案層級 CSS 補上 `.line-clamp-5`，避免改動主題編譯檔。
- Decision: 更新 `BLOWFISH-OVERRIDES.md` 並同步調整 `MIGRATION_STATUS.md`。

## Alternatives Considered
- 僅用 CSS 嘗試截斷摘要：無法在不覆蓋模板的情況下加上 `line-clamp-5` class。
- 以 JavaScript 讀取字數後截斷：增加不必要的行為與閃爍風險，不符合主題設計邏輯。

## Risks / Trade-offs
- 覆蓋檔案需在 Blowfish 升級時比對，否則可能與上游產生差異。
- PR 尚未合併，後續回收自訂覆蓋需額外處理。

## Migration Plan
1. 透過 `gh` 取得 PR #2714 的程式碼差異，鎖定需覆蓋的 partial。
2. 使用 `cp` 複製 Blowfish 原生模板至 `layouts/partials/article-link/`。
3. 套用 PR 變更（新增 class 與 line-clamp 行為）。
4. 新增自訂 CSS，補上 `.line-clamp-5`。
5. 更新 `BLOWFISH-OVERRIDES.md` 與 `MIGRATION_STATUS.md`。
6. 使用 `hugo server` 與瀏覽器驗證摘要截斷效果。

## Open Questions
- 無。
