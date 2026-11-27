---
title: Disable animations with a fixture
impact: MEDIUM
tags: [waiting, animations, stability]
---

Animations are a primary source of `element is not stable`. Two nearly identical frames satisfy Playwright's stability check, and an easing curve that decelerates mid-animation produces exactly that: Playwright clicks, and the element keeps moving. Playwright treats this as expected behavior.

Fix it at the source with a fixture that injects CSS zeroing the duration and delay of every animation and transition, plus `scroll-behavior`, in every document. That makes actionability deterministic without `force: true`, which would skip the overlap checks entirely. Zero the delays too: with only the duration at zero, an element holds still through its delay, passes the stability check, and then jumps to its end state.

```ts
export const test = base.extend({
  page: async ({ page }, use) => {
    await page.addInitScript(() => {
      const style = document.createElement("style");
      style.textContent = `*, *::before, *::after {
        animation-duration: 0s !important;
        animation-delay: 0s !important;
        transition-duration: 0s !important;
        transition-delay: 0s !important;
        scroll-behavior: auto !important;
      }`;
      document.addEventListener("DOMContentLoaded", () =>
        document.head.appendChild(style),
      );
    });
    await use(page);
  },
});
```

When a test's subject _is_ an animation, opt out locally and assert on the animation's end state, never by sleeping through it.
