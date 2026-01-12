# Tasks: 遷移 Video Shortcode

- [x] 遷移 NSF.md 內容 <!-- id: migrate-content-nsf -->
  - 修改 `content/posts/paper-survey/NSF.md`
  - 將帶有 `class="grid-w50"` 的 `video` shortcode 改為 `<div class="grid-w50">...</div>` 包裹
- [x] 移除自訂 video shortcode 模板 <!-- id: remove-template -->
  - `rm layouts/shortcodes/video.html`
- [x] 移除自訂 video shortcode 樣式 <!-- id: remove-css -->
  - `rm assets/css/custom/video-shortcode.css`
- [x] 驗證網站構建 <!-- id: verify-build -->
  - 執行 `hugo` 確保網站仍能成功構建且無嚴重錯誤
