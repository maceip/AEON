## 2025-02-24 - Icon-Only Buttons Missing ARIA Labels
**Learning:** Many icon-only buttons (like those in `WindowFrame.tsx`) rely solely on `title` attributes, which are insufficient for screen readers.
**Action:** When working on UI components, specifically check for icon-only buttons and add `aria-label` to ensure they have an accessible name.
