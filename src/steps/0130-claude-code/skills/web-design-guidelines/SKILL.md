---
name: web-design-guidelines
description: UI code checked against web interface rules for accessibility, focus, forms, animation, typography, performance, theming, i18n, and copy. Use when asked to review UI or UX, check accessibility, or audit a site against best practices.
metadata:
  version: "2.0.0"
  argument-hint: <file-or-pattern>
  source: adapted from vercel-labs/web-interface-guidelines command.md, snapshot 2026-09-22
---

# Web interface guidelines

The rules for reviewing UI code, held in this one file.

## Reviewing

1. Read the target files, or ask the user which to review.
2. Apply every rule below to every line by hand.
3. Report each violation as `file:line - issue`, adding `→ fix` when the fix fits on the line, grouped under a `## file` heading, with a bare `✓ pass` for a clean file. Add an explanation only when the fix is non-obvious. Sacrifice grammar for brevity and skip the preamble.

Done when every rule has met every line.

```text
## src/Button.tsx

src/Button.tsx:42 - icon button missing aria-label
src/Button.tsx:67 - transition: all → list properties

## src/Modal.tsx

src/Modal.tsx:12 - missing overscroll-behavior: contain
src/Modal.tsx:34 - "..." → "…"

## src/Card.tsx

✓ pass
```

## Accessibility

- Icon-only buttons carry `aria-label`.
- Form controls carry a `<label>` or `aria-label`.
- Interactive elements respond to the keyboard (`onKeyDown`/`onKeyUp`).
- `<button>` for actions, `<a>`/`<Link>` for navigation; a `<div>` or `<span>` with a click handler is a violation.
- Images carry `alt`, or `alt=""` when decorative.
- Decorative icons carry `aria-hidden="true"`.
- Async updates (toasts, validation) sit in an `aria-live="polite"` region.
- Semantic HTML (`<button>`, `<a>`, `<label>`, `<table>`) before ARIA.
- Headings run in order from `<h1>` to `<h6>`; a skip link reaches the main content.
- Heading anchors set `scroll-margin-top`.
- Meaningful media has captions, transcripts, or descriptions as applicable.
- Media controls work from the keyboard; decorative media is hidden from assistive tech.
- Zoom stays enabled: `user-scalable=no` and `maximum-scale=1` are violations.

## Focus states

- Interactive elements show visible focus: `focus-visible:ring-*` or equivalent.
- `outline-none` / `outline: none` only alongside a focus replacement.
- `:focus-visible` over `:focus`, so a click draws no focus ring.
- Compound controls group focus with `:focus-within`.
- Sticky headers, footers, and overlays leave the focused element visible.

## Forms

- Inputs carry `autocomplete` and a meaningful `name`.
- The correct `type` (`email`, `tel`, `url`, `number`) and `inputmode`.
- Paste stays allowed: `onPaste` with `preventDefault` is a violation.
- Labels are clickable, through `htmlFor` or by wrapping the control.
- Emails, codes, and usernames disable spellcheck (`spellCheck={false}`).
- Checkbox and radio label and control share one hit target, with no dead zones.
- The submit button stays enabled until the request starts and shows a spinner during it.
- Errors sit inline next to their fields; submit focuses the first error.
- Placeholders end with `…` and show an example pattern.
- Non-auth fields set `autocomplete="off"` so password managers stay quiet.
- Navigating away with unsaved changes warns first (`beforeunload` or a router guard).

## Animation

- `prefers-reduced-motion` gets a reduced variant or no animation.
- Animate `transform` and `opacity` only, which the compositor handles.
- `transition` lists its properties explicitly; `transition: all` is a violation.
- `transform-origin` is set correctly.
- SVG transforms go on a `<g>` wrapper with `transform-box: fill-box; transform-origin: center`.
- Animations are interruptible and respond to user input mid-animation.
- Autoplay motion over 5s alongside other content has pause, stop, or hide controls.
- Muted decorative loops stop under `prefers-reduced-motion`.

## Typography

