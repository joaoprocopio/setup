---
title: Run identically in any environment
impact: HIGH
tags: [environments, config, secrets]
---

The suite receives URLs and credentials, and nothing else. No test contains an `if` per environment: the same code runs against staging, QA, or production, changing only environment variables (`E2E_WEB_URL`, `E2E_API_URL`, `E2E_ADMIN_EMAIL`, `E2E_ADMIN_PASSWORD`, …).

The API gets its own URL because it rarely shares the front end’s host, and the provisioning layer builds a request context from it, as described in [provision-via-intent-helpers](provision-via-intent-helpers.md).

Secrets live in a local file outside version control, with a committed example file documenting every required key, or in the CI vault. Never in code.

**Incorrect:**

```ts
if (process.env.TARGET === "staging") {
  await page.goto("https://staging.example.com/admin");
} else {
  await page.goto("https://example.com/admin");
}
```

**Correct:**

```ts
// playwright.config.ts
use: { baseURL: requiredEnv("E2E_WEB_URL") },
// test
await page.goto("/admin");
```

One named exception: choosing a reporter or trace level through `process.env.CI` varies the tooling, not the test behavior, and is acceptable.

Pointing the suite at **production** requires three prerequisites, with no exceptions:

1. Every created record is identifiable by the `E2E-` prefix and covered by automated cleanup.
2. Real side effects such as emails, notifications, and charges are neutralized through dedicated test accounts and data.
3. Cleanup runs at the end of every run, including failed runs.

## Optional services are required variables

A journey that needs a service some environments lack, such as a mail catcher or a payment sandbox, never skips when its variable is unset. `test.skip(!process.env.E2E_MAIL_URL)` turns a misconfigured environment into a quiet skip, and the run reads as green. pytest deprecated the same pattern in `importorskip`, because “more often than not users would rather see the unexpected error so the underlying issue can be fixed” ([pytest deprecations](https://docs.pytest.org/en/stable/deprecations.html)). Model the service one of two ways:

- Add its variable to the required set, so every run needs it.
- Read the variable in a fixture that throws when it is missing, so only the tests that name the fixture fail.

```ts
mailbox: async ({}, use) => {
  await use(new Mailbox(requiredEnv("E2E_MAIL_URL")));
},
```

## One run per environment at a time

The suite assumes one run per environment at a time. Two runs against one environment break each other: the janitor sweeps the other run’s data mid-test, and a setup project that resets shared state resets it under the other run’s tests. Software Engineering at Google names the same hazard for shared environments: “the test might conflict with other simultaneous uses” ([chapter 14, Larger Testing](https://abseil.io/resources/swe-book/html/ch14.html)).

Two runs from one checkout also share an output folder, and Playwright empties `test-results/` at the start of every run, so the second run deletes the first run’s traces ([`outputDir`](https://playwright.dev/docs/api/class-testconfig#test-config-output-dir)). Give each concurrent run its own `--output <dir>`.

To run part of the suite, two flags decide what else runs:

- `--project X` also runs the projects X depends on ([project dependencies](https://playwright.dev/docs/test-projects#dependencies)) and X’s teardown project. A project that depends on every browser project runs the whole suite when you select it alone.
- `--no-deps` runs only the selected tests, with no dependency and no teardown project, so neither setup nor the janitor touches the environment. Whatever setup would have provided must already exist.
