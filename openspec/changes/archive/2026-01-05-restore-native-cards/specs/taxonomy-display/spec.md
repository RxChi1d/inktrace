# Spec: Taxonomy Display Standardization

## ADDED Requirements

### Requirement: Custom Visibility Parameters Removal
The system SHALL NOT support `showCategories` and `showTags` configuration parameters.

#### Scenario: Configuration Cleanup
-   **Given** the `config/_default/params.toml` file.
-   **When** examined.
-   **Then** `showCategories` and `showTags` keys MUST be absent.

### Requirement: Taxonomy Badge Links
Taxonomy badges MUST be rendered as standard HTML Anchor tags (`<a>`).

#### Scenario: Badge Interactivity
-   **Given** a taxonomy badge on an article card.
-   **When** inspected.
-   **Then** it MUST be an `<a>` tag with an `href` attribute pointing to the taxonomy term page.
-   **And** it MUST NOT use `onclick` JavaScript handlers for navigation.

#### Scenario: Click Behavior
-   **Given** a taxonomy badge.
-   **When** clicked.
-   **Then** the browser navigates to the taxonomy term page.
-   **And** the click MUST NOT trigger the parent card's article link (z-index handling).