- `…` in place of `...`.
- Curly quotes `“ ”` in place of straight `"`.
- Non-breaking spaces in `10&nbsp;MB`, `⌘&nbsp;K`, and brand names.
- Loading states end with `…`: `"Loading…"`, `"Saving…"`.
- Number columns and comparisons use `font-variant-numeric: tabular-nums`.
- Headings use `text-wrap: balance` or `text-pretty` to prevent widows.

## Content handling

- Text containers handle long content: `truncate`, `line-clamp-*`, or `break-words`.
- Flex children set `min-w-0` so text can truncate.
- Empty strings and arrays render an empty state.
- User-generated content works at short, average, and very long lengths.

## Images

- `<img>` carries explicit `width` and `height` to prevent layout shift.
- Below-fold images use `loading="lazy"`.
- Above-fold critical images use `priority` or `fetchpriority="high"`.

## Performance

- Lists over 50 items are virtualized (`virtua`, `content-visibility: auto`).
- Render reads no layout (`getBoundingClientRect`, `offsetHeight`, `offsetWidth`, `scrollTop`).
- DOM reads and writes are batched: all reads, then all writes.
- Uncontrolled inputs preferred; a controlled input stays cheap per keystroke.
- CDN and asset domains get `<link rel="preconnect">`.
- Critical fonts use `<link rel="preload" as="font">` with `font-display: swap`.
- `<video autoplay muted loop playsinline>` with a still alternative in place of an animated GIF, wherever compressed video is suitable.
- Short non-essential loops use a Safari H.264 MP4 `<picture>` source, a `prefers-reduced-motion` media condition, and a still fallback.

## Navigation and state

- The URL reflects state: filters, tabs, pagination, and expanded panels live in query params.
- Navigation uses `<a>`/`<Link>` so Cmd/Ctrl+click and middle-click work.
- Stateful UI is deep-linkable; `useState` holding view state is a candidate for URL sync (nuqs or similar).
- Destructive actions get a confirmation modal or an undo window.

## Touch and interaction

- `touch-action: manipulation` removes the double-tap zoom delay.
- `-webkit-tap-highlight-color` is set intentionally.
- Modals, drawers, and sheets set `overscroll-behavior: contain`.
- During drag, text selection is disabled and dragged elements are `inert`.
- Drag, swipe, pinch, and path gestures have tap/click and keyboard alternatives unless the gesture is essential.
- `autoFocus` only on desktop, on a single primary input, with a clear reason.

## Safe areas and layout

- Full-bleed layouts use `env(safe-area-inset-*)` for notches.
- Content fits its container: fix the overflow at its source, or set `overflow-x-hidden` on the container to stop unwanted scrollbars.
- Flex and grid over JavaScript measurement for layout.

## Dark mode and theming

- Dark themes set `color-scheme: dark` on `<html>`, which fixes scrollbars and inputs.
- `<meta name="theme-color">` matches the page background.
- Native `<select>` sets explicit `background-color` and `color` for Windows dark mode.

## Locale and i18n

- Dates and times use `Intl.DateTimeFormat` in place of hardcoded formats.
- Numbers and currency use `Intl.NumberFormat` in place of hardcoded formats.
- Language comes from `Accept-Language` / `navigator.languages`, not IP.
- Brand names, code tokens, and identifiers carry `translate="no"`.

## Hydration safety

- An input with `value` has `onChange`, or uses `defaultValue` when uncontrolled.
- Date and time rendering guards against server/client mismatch.
- `suppressHydrationWarning` only where a mismatch is unavoidable.

## Hover and interactive states

- Buttons and links have a `hover:` state.
- Hover, active, and focus states raise contrast above the rest state.

## Content and copy

- Active voice: “Install the CLI”, in place of “The CLI will be installed”.
- Title Case for headings and buttons (Chicago style).
- Numerals for counts: “8 deployments”, in place of “eight”.
- Specific button labels: “Save API Key”, in place of “Continue”.
- Error messages include the fix or next step, not only the problem.
- Second person; first person stays out.
- `&` in place of “and” only where space is constrained.
