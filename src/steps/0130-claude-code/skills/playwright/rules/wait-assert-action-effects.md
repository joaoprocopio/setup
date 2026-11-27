---
title: Assert the effect of every meaningful action
impact: CRITICAL
tags: [waiting, hydration, race-conditions]
---

Playwright’s auto-wait verifies visibility, stability, and occlusion, never the existence of an event handler. In server-side rendered (SSR) apps a button looks ready before JavaScript attaches its listeners, so a click before hydration is lost **without any error**.

The runner cannot prove the app reacted, so your assertion must. Follow every meaningful action with a web-first assertion of its effect. That turns a hydration race into a local, diagnosable failure instead of a mysterious one three steps later.

**Incorrect** (the lost click fails far from the cause):

```ts
await page.getByTestId("guest-form-submit").click();
await page.getByTestId("next-step-button").click(); // fails here, cause was above
```

**Correct** (the race fails at the action that lost it):

```ts
await page.getByTestId("guest-form-submit").click();
await expect(page.getByTestId("confirmation-banner")).toBeVisible();
```

Four related traps:

- **“It works if I add a delay” is a diagnosis, not a fix.** The delay that appears to fix a lost click proves the race exists. The real fix belongs in the product, where controls are born `disabled` until hydration completes, or in asserting a deterministic readiness signal.
- **Lazy content shifts layout between aim and click**: Playwright clicks a valid neighbor, with no error. Assert the state that stabilizes the page first (skeleton gone, list loaded) and treat layout shift as a product bug.
- **Popups and downloads**: register `waitForEvent` _before_ the action that triggers it. Registered after the click, the event is lost with no way to recover it. Downloaded files are discarded when the browser context closes, so persist them with `download.saveAs()` inside the test.
- **Dialog listeners**: with no listener Playwright dismisses dialogs on its own, but registering one, even only for logging, transfers that responsibility. Without `accept()` or `dismiss()` the action blocks until timeout.

## Add a ready signal when the UI shows none

When nothing on screen says the data has loaded, add a signal to the application: a test id or attribute that appears only once the data has rendered, asserted with `toBeVisible()` or `toHaveAttribute()`. A `waitForResponse` proves the request finished, not that the UI rendered its result. The signal is worth adding even when only the tests read it.

## Anchor every negative assertion

`toHaveCount(0)`, `not.toBeVisible()`, `toBeHidden()`, `not.toBeAttached()`, and `not.toBeInViewport()` pass at once on a locator that matches nothing. A check that something did not appear passes before the application had time to show it, and any of them passes forever on a misspelled or renamed test id. The other `not.` matchers, such as `not.toHaveText()` and `not.toBeEnabled()`, fail on a missing element with “element(s) not found”.

Give each such assertion two anchors:

- Before it, assert the positive state that proves the action completed, so the negative check runs after the application handled the action.
- Prove the same locator positive somewhere, in an earlier step of the test or in another test, so a wrong locator fails there.

**Incorrect** (passes before the server answers, and on any typo in the test id):

```ts
await page.getByTestId("order-form-submit").click();
await expect(page.getByTestId("order-form-error")).toBeHidden();
```

**Correct** (the effect is visible first, and the test for an invalid order proves `order-form-error` visible):

```ts
await page.getByTestId("order-form-submit").click();
await expect(page.getByTestId("order-confirmation")).toBeVisible();
await expect(page.getByTestId("order-form-error")).toBeHidden();
```
