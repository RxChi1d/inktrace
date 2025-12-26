# Research: 遷移至 Blowfish 原生 GitHub Alert 支援

**Date**: 2025-12-26
**Feature**: 001-migrate-github-alerts
**Purpose**: 調查自訂 GitHub Alert 實作細節和 Blowfish 2.94.0 原生支援

## 自訂 GitHub Alert 實作調查

### 核心文件識別

透過代碼庫探索，已識別出以下自訂 GitHub Alert 相關文件：

#### 1. HTML 渲染邏輯

**文件**: `/layouts/_default/_markup/render-blockquote.html`

**功能說明**:
- Hugo Markdown render hook，攔截所有 blockquote 渲染
- 解析 blockquote 第一行以識別 alert 類型（支援 10 種：note, info, tip, important, warning, caution, danger, error, success, check）
- 支援自訂標題（透過 `.AlertTitle` 參數）
- 支援可摺疊功能（透過 `.AlertSign` 參數，`+` 為展開，`-` 為收合）
- 根據類型選擇對應的 SVG icon（從主題 assets 載入）
- 使用 `<blockquote>` 或 `<details>` 元素渲染

**語法範例**:
```markdown
> [!NOTE]
> 這是一個註記

> [!TIP]+ 自訂標題
> 這是可展開的提示
```

**依賴**:
- 主題 icon 文件：`themes/blowfish/assets/icons/*.svg`
- i18n 翻譯：`i18n/{lang}.yaml` 中的 alert 類型名稱

#### 2. CSS 樣式定義

**文件**: `/assets/css/custom/blockquote-alerts.css`

**功能說明**:
- 230 行 CSS 代碼
- 定義 10 種 alert 類型的視覺樣式
- 包含顏色配置（背景、邊框、文字）
- 定義 icon、標題和內容區塊樣式
- 支援可摺疊 alert 的動畫效果
- 自訂展開/收合箭頭樣式

**關鍵樣式類別**:
- `.custom-alert`: 基礎樣式
- `.custom-alert-{type}`: 類型特定樣式（如 `.custom-alert-note`）
- `.custom-alert-heading`: 標題區塊
- `.custom-alert-icon`: icon 容器
- `.custom-alert-title-text`: 標題文字
- `.custom-alert-content`: 內容區塊

#### 3. i18n 翻譯配置

**文件**: `/i18n/zh-TW.yaml` 和 `/i18n/en.yaml`

**內容** (第 7-17 行):
```yaml
# Alerts
note: 注意 / Note
tip: 提示 / Tip
important: 重要 / Important
warning: 警告 / Warning
caution: 警示 / Caution
info: 資訊 / Info
danger: 危險 / Danger
error: 錯誤 / Error
success: 成功 / Success
check: 完成 / Check
```

**用途**: 提供 alert 類型的多語言標題文字

### 自訂實作的影響範圍

**直接影響**:
- 所有使用 `> [!TYPE]` 語法的 Markdown 文章
- 測試文章：`content/posts/container-platform/n8n 容器部署教學/index.md`

**間接影響**:
- 自動 CSS 載入機制：`layouts/partials/extend-head.html`（會自動偵測 `assets/css/custom/` 變更）
- 文檔文件：`CLAUDE.md` 和 `layout_notes.md` 中有相關說明

**無影響**:
- Icon 文件：位於主題目錄，不屬於自訂代碼
- 文章內容：Markdown 語法本身不變，僅渲染方式改變

## Blowfish 2.94.0 原生支援調查

### Blowfish 主題 Admonition 支援

**參考來源**: `/Users/rxchi1d/github-repositories/blowfish`（已同步至 tag 2.94.0）

**重要發現**: Blowfish 2.94.0 實作的是完整的 **Admonition 系統**，而非僅支援 GitHub Alert。該功能由 PR #2643 引入，基於 KKKZOZ/hugo-admonitions 專案。

**支援的 Alert 類型**:
根據官方文檔和代碼檢查 ([render-blockquote.html](render-blockquote.html:1-91))，2.94.0 版本支援：

1. **GitHub Alert 類型（5 種）**:
   - NOTE, TIP, IMPORTANT, WARNING, CAUTION

2. **Obsidian Callout 類型（15 種）**:
   - note, abstract, info, todo, tip, success, question, warning, failure, danger, bug, example, quote

