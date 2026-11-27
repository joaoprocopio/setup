---
title: Use web-first assertions and trust auto-waiting
impact: CRITICAL
tags: [waiting, assertions, race-conditions]
---

`await expect(locator)` assertions retry until the condition holds or the timeout expires. They eliminate the race between async rendering and verification, which is the largest single cause of flakiness. Extracting a value and asserting synchronously takes a snapshot and waits for nothing.

**Incorrect** (checks once, waits for nothing, so it flakes):

```ts
expect(await page.getByTestId("welcome-message").isVisible()).toBe(true);
expect(await el.textContent()).toBe("Confirmed");
```

**Correct** (retries until the condition holds):

```ts
await expect(page.getByTestId("welcome-message")).toBeVisible();
await expect(el).toHaveText("Confirmed");
```

An `await` _inside_ the parentheses of `expect()` is the smell: it captures a value at an arbitrary instant and loses all polling. Rewrite it as a web-first assertion.

Before every action, Playwright already waits for the element to be visible, stable, enabled, and unobscured. Four consequences follow:

- `page.waitForTimeout()` is either redundant or a mask over a bug. Banned.
- `waitForLoadState("networkidle")` is officially discouraged: it waits for 500 ms with zero network connections, which never happens under polling, WebSockets, or analytics, and happens too early in apps that render after a response. Assert readiness on what the user sees. Banned alongside `waitForTimeout`.
- `force: true` clicks where a real user could not. Fix the obstruction instead. Banned, with one exception: Playwright treats `aria-disabled="true"` as disabled, so `click()` retries until the action timeout, while a real user’s click still reaches the control. To prove that clicking an `aria-disabled` control does nothing, click it with `force: true` and assert that no effect happened, anchored as [wait-assert-action-effects](wait-assert-action-effects.md) describes.
- `ElementHandle` (`page.$`, `page.$$`) points at a dead node after a re-render, and the docs themselves discourage the class. Use locators only, because they re-query the DOM on every use.

For conditions outside the DOM, use `expect.poll()` or `expect().toPass()` instead of sleeping.

Enable `@typescript-eslint/no-floating-promises` as an **error**. A forgotten `await` creates a silent race that passes locally and fails in CI, and the lint rule removes that entire bug class at build time.

## Waits and filters are not assertions

A web-first assertion is an `await expect(locator).toX()` call, and nothing else is. `locator.waitFor()`, `locator.filter({ hasText })`, `isVisible()`, and `textContent()` verify nothing, even when they appear to check the same thing. Rewriting `await expect(x).toHaveText(T)` as `await x.filter({ hasText: T }).waitFor()` changes five things:

- **Predicate**: `toHaveText` matches the whole text, case-sensitive, after whitespace normalization. `filter({ hasText })` matches a case-insensitive substring and has no `exact` option, so `"Confirmed"` passes on “Not confirmed”.
- **State**: `toHaveText` needs the element attached, not visible, and passes on a `display:none` element. `waitFor()` waits for visible by default. To claim the user sees the text, also assert `toBeVisible()`.
- **Timeout**: an assertion waits `expect.timeout`, 5s by default. `waitFor()` waits `actionTimeout`, whose default `0` means no limit, so a failed wait runs until the test timeout.
- **Ambiguity**: a locator that matches two elements fails `toHaveText` at once with a strict-mode violation. The filter narrows the matches to the one holding the text, so the ambiguous locator passes.
- **Diagnosis**: a failed assertion prints Expected, Received, and every unexpected value it saw, headed by the custom `expect(x, "message")` text if you passed one. A failed `waitFor()` prints “Timeout exceeded” and never shows the text it found.

Use `filter({ hasText })` to choose the element to act on or assert on, and assert on what it chose.

**Incorrect** (passes on “Not confirmed”, hides an ambiguous locator, and fails with a bare timeout):

```ts
await status.filter({ hasText: "Confirmed" }).waitFor();
```

**Correct:**

```ts
await expect(status).toHaveText("Confirmed");
```
