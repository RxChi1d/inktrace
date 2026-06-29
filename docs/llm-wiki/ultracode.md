# Ultracode — Claude Code 動態編排模式

> **來源**：[code.claude.com/docs/en/workflows](https://code.claude.com/docs/en/workflows) + [Anthropic Blog](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code)
> **整理日期**：2026-06-29

---

## 一句話總結

**Ultracode = `xhigh` reasoning effort + 自動 dynamic workflow 編排**。Claude Code 會自己寫 JavaScript 協調腳本，跑數十到數百個 subagent 並行處理你的任務。

---

## 核心架構

```
┌─────────────────────────────────────────────┐
│ 對話層（Claude 跟你聊天）                      │
└──────────────────┬──────────────────────────┘
                   │ 任務描述
                   ▼
┌─────────────────────────────────────────────┐
│ Workflow Runtime（JS 腳本執行環境）            │
│  - 每小時 subagent 有獨立 context window       │
│  - 中間結果存在 script variables             │
│  - 可中斷、恢復、重跑                          │
└──────────────────┬──────────────────────────┘
                   │ 分發
          ┌────────┼────────┐
          ▼        ▼        ▼
       Agent A  Agent B  Agent C ... (dozens to hundreds)
```

### 關鍵特性

| 特性 | 說明 |
|------|------|
| **Scale** | 數十到數百個 subagent/run |
| **隔離** | 每個 subagent 有獨立 context，不互相污染 |
| **可恢復** | 中斷後從斷點繼續，不用從頭來 |
| **可重跑** | 儲存為 `.claude/workflows/` 或 `~/.claude/workflows/` |
| **模型路由** | 每個 subagent 可用不同模型（Sonnet/Opus） |
| **Worktree 隔離** | 每個 subagent 可跑在獨立 worktree |

---

## 兩種觸發方式

### 1. 關鍵字觸發（單任務）
在 prompt 中寫 `ultracode`：
```
ultracode: audit every API endpoint under src/routes/ for missing auth checks
```
- 只把**這個任務**變成 workflow
- 不影響 session 其他操作
- 可用自然語言：「use a workflow」、「run a workflow」也一樣

### 2. Effort 設定觸發（session 級別）
```
/effort ultracode
```
- **每個**實質性任務都會自動觸發 workflow
- 一個 request 可能產生多個 workflow（理解 → 修改 → 驗證）
- 當前 session 有效，新 session 重置
- 用 `/effort high` 退回普通模式

---

## 與替代方案比較

| | Subagents | Skills | Agent Teams | **Workflows** |
|---|---|---|---|---|
| **決策者** | Claude（逐 turn） | Claude（跟 prompt） | Lead agent | **腳本** |
| **中間結果** | Claude context | Claude context | Shared task list | **Script variables** |
| **可重現** | Worker 定義 | Instructions | Team 定義 | **編排腳本本身** |
| **規模** | 少量/turn | 同 subagents | 少數 | **數十到數百** |
| **中斷** | 重啟 turn | 重啟 turn | 持續跑 | **可恢復** |

---

## 六大編排模式

### 1. Fan-out-and-synthesize（展開-合成）
最常用。拆分任務 → 各 agent 並行處理 → 合成 agent 合併結果。
- 適合：程式碼遷移、文檔生成、批量分析

### 2. Adversarial verification（對抗驗證）
一個 agent 產出，另一個 agent 驗證/反駁。
- 適合：研究報告、安全審計、程式碼審查

### 3. Generate-and-filter（生成-過濾）
生成多個方案 → 用 rubric 過濾 → 去重 → 返回最優。
- 適合：命名、設計方案、測試案例生成

### 4. Tournament（錦標賽）
N 個 agent 用不同方法解同一任務 → 兩兩比較 → 選出贏家。
- 適合：排序 1000+ 項目（比較判斷 > 絕對評分）。

### 5. Classify-and-act（分類-行動）
分類 agent 判斷任務類型 → 路由到對應 agent。
- 適合：bug 分類、PR 路由、問題分診。

### 6. Loop until done（循環直到完成）
持續 spawn agents 直到停止條件（無新發現、無更多錯誤）。
- 適合：fuzzing、根因調查、漸進式修復。

---

## 什麼時候該用 Workflow

| 場景 | 原因 |
|------|------|
| 500 個檔案的 migration | 一個 context 處理不完 |
| 程式碼全面安全審計 | 需要多角度交叉檢查 |
| 研究報告 + 來源驗證 | 需要 adversarial 驗證 |
| 多個方案比較 | 需要 unbiased 評估 |
| 長時間運行的任務（小時-天） | 需要可恢復性 |
| 需要高品質、可信賴的結果 | 單 pass 容易遺漏 |

**不適合**：簡單問題、< 5 分鐘的任務、只需要一個 tool call 的事。

---

## 使用技巧

### Prompting 技巧
- 明確指定模式：「用 fan-out-and-synthesize 模式做...」
- 小任務也可以：「quick workflow for adversarial review」
- 描述停止條件：「don't stop until one theory survives the evidence」

### 組合技
- **`/loop`**：持續跑 workflow（triage、research、verification）
- **`/goal`**：設定硬性完成條件
- **Worktree 隔離**：每個 subagent 在獨立 worktree 工作，避免互相干擾
- **模型路由**：簡單 subagent 用 Sonnet（快），複雜的用 Opus（準）

### 成本控制
- Ultracode 比普通 session 消耗**顯著更多** token
- 第一次觸發會顯示預覽 → 才批准
- 可用 `/config` → Ultracode keyword trigger 關閉關鍵字觸發（避免意外啟動）

### 監控
- `/workflows`：列出所有 running/completed workflows
- 方向鍵選擇 phase → Enter drill into agent
- `p` pause / `x` stop / `r` restart

---

## 與我們工作流的關聯

在 inktrace 部落格維護中，適合用 ultracode 的場景：

| 任務 | 推薦模式 |
|------|---------|
| Blowfish 主題升級（多檔案修改 + 驗證） | Fan-out + Adversarial verification |
| 全站連結檢查 | Fan-out（每 agent 負責一個 section） |
| 性能優化分析 | Classify + Fan-out |
| 重構 hugo 配置 | Fan-out + Verify |

### 我們的標準指令格式（每次新任務用）

```
透過 claude code，
model: opus
effort: ultracode
mode: auto（不要直接用 YOLO，太危險了）
```

注意：effort 設為 ultracode 時，prompt 不需要再寫「ultracode」關鍵字（已自動觸發）。
