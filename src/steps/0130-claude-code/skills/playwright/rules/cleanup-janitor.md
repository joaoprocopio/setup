---
title: Clean up with a janitor at the start of the session
impact: MEDIUM
tags: [cleanup, teardown, hygiene]
---

Test correctness never depends on cleanup: each test creates its own world and ignores leftovers from others. Cleanup is environment hygiene, and it runs as a **janitor** in `globalSetup`, sweeping every record that carries the suite's data prefix and that earlier runs left. The current run's data stays until the next run starts, so a failed run keeps its data for investigation.

The sweep runs before the tests because nothing after them knows whether the run failed. `globalTeardown` receives only the config, a teardown project runs even when tests or setup fail, and no documented API tells either one the run's result. A janitor at the end can only sweep every time, evidence included, or never. If the sweep must run at the end, delete only records older than the longest run, so the latest run's data survives.

Four rules complete the design:

- Against production, the sweep also runs at the end of every run, this run's data included, because synthetic data cannot stay there. The trace and the report are the evidence.
- The sweep deletes the data of any run still in flight, so it assumes one run per environment at a time, as described in [env-parametrize-only](env-parametrize-only.md).
- The janitor code also runs as a standalone script, to sweep on demand, for example after a production run killed by a crash or a job timeout, since no teardown runs after `kill -9`.
- Tests leave their data in place for the janitor. Per-test teardown skips a crash, deletes the evidence of failures, and adds cost to every test.

**Incorrect** (per-test teardown deletes evidence and skips a crash):

```ts
test.afterEach(async ({ api }) => {
  await api.deleteOrder(orderId);
});
```

**Correct** (session-level sweep of earlier runs, by prefix):

```ts
// global-setup.ts
await api.deleteAllWithPrefix("E2E-");
```

This design accepts one known cost in exchange for fewer moving parts at the start: `globalSetup` runs outside the report, so a failure there produces no trace and no HTML entry. When the suite grows, migrate the janitor to a setup project through project dependencies, which gains trace, report, and retry.
