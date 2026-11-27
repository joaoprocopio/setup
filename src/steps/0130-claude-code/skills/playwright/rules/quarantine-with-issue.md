---
title: Quarantine tests only with a linked issue
impact: MEDIUM
tags: [quarantine, hygiene, process]
---

A broken test leaves the suite by fix or by removal, never by being forgotten. Both `test.fixme()` and `test.skip()` require an annotation with an issue link. A skip condition points at matrix dimensions such as engine or persona, never at environment or at a missing variable, which would break the run-anywhere contract described in [env-parametrize-only](env-parametrize-only.md).

**Incorrect:**

```ts
test.skip("customer places an order", async ({ page }) => {
  /* ... */
});
test.skip(process.env.TARGET === "staging", "broken on staging");
```

**Correct:**

```ts
test.fixme(
  "customer places an order",
  {
    annotation: {
      type: "issue",
      description: "https://issues.example.com/E2E-123",
    },
  },
  async ({ page }) => {
    /* ... */
  },
);

test.skip(
  ({ browserName }) => browserName === "firefox",
  "no touch events in Firefox",
);
```

Audit the quarantine list every cycle, because quarantine without a deadline is removal in disguise. A ceiling works as a default: 8 quarantined tests, or one week to fix or delete.

## Known bugs run under `test.fail`

A test that documents a known bug asserts the correct behavior under `test.fail()` with an issue annotation. It never asserts today's buggy behavior as if it were correct, because that test stays green while the bug lives and turns red when someone fixes it, which reads as a regression. Playwright runs a `test.fail` test, counts its failure as a pass, and reports "Expected to fail, but passed." as a failure the moment the bug is fixed.

**Incorrect** (pins the bug, with no issue):

```ts
await expect(cart.total()).toHaveText("0"); // should be 3, see bug
```

**Correct:**

```ts
test.fail(
  "cart total counts every item",
  {
    annotation: {
      type: "issue",
      description: "https://issues.example.com/E2E-124",
    },
  },
  async ({ page }) => {
    /* ... */
    await expect(cart.total()).toHaveText("3");
  },
);
```

Any failure satisfies `test.fail`, a wrong locator included. Run the test once without the modifier and check that it fails on the bug's assertion.
