# card-layout Specification

## Purpose
TBD - created by archiving change restore-native-cards. Update Purpose after archive.
## Requirements
### Requirement: Article Card Link Structure
The article card MUST use a Stretched Link pattern instead of a wrapper Anchor tag to make the entire card clickable.

#### Scenario: Clicking the card background
-   **Given** a user is on a list page (e.g., Homepage, Posts).
-   **When** the user clicks on the whitespace or background of an article card.
-   **Then** the browser navigates to the article detail page.

#### Scenario: HTML Validity
-   **Given** the rendered HTML of a list page.
-   **When** inspected.
-   **Then** the article card `div` or `article` tag MUST NOT be enclosed in an `<a>` tag.
-   **And** the article title `<a>` tag MUST contain classes (e.g., `before:inset-0`) that expand its click area.

### Requirement: Card Visual Enhancement
Article cards MUST provide visual enhancements including glassmorphism background, shadows, and hover effects to improve user experience while maintaining Blowfish native HTML structure.

#### Scenario: Glassmorphism background in light mode
- **GIVEN** a user views an article list page in light mode
- **WHEN** article cards are rendered
- **THEN** each card MUST display a semi-transparent white background (`rgba(255, 255, 255, 0.65)`)
- **AND** a backdrop blur effect MUST be applied (`backdrop-filter: blur(10px)`)
- **AND** Safari compatibility MUST be ensured via `-webkit-backdrop-filter` prefix

#### Scenario: Glassmorphism background in dark mode
- **GIVEN** a user views an article list page in dark mode
- **WHEN** article cards are rendered
- **THEN** each card MUST display a semi-transparent dark background (`rgba(26, 32, 44, 0.7)`)
- **AND** a backdrop blur effect MUST be applied

#### Scenario: Shadow system in default state
- **GIVEN** a card is rendered without hover interaction
- **WHEN** inspected
- **THEN** the card MUST have a subtle shadow (`box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05)` in light mode)
- **AND** a more prominent shadow in dark mode (`box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2)`)

#### Scenario: Border color in default state
- **GIVEN** a card is rendered without hover interaction
- **WHEN** inspected
- **THEN** the border color MUST match the original design (`rgba(0, 0, 0, 0.1)` in light mode)
- **AND** the border color MUST match the original design in dark mode (`rgba(255, 255, 255, 0.15)`)

#### Scenario: Shadow enhancement on hover
- **GIVEN** a user hovers over a card
- **WHEN** the hover state is active
- **THEN** the shadow MUST increase in intensity (`box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1)` in light mode)
- **AND** the transition MUST be smooth (300ms ease)

#### Scenario: Background color change on hover in light mode
- **GIVEN** a user hovers over a card in light mode
- **WHEN** the hover state is active
- **THEN** the card background MUST be overridden to `rgba(0, 0, 0, 0.03)`
- **AND** the hover feedback MUST match the original link-hover cover color
- **AND** the border color MUST change to `rgba(0, 0, 0, 0.15)`
- **AND** the transition MUST be smooth (300ms ease)

#### Scenario: Background color change on hover in dark mode
- **GIVEN** a user hovers over a card in dark mode
- **WHEN** the hover state is active
- **THEN** the card background MUST be overridden to `rgba(255, 255, 255, 0.04)`
- **AND** the hover feedback MUST match the original link-hover cover color
- **AND** the border color MUST change to `rgba(255, 255, 255, 0.25)`
- **AND** the transition MUST be smooth (300ms ease)

#### Scenario: Hover background override without overlay layer
- **GIVEN** a user hovers over a card
- **WHEN** the hover state is active
- **THEN** the hover background MUST be applied directly on the card element (no `::before` overlay layer)
- **AND** the implementation MUST NOT rely on an `<a>` wrapper

#### Scenario: CSS selector targeting
- **GIVEN** the Blowfish native card structure with classes `overflow-hidden rounded-lg border`
- **WHEN** custom styles are applied
- **THEN** the CSS selector `article.overflow-hidden.rounded-lg.border` MUST be used
- **AND** the selector MUST NOT affect non-card article elements
- **AND** no custom classes or data attributes MUST be added to the HTML

#### Scenario: Color fidelity to original design
- **GIVEN** custom card styles are implemented
- **WHEN** color values are defined
- **THEN** original RGBA color values MUST be used for background and hover states to match the prior design
- **AND** any deviations MUST be documented in `style-differences.md`

### Requirement: Style Difference Documentation
All deviations from the original custom styling MUST be documented to enable informed decision-making for future adjustments.

#### Scenario: Documenting preserved differences
- **GIVEN** the restoration process accepts Blowfish native specifications for certain attributes
- **WHEN** documenting style differences
- **THEN** a `style-differences.md` file MUST be created under `openspec/changes/restore-card-styling/`
- **AND** it MUST include a comparison table of original vs. current specifications
- **AND** it MUST explain the technical rationale for preserving differences (maintainability, Tailwind specificity conflicts)

#### Scenario: Documenting fully restored effects
- **GIVEN** certain visual effects are fully restored
- **WHEN** documenting style differences
- **THEN** the file MUST list all fully restored effects (glassmorphism, shadows, hover transitions)
- **AND** it MUST confirm their implementation matches the original specification

#### Scenario: Documenting non-restorable aspects
- **GIVEN** certain visual aspects cannot be restored without HTML modifications
- **WHEN** documenting style differences
- **THEN** the file MUST clearly identify these aspects (e.g., if `article-card-hover` class hook is unavailable)
- **AND** it MUST explain the technical constraints preventing restoration

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