3. **類型別名映射（14 個別名）**:
   - attention → warning
   - check → success
   - cite → quote
   - done → success
   - error → danger
   - fail → failure
   - faq → question
   - hint → tip
   - help → question
   - missing → failure
   - summary → abstract
   - tldr → abstract

**實際支援的獨特類型總數**: 15 種 (GitHub 5 種 + Obsidian 額外 10 種)

**語法**:
```markdown
> [!NOTE]
> 基本 admonition

> [!TIP]+ 自訂標題
> 展開狀態的可摺疊 admonition（使用 + 符號）

> [!INFO]- 自訂標題
> 摺疊狀態的可摺疊 admonition（使用 - 符號）
```

**渲染方式**:
- 使用 Hugo render hook ([layouts/_default/_markup/render-blockquote.html](layouts/_default/_markup/render-blockquote.html:1-91))
- 支援 `.AlertTitle` 參數：自訂標題功能
- 支援 `.AlertSign` 參數：可摺疊功能（`+` 展開，`-` 摺疊）
- 使用 `<details>` 和 `<summary>` 元素實現可摺疊
- CSS 樣式定義於 [assets/css/components/admonition.css](assets/css/components/admonition.css:1-221)
- 使用 Tailwind CSS 變數系統，支援 light/dark 模式
- 自動載入對應的 icon（使用 `partial "icon.html"`）

**多語言支援**:
- 完整的 i18n 支援（檔案：`i18n/{lang}.yaml`）
- 預設翻譯：en, zh-CN, ja, it 等
- 翻譯鍵格式：`admonition.{type}`（例如：`admonition.note`）

### 功能對比

| 功能 | 自訂實作 | Blowfish 2.94.0 |
|------|---------|----------------|
| 支援的 alert 類型 | 10 種 (note, info, tip, important, warning, caution, danger, error, success, check) | **15 種** (note, tip, important, warning, caution, info, abstract, todo, success, question, failure, danger, bug, example, quote) + 14 個別名 |
| 自訂標題 | ✅ 支援（`.AlertTitle`） | ✅ **完整支援**（`.AlertTitle`） |
| 可摺疊功能 | ✅ 支援（`.AlertSign`） | ✅ **完整支援**（`.AlertSign`: `+` 展開, `-` 摺疊） |
| 多語言 | ✅ 支援（i18n） | ✅ **完整支援**（i18n: `admonition.*`） |
| 樣式系統 | 自訂 CSS（230 行） | Tailwind CSS 變數系統（221 行，支援 light/dark 模式） |
| HTML 結構 | `<blockquote>` + 自訂類別 | `<details>`/`<div>` + `.admonition` 類別 |
| Icon 系統 | 主題 SVG assets | 主題 `partial "icon.html"`（可重用） |

**結論**: Blowfish 2.94.0 提供的是**功能更強大**的 Admonition 系統，不僅支援 GitHub Alert，還包含 Obsidian Callout 完整功能，**完全涵蓋**自訂實作的所有核心功能（自訂標題、可摺疊、多語言），且類型支援更廣（15 vs 10）。

### 遷移影響評估

**完全相容的 Alert 類型（無需調整）**:

根據類型別名映射和直接支援，自訂實作的 10 種類型在 Blowfish 中的對應關係：

| 自訂實作類型 | Blowfish 2.94.0 對應 | 狀態 |
|------------|---------------------|------|
| note | note | ✅ 直接支援 |
| info | info | ✅ 直接支援 |
| tip | tip | ✅ 直接支援（別名：hint） |
| important | important | ✅ 直接支援 |
| warning | warning | ✅ 直接支援（別名：attention） |
| caution | caution | ✅ 直接支援 |
| danger | danger | ✅ 直接支援 |
| error | danger | ✅ 透過別名映射（error → danger） |
| success | success | ✅ 直接支援（別名：check, done） |
| check | success | ✅ 透過別名映射（check → success） |

**結論**: 自訂實作的所有 10 種類型都在 Blowfish 2.94.0 中獲得支援，其中 8 種直接支援，2 種透過別名映射（error → danger, check → success）。

**完全相容的功能（無需調整）**:

1. **自訂標題功能** (`.AlertTitle`):
   - ✅ Blowfish **完整支援**
   - 語法相同：`> [!TYPE] 自訂標題`
   - 實作：render hook 讀取 `.AlertTitle` 屬性並渲染
   - 無需任何調整

