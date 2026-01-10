# Spec Delta: card-layout

## ADDED Requirements

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
