# Claude Code Auto Mode — 完整指南

> **來源**：[code.claude.com/docs/zh-TW/permission-modes](https://code.claude.com/docs/zh-TW/permission-modes)
> **建立日期**：2026-06-29

---

## 什麼是 Auto Mode

Auto mode 讓 Claude Code 執行例行操作時**不再頻繁彈出權限提示**，由獨立的背景分類器模型審查每個操作。

**不是 YOLO** — `bypassPermissions`（也就是 `--dangerously-skip-permissions`）才是跳過所有安全檢查的危險模式。Auto mode 仍有安全防護。

---

## 模式比較

| 模式 | 自動批准 | 最適合 |
|------|---------|--------|
| `default` | 僅讀取 | 入門、敏感工作 |
| `acceptEdits` | 讀取 + 檔案編輯 + 常見 fs 命令 | 迭代你正在 review 的程式碼 |
| `plan` | 僅讀取 | 變更前探索 |
| **`auto`** | **所有操作，背景分類器審查** | **長時間任務、減少提示疲勞** |
| `dontAsk` | 僅預先批准的工具 | CI / script |
| `bypassPermissions` | 所有操作（無檢查） | ⚠️ 隔離容器/VM 專用 |

---

## Auto Mode 重點

### 預設允許的操作
- 工作目錄中的本地檔案操作
- 安裝 lockfile 中宣告的依賴項
- 讀取 `.env` 並發送到匹配的 API
- 唯讀 HTTP 請求
- 推送到**啟動的分支**或 **Claude 建立的分支**

### 預設被分類器阻止的操作
- `curl | bash`（下載執行程式碼）
- 發送敏感資料到外部端點
- 生產部署和遷移
- 雲端儲存大量刪除
- 授予 IAM 或 repo 權限
- **強制推送**或**直接推送到 main**
- `git reset --hard`、`git checkout -- .`（丟棄未提交變更）
- `git commit --amend`（當 HEAD 不是此 session 建立）
- `terraform destroy`、`pulumi destroy`
- 對**受保護路徑**的寫入（`.git/`, `.claude/`, `.vscode/`, `.bashrc` 等）

### 回退機制
- 連續 3 次 or 總共 20 次被阻止 → auto mode **暫停**
- 手動批准操作的提示會恢復 auto mode
- 非互動模式（`-p`）中重複阻止會**中止 session**

### 分類器決策順序
1. 比對 allow/deny 規則 → 立即決定
2. 唯讀 + 工作目錄內檔案編輯 → 自動批准
3. 其他 → 送分類器
4. 被阻止 → Claude 收到原因並嘗試替代方法

---

## 啟動方式

### CLI 啟動時指定（推薦）
```bash
claude --permission-mode auto
```

### Print mode + auto（one-shot 任務最適合）
```bash
claude --permission-mode auto -p "task description" \
       --max-turns 15 \
       --allowedTools Bash,Read,Write \
       --model opus
```

### 會話中切換
按 `Shift+Tab` 循環：`default` → `acceptEdits` → `plan`

### 持久預設值
`~/.claude/settings.json`:
```json
{
  "permissions": {
    "defaultMode": "acceptEdits"
  }
}
```

### VS Code
設定 `claudeCode.initialPermissionMode`

---

## 與 Ultracode 搭配

Ultracode = `xhigh` reasoning + dynamic workflow 編排。
Ultracode 會 spawn 多個 subagent，每個 subagent 的操作**都會通過分類器**。

**啟動指令（auto mode + ultracode + opus）**：
```bash
claude --model opus --permission-mode auto
# 然後在 session 中：
# /effort ultracode
# 輸入你的任務描述
```

**為什麼不要用 YOLO（`--dangerously-skip-permissions`）**：
- 分類器會阻止危險操作（對 main 強制 push、`terraform destroy`）
- 受保護路徑寫入仍然會提示
- 子 agent 的操作仍受約束

---

## 實戰經驗（2026-06-29）

### 任務
在 `~/github-repositories/inktrace` 中建立 feature branch 並更新 Blowfish submodule。

### 指令
```bash
claude --model opus --permission-mode auto -p "
git checkout -b feat/upgrade-blowfish-v2.103.0
cd themes/blowfish && git fetch --tags && git checkout v2.103.0
" --max-turns 15 --allowedTools Bash,Read,Write
```

### 結果
- ✅ `git checkout -b`：自動批准
- ✅ `git fetch --tags`：自動批准
- ✅ `git checkout v2.103.0`：自動批准
- ✅ 沒有任何權限提示彈出
- ✅ 分類器未觸發阻擋

### 結論
Auto mode 對於**本地 git 操作 + 檔案編輯**的任務非常順暢，不需要跳過所有安全檢查。

---

## 什麼時候用哪種模式？

| 情境 | 推薦模式 |
|------|---------|
| 本地 git 操作、branch 建立 | `auto` |
| 撰寫/編輯程式碼 | `auto` 或 `acceptEdits` |
| 大規模重構（ultracode） | `auto` |
| 只讀取、探索 | `plan` |
| 需要推送到 main / 危險操作 | `default`（每個都會詢問） |
| 在隔離容器/VM 中 | `bypassPermissions` |
| 第一次操作不確定 | `default` |

---

## 受保護路徑（所有模式下寫入都會提示，bypassPermissions 除外）

- `.git/`, `.config/git/`
- `.vscode/`, `.idea/`
- `.claude/`（除了 `.claude/worktrees/`）
- `.husky/`, `.cargo/`, `.devcontainer/`
- `.bashrc`, `.zshrc`, `.profile`
- `.npmrc`, `.yarnrc`, `bunfig.toml`
- `.gitconfig`, `.gitmodules`
- `.mcp.json`, `.claude.json`

---

## 參考

- 官方文件：https://code.claude.com/docs/zh-TW/permission-modes
- Auto mode 配置：https://code.claude.com/auto-mode-config
- Ultracode 文件：https://code.claude.com/docs/en/workflows
