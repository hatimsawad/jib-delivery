# JIB localization standard

## Supported languages

All JIB surfaces use the same three supported languages:
- Arabic (`ar`) — right-to-left.
- French (`fr`) — left-to-right.
- English (`en`) — left-to-right.

The three language names must remain visible together in the language area; do not hide the other choices inside a dropdown. The current language may be highlighted, while the other two remain visible.

## Product-wide scope

Apply the same language standard to:
- JIB customer app.
- JIB merchant app.
- JIB courier app.
- Standalone JIB Manager web console.

## Implementation rules

1. Keep all user-facing strings in translation resources; do not scatter translated literals through widgets or pages.
2. Use a shared language-code convention (`ar`, `fr`, `en`) across Flutter and Next.js.
3. Persist the user's selected language and restore it on next launch; default to Arabic for a new account in Morocco.
4. Switch layout direction with the language: RTL for Arabic and LTR for French and English.
5. Format dates and times using `Africa/Casablanca`, and currency as MAD / الدرهم المغربي.
6. Translate validation, loading, empty, error, confirmation, notification, accessibility and transactional status messages—not only navigation labels.
7. Never translate database enum values, API keys, or status identifiers; translate them only at the presentation layer.
8. Keep product/store names and customer-entered text unchanged unless a separate translation is explicitly available.

## Current implementation status

- JIB Manager now visibly presents العربية, Français and English together in its header.
- The complete interactive language switch and full translation coverage across all four apps remain implementation tasks; the visible language labels must not be mistaken for completed localization.
- CI and preview deployment must pass after each localization change.
