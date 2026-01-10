## ADDED Requirements
### Requirement: Summary 行數限制
列表頁的文章摘要區塊 MUST 依卡片型態套用對應的 `line-clamp` 行數限制，避免摘要過長影響版面。

#### Scenario: Card 與 Related Card 摘要限制 5 行
- **Given** 使用 `article-link/card.html` 或 `article-link/card-related.html` 顯示文章卡片。
- **When** `showSummary` 為 true。
- **Then** 摘要區塊 MUST 包含 `line-clamp-5` class。
- **And** 摘要區塊 MUST 使用 `article-link__summary` class。

#### Scenario: Simple list 摘要限制 3 行
- **Given** 使用 `article-link/simple.html` 顯示文章列表。
- **When** `showSummary` 為 true。
- **Then** 摘要區塊 MUST 包含 `line-clamp-3` class。
- **And** 摘要區塊 MUST 使用 `article-link__summary` class。

#### Scenario: Shortcode summary 依 compactSummary 決定
- **Given** 使用 `article-link/_shortcode.html` 顯示文章列表。
- **When** `showSummary` 為 true 且 `compactSummary` 為 true。
- **Then** 摘要區塊 MUST 包含 `line-clamp-3` class。
- **And** 摘要區塊 MUST 使用 `article-link__summary` class。

#### Scenario: Shortcode summary 未啟用 compactSummary
- **Given** 使用 `article-link/_shortcode.html` 顯示文章列表。
- **When** `showSummary` 為 true 且 `compactSummary` 為 false。
- **Then** 摘要區塊 MUST NOT 包含 `line-clamp-3` class。
- **And** 摘要區塊 MUST 使用 `article-link__summary` class。
