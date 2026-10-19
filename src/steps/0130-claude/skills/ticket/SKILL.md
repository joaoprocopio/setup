---
name: ticket
description: Write a ticket a cold reader can implement and test from its description alone, whether feature, bug, epic, or spike. Use when drafting, rewriting, or reviewing a ticket, issue, bug report, or acceptance criteria.
---

# Ticket

A ticket's job is shared understanding: the writer, the implementer, and the tester read it and reach the same verdict on what "done" means. Correct work that bounces back from QA is the failure this skill prevents, and its usual cause is an ambiguous acceptance criterion.

The whole skill unfolds from one test, the **cold reader**: someone who joined none of the conversations can implement and test the ticket from its description alone. Every rule below serves that reader. The target is the right content, not more content: the problem, the bounds, the decisions already made, and criteria with one possible reading.

## Writing a ticket

1. **Gather.** Collect the problem, the decisions, and the constraints from the conversation, linked tickets, and the code. Write in the language the project's tickets already use.
2. **Type it.** Pick feature, bug, epic, or spike, and follow that type's shape under "Shape by type".
3. **Size it.** If the criteria pile up "and also", the ticket is too big: split it first, per [`SPLITTING.md`](SPLITTING.md), then write each piece.
4. **Draft** to the principles and the criteria rules.
5. **Walk it in slow motion.** Trace the user from start to end and decide each edge case the walk exposes (see principle 3).
6. **Reread** against "Reread checklist". Done when every item holds, or its gap is listed under **Open questions**.

Source every decision from the user or the context. A decision you cannot source is an open question: ask the user, or list it under **Open questions** in the ticket, so the gap stays visible instead of becoming a guess the implementer inherits.

## Reviewing a ticket

Apply every principle and the reread checklist, and report each gap as the question a cold reader would ask, with a proposed rewrite. The rules are a guideline, not a gate: judge a ticket by whether it produces shared understanding, never by whether it follows the template.

## Updating a ticket

The description is a living document. Fold every decision from refinement or chat back into it, above all the examples and edge cases QA will test. When scope changes mid-sprint, edit the description and flag the change, so nobody tests against a stale criterion.

## Principles

### 1. Problem before solution

Open with the problem the ticket solves, before any "what to do". Without a problem there is no basis for judging whether a solution is good. Frame it as one concrete case: who tried to do what, and why it fails today. "The organiser tried to resend the invite to 40 guests who hadn't replied and had to open each invite one by one" beats "improve invite resending". With the problem stated, done means "the problem is gone", not "did what the card said", and dev and QA share one yardstick.

### 2. Solve at the right altitude

Well-shaped work is **rough, solved, and bounded**:

- **Solved**: the main path is thought through end to end, so the implementer finds no missing decision mid-sprint.
- **Bounded**: the ticket says where to stop. What isn't written isn't scope.
- **Rough**: leave to the team what it does better: pixels, layout, names, implementation.

Too vague ("improve the confirmation screen") forces mind-reading, and each mind reads differently. Too precise (a polished mock with no caveats) becomes an implicit contract, and QA fails the card on cosmetic differences that were never requirements. Add concrete detail only at **linchpins**: the spots likely to be misread or technically tricky.

Two techniques hit the middle:

- **Flow in words**: name the screens, the elements the user acts on, and how one leads to the next. "On the guest list, the Resend button opens a dialog listing non-responders and a Confirm send button." This doubles as a test script.
- **Fat-marker sketch**: if you attach an image, prefer a visibly unfinished sketch, and state what in it is required and what is illustration.

Replace generic phrasing with an enumerated list of deliverables. Each item becomes a verifiable criterion; anything off the list is out of scope.

### 3. Decide the rabbit holes

Rabbit holes are the unknowns that blow up timelines and expectations. Walk the use case in slow motion and, at each step, ask whether it needs new technical work, assumes parts connect in a way nobody checked, or hides a hard decision. Check the usual suspects: empty state, error, permission, legacy data, repeated action, already-completed item.

Each one needs a written decision, not a sophisticated solution. "Guest without email: left out of the resend list, no warning" is cheap on paper and expensive when improvised mid-sprint. Take technical doubts to a developer before planning, and ask what the idea costs, not whether it is possible.

### 4. Write the out of scope

Every feature ticket carries an **Out of scope** section listing what it deliberately doesn't deliver. Prioritise what a reasonable reader would assume is included: that's where divergence lives, and where QA tests something that was never in scope. Keep **nice-to-haves** as a separate, explicitly optional list, so nobody mistakes them for requirements.

### 5. Stand alone

Write for a reader who wasn't in the meeting: anticipate their likely questions and answer them in the description. Every link to a ticket, PR, or document carries one sentence saying what is there and why it matters: "Same root cause as TA-465 (crash from browser translation)", never a bare "TA-465". Stand-alone doesn't mean exhaustive: stop at enough context to implement and test without calling anyone.

