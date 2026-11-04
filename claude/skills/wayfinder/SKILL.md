---
name: wayfinder
description: Plan work too big for one agent session as a QuestLog questline of decision issues, resolved one at a time until the way to the destination is clear.
disable-model-invocation: true
license: MIT
metadata:
  forked-from: https://github.com/mattpocock/skills
  forked-skill: wayfinder
  forked-on: "2026-08-03"
  upstream-copyright: Copyright (c) 2026 Matt Pocock, MIT
  editor: Mike Zornek
---

A loose idea has arrived — too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **map** in QuestLog, then works its **decision issues** — questions whose resolution is a decision, not slices of a build to execute — one at a time until the route is clear.

The destination varies per effort, and naming it is the first act of charting — it shapes every issue. It might be a spec to hand off and iterate on, a decision to lock before planning starts, or a change made in place like a data-structure migration. The map is domain-agnostic — engineering work, course content, whatever fits the shape.

## Plan, don't do

Wayfinder is **planning** by default: each issue resolves a decision, and the map is done when the way is clear — nothing left to decide before someone goes and does the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off. An effort can override this in its **Notes** — carrying execution into the map itself — but absent that, produce decisions, not deliverables.

## QuestLog

The map and its decision issues are QuestLog issues, so the global QuestLog rule and `~/QuestLog/README.md` govern their files: the folder, the frontmatter, the issue IDs, and how to close one. Read the README before charting. This skill adds only what wayfinding needs on top of it.

All of an effort's issues go in the repo folder of the repo you are working in, `~/QuestLog/<repo>/`. Name each file after its title in kebab case. Take IDs from the next free ID that `elixir build.exs` prints, counting up from it when you create several issues in one pass.

After each pass of changes — charting, or resolving one issue — run `elixir build.exs` in `~/QuestLog`, fix any warning it prints about the issues you touched, then commit and push as the global QuestLog rule says. Another session may have created an issue since you read the next free ID, so a duplicate-ID warning means renumber yours.

## Refer by name

Every map and issue has a **name** — its title. In everything the human reads — narration, the map's Decisions-so-far — refer to it by that name, never by a bare ID or file name. A wall of `QL-81, QL-82, QL-83` is illegible; names read at a glance. The ID doesn't vanish — it rides beside the name, as in `Pick the queue backend (QL-82)`, but never stands in for it.

## The map

The map is a single issue — the canonical artifact. Its decision issues are its **children**: each names the map in its `parent` field, which makes the map a **questline**. A questline needs no marker of its own, so what makes this one a map is its body, below.

The map is an **index**, not a store. It lists the decisions made and points at the issues that hold their detail; a decision lives in exactly one place — its issue — so the map never restates it, only gists it and points.

### The map body

The whole map at low resolution, loaded once per session. Open decision issues are **not** listed — they are the map's open children, found by searching the repo folder for `parent: <map ID>`.

```markdown
## Destination

<what reaching the end of this map looks like — the spec, decision, or change this effort is finding its way to. One or two lines; every session orients to it before choosing an issue.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index — one line per closed decision issue: enough to judge relevance, then open the issue for the detail it holds -->

- <closed issue title> (QL-<id>) — <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog you can't write an issue for yet; graduates as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never graduates -->
```

### Decision issues

Each decision issue is a child of the map; its issue ID is its identity. Its body is the question, sized to one 100K token agent session:

```markdown
**Type:** <research | prototype | grilling | task>

## Question

<the decision or investigation this issue resolves>
```

