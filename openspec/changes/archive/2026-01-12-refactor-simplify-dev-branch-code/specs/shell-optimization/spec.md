# Spec: Shell Script Optimization

## ADDED Requirements

### Requirement: 錯誤訊息 MUST 統一格式
**ID**: SH-001

Shell 腳本的錯誤和警告訊息 MUST 使用統一的格式和顏色編碼。

#### Scenario: 使用顏色區分訊息類型
- **WHEN** 執行腳本輸出訊息
- **THEN** 錯誤訊息應使用 RED 顏色
- **THEN** 警告訊息應使用 YELLOW 顏色
- **THEN** 成功訊息應使用 GREEN 顏色
- **THEN** 所有訊息應包含明確的前綴符號（✓, ✗, ⚠, ↻）

#### Scenario: 錯誤訊息提供解決方案
- **WHEN** 腳本遇到錯誤情況並輸出錯誤訊息
- **THEN** 應說明問題原因
- **THEN** 應提供解決方法或下一步操作建議
**Example**:
```
Error: yq is required but not installed.
Please install yq: brew install yq
```

---

### Requirement: 重複邏輯 MUST 抽取為函數
**ID**: SH-002

相同或相似的邏輯重複超過 2 次時，MUST 抽取為獨立函數。

#### Scenario: generate-taxonomy-index.sh 抽取翻譯驗證函數
- **WHEN** 實作 zh-TW 和 en 的翻譯驗證邏輯
- **THEN** 應有單一函數 `validate_translation`
- **THEN** 函數應接受參數：`lang`, `value`, `term`, `taxonomy`
- **THEN** 兩種語言應呼叫同一函數

#### Scenario: validate-taxonomy-terms.sh 抽取 term 驗證邏輯
- **WHEN** 實作 categories 和 tags 的驗證邏輯
- **THEN** 應有單一函數處理 term 驗證
- **THEN** categories 和 tags 應呼叫同一函數

---

### Requirement: 函數 SHALL 使用清晰的返回碼
**ID**: SH-003

Shell 函數 SHALL 使用明確的返回碼表示不同的結果狀態。

#### Scenario: term_exists 函數使用語意化返回碼
- **WHEN** 執行 `term_exists` 檢查 term 是否存在於 SSOT
- **THEN** 返回 0 表示兩種翻譯都存在
- **THEN** 返回 1 表示缺少 zh-TW 翻譯
- **THEN** 返回 2 表示缺少 en 翻譯
- **THEN** 呼叫方應能根據返回碼輸出對應的錯誤訊息

#### Scenario: 函數返回碼應有文檔說明
- **WHEN** 查看 Shell 函數註解
- **THEN** 應說明各個返回碼的含義
**Example**:
```bash
# Returns:
#   0 - Both translations exist
#   1 - Missing zh-TW translation
#   2 - Missing en translation
term_exists() { ... }
```

---

### Requirement: 條件判斷 SHALL 簡化
**ID**: SH-004

Shell 腳本中的條件判斷 SHALL 盡可能簡化，避免深層巢狀。

#### Scenario: 使用 early return 替代深層巢狀
- **WHEN** 函數需要進行多個條件檢查並實作邏輯
- **THEN** 應優先處理錯誤情況並 early return
- **THEN** 避免 if-else 巢狀超過 2 層

**Example**:
```bash
# Bad (nested)
if [ -f "$file" ]; then
    if [ -r "$file" ]; then
        if [ -n "$content" ]; then
            process "$content"
        fi
    fi
fi

# Good (early return)
[ ! -f "$file" ] && return 1
[ ! -r "$file" ] && return 2
[ -z "$content" ] && return 3
process "$content"
```

#### Scenario: validate-taxonomy-terms.sh 簡化 front matter 解析狀態追蹤
- **WHEN** 實作 YAML front matter 解析邏輯
- **THEN** 應簡化狀態追蹤變數（如 `categories="open"/"closed"`）
- **THEN** 可考慮使用更清晰的布林變數（如 `in_categories=true/false`）

---

### Requirement: 變數命名 SHALL 清晰且一致
**ID**: SH-005

Shell 腳本中的變數命名 SHALL 使用小寫加底線格式，並清楚表達用途。

#### Scenario: 使用描述性變數名
- **WHEN** 命名翻譯內容相關變數
- **THEN** 應使用 `title_zh` 或 `title_zh_tw` 而非 `t1`
- **THEN** 應使用 `taxonomy_type` 而非 `type`

#### Scenario: 常數使用全大寫
- **WHEN** 定義腳本中的常數（如目錄路徑、顏色碼）
- **THEN** 應使用全大寫命名
**Example**: `DATA_DIR`, `REPO_ROOT`, `RED`, `GREEN`

---

### Requirement: Front matter 解析 MUST 健壯
**ID**: SH-006

Front matter 解析 MUST 正確處理各種 YAML 格式，包括 inline array 和 block array。

#### Scenario: 正確解析 inline array 格式
- **WHEN** Front matter 包含 `categories: [engineering, paper-survey]` 且執行解析
- **THEN** 應正確提取 `engineering` 和 `paper-survey`

#### Scenario: 正確解析 block array 格式
- **WHEN** Front matter 包含以下內容且執行解析：
```yaml
categories:
  - engineering
  - paper-survey
```
- **THEN** 應正確提取 `engineering` 和 `paper-survey`

#### Scenario: 正確處理空值情況
- **WHEN** Front matter 包含 `categories: []` 或未定義 categories 且執行解析
- **THEN** 不應產生錯誤
- **THEN** 應跳過該欄位的驗證

---

## REMOVED Requirements

無移除的需求。

---

## Related Specs
- `taxonomy-i18n`: Taxonomy 翻譯管理
- `code-quality`: 程式碼品質標準