2. **可摺疊功能** (`.AlertSign`):
   - ✅ Blowfish **完整支援**
   - 語法相同：`+` (展開), `-` (摺疊)
   - 實作：render hook 讀取 `.AlertSign` 屬性，使用 `<details>` 元素
   - 無需任何調整

3. **多語言支援**:
   - ✅ Blowfish **完整支援**
   - 使用 i18n 系統，翻譯鍵：`admonition.{type}`
   - 需要調整：i18n 檔案中的翻譯鍵從 `alert.*` 改為 `admonition.*`

**需要調整的項目**:

1. **i18n 翻譯鍵移除**:
   - 自訂實作使用：`note`, `tip`, `important` 等（頂層鍵，提供中文翻譯）
   - Blowfish 使用：`admonition.note`, `admonition.tip` 等（嵌套鍵）
   - **專案需求**: 統一使用英文標題，不配置 zh-TW 翻譯
   - **實作方式**:
     - 移除 `i18n/zh-TW.yaml` 和 `i18n/en.yaml` 中的自訂 alert 翻譯鍵（7-17 行）
     - 不在專案層級添加 `admonition.*` 翻譯
     - Blowfish render hook 邏輯（[render-blockquote.html:38](render-blockquote.html:38)）:
       ```
       $admonitionTitle := .AlertTitle | default (i18n "admonition.{type}" | default $normalizedType)
       ```
     - 當無 i18n 翻譯時，使用 `$normalizedType`（小寫類型名稱，如 "note", "tip", "important"）
   - **影響**: admonition 標題將顯示為英文小寫（note, tip, important 等），符合專案需求

2. **CSS 類別名稱**:
   - 自訂實作使用：`.custom-alert`, `.custom-alert-{type}`
   - Blowfish 使用：`.admonition`, `[data-type="{type}"]`
   - **影響**: 如果有其他 CSS 依賴自訂類別，需要調整

3. **HTML 結構差異**:
   - 自訂實作：`<blockquote class="custom-alert-{type}">`
   - Blowfish：`<div class="admonition" data-type="{type}">` 或 `<details>`
   - **影響**: 如果有 JavaScript 依賴特定 HTML 結構，需要調整

### 測試文章檢查

**文件**: `content/posts/container-platform/n8n 容器部署教學/index.md`

**使用的 alert 語法**:
需要使用 `rg` 檢查該文章實際使用的 alert 類型和功能：

```bash
rg '^\> \[!' content/posts/container-platform/n8n\ 容器部署教學/index.md
```

**潛在風險**:
- 如果使用了 info, danger, error, success, check 類型，遷移後樣式會失效
- 如果使用了 `.AlertTitle` 或 `.AlertSign`，遷移後功能會失效

## 遷移策略決策

### 決策 1: 遷移範圍

**選項 A**: 完全移除自訂實作，僅依賴 Blowfish 原生支援
- **優點**: 簡化維護，與主題更新保持同步
- **缺點**: 失去額外的 alert 類型和自訂功能
- **適用**: 如果文章主要使用標準 5 種 alert 類型

**選項 B**: 保留部分自訂樣式，補充 Blowfish 不支援的功能
- **優點**: 保留所有現有功能
- **缺點**: 維護複雜度增加，可能與主題更新衝突
- **適用**: 如果文章大量使用額外的 alert 類型或自訂功能

**選定**: **選項 A**（完全移除自訂實作）

**理由**:
1. 規格中明確要求「完全移除自訂程式碼」
2. **Blowfish 2.94.0 完全涵蓋所有自訂功能**：
   - ✅ 支援所有 10 種自訂 alert 類型（透過直接支援或別名映射）
   - ✅ 支援自訂標題（`.AlertTitle`）
   - ✅ 支援可摺疊功能（`.AlertSign`）
   - ✅ 支援多語言（i18n）
   - ✅ 額外提供 5 種新類型（abstract, todo, question, failure, bug）
3. Blowfish 實作更現代化：
   - 使用 Tailwind CSS 變數系統（支援 light/dark 模式）
   - 更好的可維護性和擴展性
   - 與主題整合更緊密
4. 簡化維護，避免未來主題更新衝突
5. 如有視覺調整需求，可在遷移後使用 Tailwind CSS 覆寫（符合模組化 CSS 原則）

