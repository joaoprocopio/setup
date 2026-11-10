---
name: ticket
description: Write a ticket a cold reader can implement and test from its description alone, whether feature, bug, epic, or spike. Use when drafting, rewriting, or reviewing a ticket, issue, bug report, or acceptance criteria.
---

# Ticket

A ticket is the **contract** between the writer, the implementer, and QA: all three read it and reach the same verdict on what "done" means. Write it for the **cold reader**, someone who joined none of the conversations and must implement and test from the description alone. Keep it to **one screen**: the problem, the behaviour, the bounds, and criteria QA can check. Everything else lives in the PR, the comments, or an ADR.

Use the vocabulary of the project's `GLOSSARY.md` (or the one `GLOSSARY-MAP.md` points to), and write in the language the project's tickets already use.

## Templates

Use these headings word for word on every card. Where the project's tickets already name a section, reuse that exact name every time. Drop a section that has nothing to say.

Feature or task:

```markdown
## Problem

<one concrete scene: who tried to do what, and what went wrong for them>

## Solution

<the flow in words: screens, the elements the user acts on, what each leads to>

## Edge cases

- <case>: <decision>

## Out of scope

- <item>

## Acceptance criteria

- [ ] <one behaviour QA can observe>

## How to test

1. <where the screen is, the data to set up, then the steps>

## Open questions

- <question>, for <person>
```

Bug:

```markdown
## Steps to reproduce

1. <fewest steps that still trigger it, with any setup>

## Expected result

<what should happen, verifiable: this is the acceptance criterion>

## Actual result

<what happened, verbatim: error text, status code>

## Environment

<build, platform, where it does and does not occur, what was not checked>

## Notes

<attachments, and any suspected cause labelled as speculation>
```

Epic: an outcome, never a task list. State the objective, who benefits, the signal that says it worked, and what is out. The children carry the criteria.

Spike: a **Question** (one unknown), a **Timebox** in days, and a **Deliverable** (decision record, throwaway prototype, comparison) enough to write the follow-up tickets. It ships no production code.

## Writing a ticket

1. **Gather** the problem, the decisions, and the constraints from the conversation, linked tickets, and the code.
2. **Decide the edge cases.** Call the Skill tool with `grilling` to walk the user's path with the user and settle each rabbit hole: empty state, error, permission, legacy data, repeated action. Every decision goes under **Edge cases** as one line; every decision you cannot source goes under **Open questions**.
3. **Draft** into the template, section by section, to the rules below.
4. **Reread as QA.** Done when every criterion can be checked on screen from **How to test**, and the card fits on one screen. If the draft covers more than one problem, tell the user; how to split is their call.

## Sections

### Problem

Open with the effect the user feels, as a scene with a date, an actor, and data. The mechanism comes later, in **Solution** or the PR.

```text
Good: On 3/9 the organiser resent an invite that had already gone out on 21/7, and 40 guests got it twice.
Bad:  The organiser hits /invites/resend, which reads Invite.sent_at without checking the batch.
```

### Solution

Describe behaviour, not design: what the user sees and does. Leave settings, file paths, field names, and library calls to the PR; they go stale and QA cannot test them. Add concrete detail only at spots likely to be misread. An attached image is a visibly rough sketch, with a line saying what in it is required.

### Edge cases and Out of scope

One line per item: the case and the decision, or the excluded item. The reasoning behind a decision goes in a comment, so the card stays scannable. List under **Out of scope** what a reasonable reader would assume is included.

### Acceptance criteria

Each criterion is one behaviour QA can see on screen and mark pass or fail alone. Write it in the words of the screen, with the precondition when one matters. When a behaviour cannot be reproduced in the test environment, say so on the criterion and name who verifies it and how.

```text
Good: - [ ] With a guest who has not replied, Resend shows "Invite resent" and the guest list shows today's date.
Bad:  - [ ] POST /resend with only_pending=on returns 200, sets resent_at, and logs the batch.
```

The bad one names a field, an endpoint, and a log; QA cannot reach any of them, and it checks three things at once.

### How to test

Start with where the screen is and the data to set up, then the steps. Every step works at any time: a step that must run "before the merge" or on data that may be cleaned up fails the next tester. Name fresh data to create in place of a specific record ID.

### Links

Every link to a ticket, PR, or document carries one sentence saying what is there and why it matters: "Same root cause as TA-465 (crash from browser translation)". The card still reads whole without opening any of them.

## Updating a ticket

The card states the current contract, never the history. When a decision changes, edit the section it belongs to and flag the change in a comment, so nobody tests against a stale criterion. Investigation notes, priority arguments, and the story of the work go in comments or the PR. A card already in QA changes only its criteria and **How to test**, and the change is announced in a comment.

## Reviewing a ticket

Read it as the cold reader and as QA. Report each gap as the question they would ask, with a proposed rewrite. Judge the card by whether the three readers reach the same verdict, not by whether it fills the template.