The **Type** line names one of the [issue types](#issue-types). Tags keep their README meaning — the area of the work — so the type does not go in `tags`.

Blocking edges go in the `blocked_by` frontmatter field, as the README's Blocking section defines it. Hierarchy says which map an issue belongs to; blocking says what has to finish first, and only the second decides the frontier. An issue is **unblocked** when every issue in its `blocked_by` list is closed; the **frontier** is the map's open, unblocked children — the edge of the known, and what the viewer's Ready filter shows within the map's questline. Take the frontier in ID order, since the frontmatter cannot express any other order.

The answer isn't part of the question — it's recorded on resolution, in the `## Resolution` section the README defines (see [Work through the map](#work-through-the-map)). Assets created while resolving an issue go in a subfolder named after the issue's file, as the README's Attachments section says, and are linked from the issue, not pasted in.

## Issue types

Every decision issue is either **HITL** — human in the loop, worked *with* a human who speaks for themselves — or **AFK**, driven by the agent alone. A HITL issue only resolves through that live exchange; the agent never stands in for the human's side of it (a grilling agent that answers its own questions has broken this).

- **Research** (AFK): Reading documentation, third-party APIs, or local resources like knowledge bases to surface a fact a decision waits on. Resolved by a `/research` **subagent**. Use when knowledge outside the current working directory is required.
- **Prototype** (HITL): Raise the fidelity of the discussion by making a cheap, rough, concrete artifact to react to — an outline, a rough take, a stub, or UI/logic code via the /prototype skill. Links the prototype as an asset. Use when "how should it look" or "how should it behave" is the key question.
- **Grilling** (HITL): the default case. `/grill` is user-invoked, so ask the user to run it rather than trying to invoke it — put the question to them and let them decide.
- **Task** (HITL or AFK): Manual work that must happen before a *decision* can be made — nothing to decide, prototype, or research, but the discussion is blocked until it's done. Signing up for a service so its API can be judged, provisioning access, moving data so its shape can be seen. This is the one type that *does* rather than decides — and it earns its place by unblocking a decision, not by delivering the destination. The agent drives it alone where it can (AFK); otherwise it hands the human a precise checklist (HITL). Resolved when the work is done; the Resolution records what was done and any resulting facts (credentials location, new URLs, row counts) later issues depend on.

## Fog of war

The map is _deliberately_ incomplete: don't chart what you can't yet see. Beyond the live issues lies the **fog of war** — the dim view of decisions and investigations you can tell are coming but can't yet pin down, because they hang on questions still open. Resolving an issue clears the fog ahead of it, graduating whatever's now specifiable into fresh issues — one at a time, until the way to the destination is clear and no open issues remain.

The map's **Not yet specified** section is where that dim view is written down: the suspected question, the area to revisit later. It's the undiscovered frontier _toward_ the destination — everything here is in scope, just not sharp enough to write as an issue. Write as loosely or as fully as the view allows; it doubles as a signpost for whoever reads where the effort is headed.

**Fog or issue?** The test is whether you can state the question precisely now — _not_ whether you can answer it now.

- **Issue when** the question is already sharp — even if it's blocked and you can't act on it yet.
- **Not yet specified when** you can't yet phrase it that sharply. Don't pre-slice the fog into issue-sized pieces: it's coarser than an issue, and one patch may graduate into several issues, or none, once the frontier reaches it.

**Not yet specified** excludes what's already decided (Decisions so far), what's already a live issue, and what's out of scope (the next section).

## Out of scope

Fog only ever gathers _toward_ the destination. The destination fixes the scope, so work beyond it is **out of scope** — it isn't fog, and it doesn't belong in **Not yet specified**. It gets its own **Out of scope** section on the map: work you've consciously ruled out of _this_ effort. Scope, not sharpness, lands it here.

Out-of-scope work never graduates — the frontier stops at the destination — so it returns only if the destination is redrawn, and then as a fresh effort, not a resumption.

Ruling something out of scope is a scoping act, not a step on the route. When an issue that already exists turns out to sit past the destination — mis-scoped in while charting, or exposed by a resolution — **close it**, with a Resolution that says why it is out of scope (a closed issue is unambiguously off the frontier), and leave one line in the **Out of scope** section: the gist plus why, naming the closed issue. It stays out of **Decisions so far**, which records the route actually walked — a scope boundary isn't a step on it.

## Invocation

Two modes. Either way, **never resolve more than one issue per session** — with the exception of research issues.

### Chart the map

User invokes with a loose idea.

1. **Name the destination.** Pin down what this map is finding its way to — the spec, decision, or change. Ask the user to run `/grill` if it needs real settling; the destination fixes the scope, so it comes first.
2. **Map the frontier.** Ask the user for a second, **breadth-first** pass: fan out across the whole space rather than deep on any one thread, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog** — the way to the destination is already clear, the whole journey small enough for one session — you don't need a map. Stop and ask the user how they'd like to proceed.
3. **Create the map**: Destination and Notes filled in, Decisions-so-far empty, the fog sketched into **Not yet specified**.
4. **Create the issues you can specify now** as children of the map — then fill in their `blocked_by` fields in a **second pass**, once every issue has an ID to point at. Wiring sorts them into the frontier and the blocked; everything you can't yet specify stays in the fog — the **Not yet specified** section.
5. **Fire the research subagents.** For each research issue you just created, spin up a `/research` subagent to resolve it in parallel. It saves its findings in the issue's attachment subfolder and links them from the issue.
6. Build, commit, and push QuestLog, then stop — charting is one session's work; it hand-resolves nothing.

### Work through the map

User invokes with a map (its ID, such as `QL-80`, or its file). An issue is **optional** — without one, you pick the next decision, not the user.

1. Load the **map** — the low-res view, not every issue body.
2. Choose the issue. If the user named one, use it. Otherwise take the first frontier issue in ID order.
3. Resolve it — **zoom as needed**: read the full body of any related or closed issue on demand; invoke the skills the `## Notes` block names. If in doubt, ask the user to run `/grill`. When an issue closes on a real trade-off, hand off to `adr`; when it closes by settling what a word means, hand off to `domain-language`.
4. Record the resolution: write the answer in the issue's **Resolution** section, **close** the issue as the README says (when a PR resolves a Task issue, its number goes in `prs`), and **append a line** to the map's Decisions-so-far. Set the map's `updated` date too.
5. Add newly surfaced issues (create, then wire); graduate any fog the answer has made specifiable, clearing each graduated patch from **Not yet specified** so it lives only as its new issue. If the answer reveals an issue — this one or another — sits beyond the destination, **rule it out of scope** rather than resolving it on the route. If the decision invalidates other parts of the map, update those issues, or close them with a Resolution that says the decision replaced them. QuestLog never deletes an issue.
6. Build, commit, and push QuestLog.
