---
name: to-tickets
description: Break a plan, spec, or conversation into tracer-bullet tickets that declare what blocks them, published as Asana tasks.
disable-model-invocation: true
license: MIT
metadata:
  forked-from: https://github.com/mattpocock/skills
  forked-skill: to-tickets
  forked-on: "2026-08-03"
  upstream-copyright: Copyright (c) 2026 Matt Pocock, MIT
  editor: Mike Zornek
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

Tickets are Asana tasks on the repo's board. The global Asana rule names the board and the section new tasks go in.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, or an Asana task URL) as an argument, fetch it and read its full description and every comment, as the global Asana rule says.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's glossary vocabulary, if it has a glossary — `docs/ubiquitous_language.md` or a root `UBIQUITOUS_LANGUAGE.md` — and respect any decisions in `docs/adr/` for the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change — rename a column, retype a shared symbol — whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behavior this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Publish the tickets

Publish the approved tickets with `create_tasks`, in dependency order — blockers first, so each ticket's **Blocked by** section can link tasks that already exist. When the source is an Asana task, create each ticket as a subtask of it by setting `parent`. Otherwise create them in the project and section the global Asana rule names.

Then record each ticket's blockers as Asana dependencies: `update_tasks` with `add_dependencies` on each blocked ticket, listing its blockers' GIDs. The body's **Blocked by** section mirrors them, so they stay readable without opening the dependency panel.

Read the edges back with `get_task` on each blocked ticket and confirm its `dependencies` before moving on. A ticket whose body says "Blocked by" while Asana records no dependency looks wired and is not.

Give the user each new task's URL.

Work the **frontier**: any ticket whose blockers are all complete. For a purely linear chain that means top to bottom.

Adding subtasks is the only change to a parent task; its description, status, and completion stay as they are.

<ticket-template>

## Parent

A link to the parent task (if the source was an existing task, otherwise omit this section).

## What to build

The end-to-end behavior this ticket makes work, from the user's perspective — not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A link to each blocking task, or "None — can start immediately".

</ticket-template>

Avoid specific file paths or code snippets — they go stale fast. The one exception is a snippet that came out of a prototype and pins a decision down more precisely than prose can; the `prototype` skill's capture rules say how to carry one across.