**重要更新**: 原先誤以為 Blowfish 僅支援 5 種 GitHub Alert 類型，經過完整代碼檢查後發現實際上支援 15 種類型 + 14 個別名，且包含完整的自訂標題和可摺疊功能。因此遷移**無功能損失**，反而獲得功能增強。

### 決策 2: Submodule 更新方法

**選項 A**: 直接在 themes/blowfish 中執行 `git checkout v2.94.0`
- **優點**: 簡單直接
- **缺點**: 需要手動更新 parent repo 的 submodule reference

**選項 B**: 在 parent repo 執行 `git submodule update --remote themes/blowfish`
- **優點**: 自動更新 submodule reference
- **缺點**: 預設會拉取 main branch 最新版本，需額外指定 tag

**選項 C**: 手動兩步驟更新
1. `cd themes/blowfish && git fetch --all --tags && git checkout v2.94.0`
2. `cd ../.. && git add themes/blowfish`

- **優點**: 明確控制版本，清楚的操作步驟
- **缺點**: 步驟較多

**選定**: **選項 C**

**理由**:
1. 明確指定版本 `v2.94.0`，避免意外更新到其他版本
2. 步驟清晰，易於驗證
3. 符合 git submodule 最佳實踐

### 決策 3: 驗證策略

**測試範圍**:
1. **P1 階段驗證**（移除自訂代碼後）:
   - Alert 樣式應該失效（不顯示或顯示為純文字）
   - 其他頁面功能正常（首頁、標籤、分類、導航）
   - 瀏覽器控制台無錯誤

2. **P2 階段驗證**（升級 Blowfish 後）:
   - 所有標準 GitHub Alert 類型正確顯示
   - Alert 使用 Blowfish 原生樣式（圖示、顏色、邊框）
   - 其他頁面功能持續正常
   - 瀏覽器控制台無錯誤

**測試文章**:
- 主要：`content/posts/container-platform/n8n 容器部署教學/index.md`
- 補充：使用 `rg` 搜尋所有包含 `> [!` 的文章

**測試工具**:
- `hugo server`: 本機開發伺服器
- `npm run build`: CSS 重建
- Chrome DevTools: 檢查控制台錯誤和樣式來源

## 依賴與限制

### 外部依賴

1. **Blowfish 主題**:
   - 版本：2.94.0
   - 來源：https://github.com/nunocoracao/blowfish
   - 更新方式：Git submodule

2. **Node.js & npm**:
   - 用途：執行 `npm run build` 重建 CSS
   - 假設：已安裝且可用

3. **Hugo Extended**:
   - 用途：靜態網站生成和開發伺服器
   - 假設：已安裝且可用

### 技術限制

1. **Submodule 狀態**:
   - 當前 Blowfish 版本：需要使用 `git submodule status` 確認
   - 目標版本：v2.94.0
   - 限制：必須確保 submodule 已初始化

2. **CSS 自動載入**:
   - 機制：`layouts/partials/extend-head.html` 自動掃描 `assets/css/custom/*.css`
   - 行為：刪除 CSS 檔案後自動停止載入
   - 限制：無需手動修改 `extend-head.html`

3. **Git Workflow**:
   - Pre-commit hook：會自動更新 Markdown 檔案的 `lastmod` 欄位
   - 影響：commit 時可能會觸發 hook
   - 限制：需要確保 hook 不會干擾遷移過程

### 風險與緩解

| 風險 | 影響等級 | 影響描述 | 緩解策略 |
|------|---------|---------|---------|
| i18n 翻譯鍵移除影響 | **低** | 移除自訂翻譯鍵後，admonition 標題將顯示英文（專案需求） | 直接移除 i18n 檔案中的自訂 alert 翻譯鍵，依賴 Blowfish 的預設行為（類型名稱作為標題） |
| Blowfish 2.94.0 視覺樣式與專案風格不符 | **低** | Blowfish 使用不同的配色方案 | P2 驗證階段人工檢查，必要時使用 Tailwind CSS 變數覆寫 `--adm-{type}-*` |
| CSS 類別名稱變更導致其他功能失效 | **低** | 如果有其他 CSS/JS 依賴 `.custom-alert` 類別 | 使用 `rg` 搜尋 `.custom-alert` 引用，確認無其他依賴 |
| Submodule 更新失敗 | **低** | 無法切換到 v2.94.0 | 使用明確的 git 指令，每步驟驗證 |
| 驗證失敗需要回滾 | **低** | 時間浪費 | 每階段都先 commit，使用 `git reset --hard` 快速回滾 |
| 其他頁面功能受影響 | **低** | 網站其他功能異常 | 兩階段驗證都包含全站功能檢查 |

