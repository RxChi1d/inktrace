# Design: Native Card Restoration

## Architectural Pattern: Stretched Link vs Nested Anchor

### Current (Problematic) Pattern: Nested Anchor
目前的實作採用「大連結包小元素」模式：
```html
<a href="article-url" class="card">
  ...
  <span onclick="goto(tag-url)">Tag</span>
  ...
</a>
```
- **缺點**：HTML 語法限制導致內部不能放真正的 `<a>`，必須用 JS 模擬，破壞語意與可及性。

### Target Pattern: Stretched Link (Blowfish Native)
目標是採用 Bootstrap/Tailwind 常見的 Stretched Link 模式：
```html
<div class="card relative">
  ...
  <!-- Title Link expands to cover the whole card -->
  <a href="article-url" class="before:absolute before:inset-0">Title</a>
  ...
  <!-- Taxonomy Link sits on top (via z-index or natural stacking) -->
  <a href="tag-url" class="relative z-10">Tag</a>
  ...
</div>
```
- **優點**：HTML 結構合法，語意清晰，SEO 友善，且無需維護 JS 跳轉邏輯。

## Implementation Details

### Layout Changes
1.  **`layouts/partials/article-link/simple.html`**:
    -   **Action**: DELETE (Remove file).
    -   **Result**: Revert to theme default. Uses native stretched link structure and `<img>` tags.

2.  **`layouts/partials/article-meta/basic.html`**:
    -   **Action**: DELETE (Remove file).
    -   **Result**: Revert to theme default. Uses standard `<a>` tags for taxonomies.

### Configuration Changes
-   **`config/_default/params.toml`**:
    -   刪除 `showCategories`。
    -   刪除 `showTags`。