## Acceptance criteria

The criteria are the ticket's behaviour: if the system meets all of them it is correct, and if it misses one it is not. There is no third reading.

- **Yes-or-no answer**: QA can say pass or fail from the criterion alone. If you cannot imagine the test, the criterion is ambiguous.
- **Explicit starting state**: most ambiguity hides in the unstated precondition (logged in or not? invite already sent? event past or future?). Given/When/Then forces it into the open:
  - **Given**: context and state only, no user actions.
  - **When**: one event, by a user or an external system.
  - **Then**: an outcome the user can observe.
- **Behaviour, not implementation**: "the guest confirms attendance with valid data" outlives "types X in field Y and clicks Send". Test: if the wording would change when the implementation changes, rewrite it. Use domain words (invite, confirmation), never technical jargon.
- **One behaviour per scenario**: each distinct condition gets its own scenario.
- **Beyond the happy path**: cover the edge cases principle 3 decided (error, empty, duplicate, no permission). For each business rule, give one concrete example with realistic data and one counter-example.
- **Measurable words**: rewrite `fast`, `easy`, `simple`, `intuitive`, `adequate`, and `supports many` as a number or an observable condition. "Responds within 3 seconds" passes or fails; "is fast" starts an argument. When measuring isn't worth it, define the term: "easy = at most 3 clicks".

Given/When/Then is a tool, not a ritual. A full scenario reads:

```text
Given a guest who hasn't replied,
when the organiser triggers a resend,
then the guest receives a new invite email
and the guest list shows the resend date.
```

A trivial criterion ("the button disappears after sending") reads fine as one direct sentence, held to the same discipline: observable and testable.

The enumerated deliverables from principle 2 are raw material: each item needs its own criterion. Three to five criteria is a healthy card; well beyond that signals a card to split, and fewer while QA keeps bouncing it signals missing criteria.

## Titles

The title shows up on the board, in search, and in triage, so it stands alone:

- **Feature or task**: a verb completing "This ticket will…": "Allow bulk resend of invites to non-responders", never "Invite resending".
- **Bug**: the observable symptom plus the area, under 60 characters: "Attendance confirmation returns 500 when the invite has expired", never "Problem with confirmation". State the symptom, not the fix you suspect.

## Shape by type

The principles apply to every type; the weight shifts.

### Feature or story

Uses the whole skill; principles 1, 4, and the acceptance criteria weigh most. Sections, in order: **Problem**, **Solution** (flow in words, deliverables), **Edge cases** (decisions), **Out of scope**, **Acceptance criteria**, and **Open questions** if any remain.

### Bug

One bug per ticket: each defect has its own fix-and-test cycle. Sections:

- **Steps to reproduce**: numbered, cut to the fewest steps that still trigger it, including any special setup, runnable by a cold reader.
- **Expected result**: what should happen. This is the bug's acceptance criterion, so make it verifiable.
- **Actual result**: what happened, verbatim where possible (exact error text, status code).
- **Environment**: version or build, platform, where it does and doesn't occur.
- **Frequency**: always, sometimes (with whatever is unique about when), or once.
- **Notes**: attachments (stack trace, logs, screenshot), and any suspected cause, labelled as speculation, kept apart from the observations.

### Epic

Write an epic by its outcome, never its task list; the tasks live in the child tickets. The description answers: what objective, who benefits, which signal says it worked, and what is out. A hypothesis frames it well:

```text
We believe that [building this] for [these people]
will achieve [this outcome].
We will know this is true when we see [this signal].
```

"Cut API response time below 200 ms" is an epic with an end; "API refactor" is a folder that never closes. Fine-grained acceptance criteria live in the children; the epic's criterion is its signal.

### Spike

A spike answers a question; it ships no feature. Sections:

- **Question**: one specific unknown, technical or functional.
- **Timebox**: in days ("2 days"), never "until solved".
- **Deliverable**: its form (decision record, throwaway prototype, comparison), enough to write and size the follow-up tickets.

Its acceptance criterion is always the same: the question is answered and the result is shared with the team. Production code is never the deliverable. When building a thin real slice would answer the question, write that ticket instead.

## Reread checklist

- The problem comes before the solution, as a concrete case.
- A cold reader could implement and test from the description alone.
- Every obvious edge case (error, empty, permission, repetition) has a written decision and a criterion.
- **Out of scope** names what a reasonable reader would assume is included.
- Every criterion answers yes or no and states its precondition.
- No criterion leans on an unmeasured `fast`, `easy`, `simple`, or `intuitive`.
- Every link carries a sentence of context.
- The latest refinement decisions are in the description.
- The title stands alone on the board.
- More than five criteria: consider splitting before detailing.