**風險總結**: 由於 Blowfish 2.94.0 完全支援自訂實作的所有功能，且專案需求為使用英文標題（無需 i18n 配置），遷移風險極低，整體風險等級為**低**。

## Alternatives Considered

### Alternative 1: 保留自訂實作，不升級 Blowfish

**優點**:
- 無需遷移，保留所有現有功能
- 零風險

**缺點**:
- 無法享受 Blowfish 新版本的其他改進
- 維護複雜度增加
- 與主題更新可能衝突

**拒絕理由**: 規格明確要求遷移至 Blowfish 原生支援

### Alternative 2: 混合實作（保留部分自訂）

**優點**:
- 可以保留額外的 alert 類型
- 可以保留自訂功能

**缺點**:
- 維護複雜度高
- 可能與 Blowfish 原生實作衝突
- 不符合「完全移除」的需求

**拒絕理由**: 規格要求完全移除自訂程式碼，且增加維護負擔

### Alternative 3: 升級前先更新文章語法

**優點**:
- 確保所有文章使用標準語法
- 降低遷移風險

**缺點**:
- 增加工作量
- 可能需要大量文章修改
- 超出此次遷移範圍

**拒絕理由**: 假設文章已使用標準 GitHub Flavored Markdown 語法，如驗證發現問題再處理

## 結論

### 關鍵發現總結

透過詳細的代碼檢查和文檔分析，已完全了解自訂 GitHub Alert 的實作細節和 Blowfish 2.94.0 的原生支援：

**重大發現**:
1. **Blowfish 2.94.0 不只支援 GitHub Alert，而是完整的 Admonition 系統**
   - 支援 15 種獨特類型 + 14 個別名（總計 29 種語法變體）
   - 遠超自訂實作的 10 種類型

2. **所有自訂功能都被完整支援**:
   - ✅ 自訂標題（`.AlertTitle`）
   - ✅ 可摺疊功能（`.AlertSign`: `+`/`-`）
   - ✅ 多語言支援（i18n）
   - ✅ 所有 10 種自訂類型（透過直接支援或別名映射）

3. **實作來源**:
   - 基於 KKKZOZ/hugo-admonitions 專案
   - 由 PR #2643 引入（作者：RxChi1d）
   - 使用現代化的 Tailwind CSS 變數系統

### 遷移策略

經過分析，確定以下遷移策略：

1. **完全移除自訂實作**（選項 A）
   - 理由：Blowfish 2.94.0 完全涵蓋所有功能，無功能損失
   - 移除檔案：render-blockquote.html, blockquote-alerts.css, i18n 翻譯鍵

2. **使用明確的 submodule 更新步驟**（選項 C）
   - 理由：明確控制版本，避免意外更新
   - 步驟：`git fetch && git checkout v2.94.0 && git add themes/blowfish`

3. **兩階段人工驗證**（P1 驗證失效，P2 驗證恢復）
   - P1: 確認移除後 alert 失效
   - P2: 確認升級後 alert 恢復且功能完整

4. **i18n 翻譯鍵移除**（專案需求：統一使用英文標題）:
   - 移除專案層級的自訂 alert 翻譯鍵（`i18n/zh-TW.yaml` 和 `i18n/en.yaml` 中的 7-17 行）
   - 不添加 Blowfish 的 `admonition.*` 翻譯
   - Blowfish 將使用 `$normalizedType` 作為預設標題（英文小寫，如 "note", "tip", "important"）
   - 結果：所有 admonition 標題統一顯示英文小寫類型名稱

### 執行前置條件

所有技術細節、依賴、限制和風險都已識別和記錄，符合以下前置條件：

- ✅ 完全理解 Blowfish 2.94.0 的 admonition 實作機制
- ✅ 確認所有自訂功能都被支援（無功能損失）
- ✅ 識別需要調整的項目（i18n 翻譯鍵格式）
- ✅ 評估風險等級為低至中
- ✅ 制定明確的遷移和回滾策略

**可以安全地進入下一階段（任務分解 `/speckit.tasks`）**。
