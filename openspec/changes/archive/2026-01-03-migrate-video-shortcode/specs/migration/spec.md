# Spec: 遷移 Video Shortcode

## ADDED Requirements

### Requirement: 遷移內容檔案
我們 **MUST** 更新現有的 Markdown 內容，以適應原生 video shortcode 不支援 `class` 參數的限制。

#### Scenario: NSF.md 樣式調整
- **Given** `content/posts/paper-survey/NSF.md` 包含帶有 `class="grid-w50"` 的 `video` shortcode
- **When** 執行遷移任務
- **Then** 這些 `video` shortcode 應被包裹在 `<div class="grid-w50">...</div>` 中
- **And** `video` shortcode 本身的 `class` 參數應被移除（或保留但被忽略）

### Requirement: 移除自訂 Video Shortcode
我們 **MUST** 移除專案層級的 video shortcode 實作與樣式，以恢復使用主題預設值。

#### Scenario: 刪除自訂實作檔案
- **Given** 專案根目錄下存在 `layouts/shortcodes/video.html`
- **And** 專案根目錄下存在 `assets/css/custom/video-shortcode.css`
- **When** 執行遷移任務
- **Then** `layouts/shortcodes/video.html` 應被刪除
- **And** `assets/css/custom/video-shortcode.css` 應被刪除
- **And** Hugo 應自動使用 `themes/blowfish/layouts/shortcodes/video.html` 作為 video shortcode 的實作
