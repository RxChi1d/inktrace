# Inktrace Blog

使用 [Hugo](https://gohugo.io/) 框架和 [Blowfish](https://github.com/nunocoracao/blowfish) 主題建立的個人部落格。

## 環境需求

- [Git](https://git-scm.com/)
- [Hugo Extended](https://gohugo.io/installation/) (v0.87.0 或更新版本)

## 快速開始

### 1. 複製儲存庫

```bash
git clone git@github.com:RxChi1d/inktrace.git
cd inktrace
```

### 2. 執行設定腳本

**重要**：複製專案後，必須執行設定腳本以配置 Git hooks 和初始化 submodules：

```bash
./setup.sh
```

此腳本會自動：
- 配置 Git hooks，自動更新 Markdown 檔案的 `lastmod` 欄位
- 初始化 Blowfish 主題 submodule

### 3. 啟動開發伺服器

```bash
hugo server
```

造訪 [http://localhost:1313](http://localhost:1313) 即可瀏覽你的部落格。

## 專案結構

```
.
├── archetypes/          # 內容模板
├── assets/css/custom/   # 自訂 CSS 檔案（自動載入）
├── config/_default/     # Hugo 配置
├── content/             # 部落格文章與頁面
├── layouts/             # 自訂版面覆寫
├── script/git-hooks/    # Git hooks（pre-commit）
├── static/              # 靜態資源
└── themes/blowfish/     # Blowfish 主題（submodule）
```

## 自訂 CSS 組織規範

本專案使用模組化的方式管理自訂 CSS。所有位於 `assets/css/custom/` 的 `.css` 檔案都會透過 `layouts/partials/extend-head.html` 自動載入。

### 新增自訂樣式

1. 在 `assets/css/custom/` 目錄下建立新的 `.css` 檔案
2. 使用 `kebab-case` 命名（例如：`homepage-custom.css`）
3. 無需額外配置，檔案將自動被載入

**重要**：絕不修改 `themes/blowfish/` 下的任何檔案。所有自訂內容必須放在專案根目錄下。

## Git Pre-Commit Hook

Pre-commit hook 會自動：
- 更新已修改的 Markdown 檔案的 `lastmod` 欄位
- 為 `date` 與今日不同的檔案新增 `lastmod` 欄位
- 使用台北時區（Asia/Taipei）

位置：[script/git-hooks/pre-commit](script/git-hooks/pre-commit)

## 貢獻

這是個人部落格，但如果你發現問題或有建議，歡迎開 issue。

## 授權

內容版權 © RxChi1d。Blowfish 主題採用 MIT 授權。
