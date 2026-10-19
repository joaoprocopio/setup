# Splitting a ticket

A ticket whose criteria keep growing has a size problem, not a writing problem. Split before you detail: a small ticket has short criteria, and short criteria are testable.

## Slice vertically

Every piece delivers one complete, observable behaviour, touching every layer it needs (UI, logic, data). Cut by behaviour, never by layer: "build the API" and "build the screen" as separate tickets give QA nothing to accept, and breed artificial, ambiguous criteria.

## The simplest complete slice first

1. Find the core complexity: the part that makes the ticket hard.
2. List the variations: business rules, user types, data types, paths, interfaces.
3. Make the first ticket one end-to-end slice through the core, with every variation stripped out: usually the simple start and end of the workflow.
4. Give each variation its own ticket.

## Axes to cut along

Almost any ticket splits along one of these:

- **Path**: each way the user reaches the goal is a ticket. Share by copying a link first; share to a social network later.
- **Interface**: a basic interface first, richer ones after. Get a shareable URL first; a picker of network logos later.
- **Data**: a subset of the data first. Accept MP4 uploads only; other formats later.
- **Rules**: relax a business rule first, enforce it in a follow-up. Upload without the copyright check; add the check next.
- **Operations**: split create, read, update, and delete.
- **Workflow steps**: the first and last steps first, the middle steps as follow-ups.
- **Performance**: make it work, then make it fast, as two tickets with their own numeric criteria.
- **Spike**: when the unknown blocks any split, take the research out as a spike, then split with what it answers.

## Choosing between splits

Prefer the split that exposes low-value work, so it can be deprioritised or dropped. Between two splits of equal value, prefer the one giving pieces of similar size. Each piece must pass every rule in [`SKILL.md`](SKILL.md) on its own: its own problem, out of scope, and criteria.
