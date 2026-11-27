---
name: playwright
description: Rules for writing deterministic, flake-free end-to-end tests with Playwright. Use when writing, reviewing, or debugging Playwright tests, setting up an E2E config or harness, investigating a flaky test, or choosing selectors, test data, waits, or timeouts. Applies even when the user never says "flaky" or "deterministic".
---

# Playwright deterministic testing

This skill holds the rules that keep an end-to-end suite trustworthy: four non-negotiable principles, the config that encodes them, and one rule file per area (waiting, selectors, test data, structure, config).

A test is **deterministic** when the same application code always produces the same result: on any machine, in any order, at any parallelism. A test is **flaky** when it alternates between green and red with no change in the code under test. Flakiness is always a bug, either in the test (implicit wait, shared data, ambiguous selector) or in the application (a real race the user also hits).

## Non-negotiable principles

The rest of this skill derives from these four:

1. **Every test is independent and self-contained.** A test creates everything it needs and references only what it created. No test depends on another test, on execution order, or on state left by previous runs.
2. **Every test is deterministic.** Every wait targets a condition, never a duration such as `waitForTimeout`. Every piece of data belongs to one test, and every selector matches one element. A test that needs a retry to pass is broken.
3. **The whole suite runs in parallel.** Set `fullyParallel: true` from day one. Parallelism is not a late optimization: it is the continuous proof that principle 1 holds.
4. **Flakiness fails the run.** With `failOnFlakyTests: true`, a test that failed and passed on retry fails the whole run. A flake is a bug with priority, never tolerated noise.

The minimal config that encodes them:

```ts
export default defineConfig({
  fullyParallel: true,
  retries: 2,
  failOnFlakyTests: true,
  forbidOnly: !!process.env.CI,
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
});
```

## Rules

Ordered by impact: the top rules sustain every rule below them. Read a rule file before you work in its area.

| Rule                                                                  | Read when                                                                                      |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [wait-web-first-assertions](rules/wait-web-first-assertions.md)       | asserting a state, waiting for one, or replacing an `expect` with `waitFor()` or `filter()`    |
| [wait-assert-action-effects](rules/wait-assert-action-effects.md)     | after a click or submit, before a negative assertion, or around popups, downloads, and dialogs |
| [config-retry-as-detector](rules/config-retry-as-detector.md)         | setting retries or the trace mode, or triaging a test that failed once                         |
| [select-by-test-id](rules/select-by-test-id.md)                       | choosing a locator or naming a test id                                                         |
| [journeys-smallest-proof](rules/journeys-smallest-proof.md)           | deciding what one test covers, or splitting a long test                                        |
| [data-unique-identifiable](rules/data-unique-identifiable.md)         | creating test data, per-worker resources, or anything that depends on the date                 |
| [provision-via-intent-helpers](rules/provision-via-intent-helpers.md) | preparing data before the UI step, or calling the backend from a test                          |
| [fixtures-compose-explicitly](rules/fixtures-compose-explicitly.md)   | adding or overriding a fixture                                                                 |
| [env-parametrize-only](rules/env-parametrize-only.md)                 | reading an environment variable, targeting another environment, or running part of the suite   |
| [network-no-mocks](rules/network-no-mocks.md)                         | using `page.route()` or `page.clock`, or testing an error path                                 |
| [cleanup-janitor](rules/cleanup-janitor.md)                           | deleting test data, or writing global setup or teardown                                        |
| [wait-disable-animations](rules/wait-disable-animations.md)           | seeing `element is not stable`, or testing animated UI                                         |
| [structure-persona-projects](rules/structure-persona-projects.md)     | defining projects, devices, or persona tags                                                    |
| [structure-component-objects](rules/structure-component-objects.md)   | writing a component or page object, or locating a toast                                        |
| [config-timeout-budget](rules/config-timeout-budget.md)               | changing a timeout, or debugging a test that hit one                                           |
| [quarantine-with-issue](rules/quarantine-with-issue.md)               | skipping a test, or testing a known bug                                                        |

## Out of scope

- **Visual regression by screenshot** (`toHaveScreenshot`): pixel baselines require identical rendering environments between generation and verification, which conflicts with running from any machine against any URL, and multiplies baselines across the device matrix. Targeted structural assertions (`toMatchAriaSnapshot`) cover part of the need with far more stability.
- **Accessibility scans**: worth doing, especially because the test-id-first selector choice gives up the semantic verification `getByRole` performs for free. They belong to a separate effort, not to this suite.
