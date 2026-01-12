# Spec: Card Layout Restoration

## ADDED Requirements

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
