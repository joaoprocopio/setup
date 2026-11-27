---
title: Treat retry as a detector, not a crutch
impact: CRITICAL
tags: [config, retries, flakiness]
---

Configure `retries: 2` with `failOnFlakyTests: true` in every environment. The retry does not exist to hide failure. It exists to **classify** it:

- Fails all three attempts: a regression.
- Fails, then passes: a flake. The run **still fails**, but the report names the right category and attaches evidence from both executions.

```ts
export default defineConfig({
  retries: 2,
  failOnFlakyTests: true,
  use: { trace: "retain-on-failure" },
});
```

Use `trace: "retain-on-failure"`, which records the trace of every attempt and discards the green ones. The official docs recommend `on-first-retry` for cost, but in that mode the trace captured in a flaky scenario comes from the attempt that _passed_. Under `failOnFlakyTests`, the evidence that matters is the first failed attempt, and `retain-on-failure` is the mode that preserves it.

Two effects make a tolerated flake expensive:

- Flakiness compounds. Suite reliability is the _product_ of individual reliabilities, so 2,000 tests that each pass 99.95% of the time pass together about 37% of the time.
- Tolerated flakes hide regressions. A team that learns to dismiss a red build as “probably a flake” dismisses real failures too, and broken code reaches production.

“Passes locally, breaks in CI” names a race, not a CI defect: the fast, idle local machine masks what runner contention reveals. Reproduce it with `--repeat-each=100 --workers=10` before blaming infrastructure.
