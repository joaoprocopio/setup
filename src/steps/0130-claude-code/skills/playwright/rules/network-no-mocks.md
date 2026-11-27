---
title: Exercise the real backend instead of mocking the network
impact: HIGH
tags: [network, mocking, fidelity]
---

Every test exercises the real backend of the targeted environment, end to end. A `page.route()` that fakes a success response from your own backend stops validating the actual deploy and creates disguised behavior variation between tests. Playwright’s Best Practices limit faked responses to what you do not control: “Only test what you control. Don’t try to test links to external sites or third party servers that you do not control” ([Best Practices](https://playwright.dev/docs/best-practices#avoid-testing-third-party-dependencies)).

Three uses of `page.route()` differ, and only the first breaks this rule:

- **Faking your own endpoint’s success**: banned. The test then proves the client against a guess at the server, not against the server.
- **Injecting a fault the real stack cannot produce on demand**, such as an HTTP 500, an aborted request, or a third party being down: acceptable when the test asserts on that fault. Software Engineering at Google allows stubs for “errors that might not be possible to trigger from a real implementation”, and adds that “each stubbed function should have a direct relationship with the test’s assertions” ([chapter 13, Test Doubles](https://abseil.io/resources/swe-book/html/ch13.html)).
- **Holding or delaying a real response to observe an in-flight state**, such as a spinner or a disabled submit button: acceptable. Fetch the real response with `route.fetch()` and fulfill it once the test has asserted the in-flight state, so the server still answers ([Modify API responses](https://playwright.dev/docs/mock#modify-api-responses)).

```ts
let release!: () => void;
const held = new Promise<void>((resolve) => (release = resolve));
await page.route("**/api/orders", async (route) => {
  const response = await route.fetch();
  await held;
  await route.fulfill({ response });
});
await page.getByTestId("order-form-submit").click();
await expect(page.getByTestId("order-form-submit")).toBeDisabled();
release();
await expect(page.getByTestId("order-confirmation")).toBeVisible();
```

The full set of error paths still belongs to the cheaper layers: frontend integration and unit tests. Inject a fault in E2E only for the few errors a journey depends on.

Freezing the browser clock with `page.clock` against a real backend creates the same problem: two clocks that diverge, and failures that are hard to diagnose. Restrict clock mocking to purely client-side behavior, such as how a relative date renders.
