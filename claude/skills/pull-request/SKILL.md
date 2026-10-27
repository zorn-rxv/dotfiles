---
name: pull-request
description: Tell the story of a change in its pull request — the problem, the fix, and what deserves the reviewer's attention — then open it. Use when a change is ready for a PR, when an existing PR body needs rewriting, and when another skill needs a PR opened.
license: MIT
metadata:
  origin: https://github.com/zorn/dotfiles/issues/28
  research: https://github.com/zorn/dotfiles/blob/main/docs/research/pr-writing-skill.md
  editor: Mike Zornek
---

# Pull Request

A PR body has one reader: someone without your context, who will skim anything long. **Tell the story** — what was wrong, what you did about it, and what they should push back on — in about 250 words.

## 1. Read the change and name its flavor

`git diff main...HEAD` for the change. For the Asana task behind it, read the description and every comment, as the global Asana rule says. Decisions get made in comment threads, and a read of the description alone misses them.

Three flavors, told apart by what the reviewer cannot get from the diff alone:

- **Behavior change** — the software now does something different. The reviewer needs to *see* it behave, so this is the flavor that carries a demo path and screenshots.
- **Artifact** — the change commits a document: research, an ADR, a spec, a prototype. The artifact *is* the diff, so reading it is the review. The body gives the headline of each finding and the decision it changes, not the findings themselves.
- **Mechanical** — dependency bumps, generated output, sweeping renames. The reviewer needs the verification evidence and whatever you did by hand against the pattern.

Name the flavor before drafting. It decides which moves below apply.

## 2. Tell the story

Four moves, in order. Name each heading after its own content — `Three findings that change the export format`, `What changes in a browser` — rather than reaching for `Summary` or `What changed`.

1. **Open with what this is and where it sits.** One or two sentences under no heading: the change, and the arc it belongs to. Link the PR it follows from, if any, and say what it leaves for later. The task link goes above this paragraph, as the checks below require.
2. **Disclose the risk.** Say what could break and for whom, and how to undo it — "A revert undoes this", or "A revert won't undo this: the migration drops `legacy_notes`." Name what a revert would not restore. Then say what did *not* change and what the suite says — "No production behavior changes here; the suite is unchanged at 327 passing." Keep the disclosure short: it is what a reviewer leans on to decide how hard to look.
3. **Carry the substance under content-named headings.** Lead each with a claim rather than a topic. Cite `path:line` for anything the reviewer would otherwise go hunting for, and link it when the file lives in this repo.
4. **End with `Worth a reviewer's attention`.** Bold-led bullets, one per judgment call the reviewer might overturn — a skipped lint rule, a deviation from what the task specified, a trade-off you picked a side on. This is the section that earns the review; write it even when the list has one item.

Alternatives you considered belong here as a headline and a link to where they were argued. The reader who wants the full case follows the link; everyone else needs the sentence.

## 3. Show it working

Every flavor gets a picture when it has a shape to show. A behavior change gets a demo path and a screenshot; a change with nothing to screenshot gets a sketch.

**The demo path** costs nothing and goes stale slower than an image. Take the port from the project's config and the route from the router's own generated list (`mix phx.routes` in a Phoenix app) rather than reading the router by eye, then say what to click. Where the repo already documents how to inspect a running app, link that document rather than restating it.

**The screenshot is the part reviewers actually look at, so a visible change gets one.** Capture the new state with browser automation against the running app, and reference it in the body by its absolute path. `gh` resolves a relative path from the directory it runs in, not the body file's, so a relative reference breaks as soon as the two differ. Step 4 uploads it with `gh --attach`, which rewrites the reference in place and keeps its position and alt text. The flag needs `gh` 2.99.0 or later, so check `gh --version` before capturing anything. [reference/images.md](reference/images.md) covers what the upload does, the two forms that silently fail, and the theme-aware light/dark pair that `--attach` cannot serve.

Include a **before** shot whenever it is cheap — the base ref is already built, or the change is confined to markup and styles. When capturing it would mean a cold rebuild of the base ref, describe the old state in a sentence and show the new one alone. Seed both captures from the same fixtures, so the difference in the image is the change and nothing else. If the app renders differently across clients, say which one you captured.

Stack the pair vertically rather than side by side — two half-width images make the difference between them harder to see, which is the one thing the pair exists to show.

```markdown
**Before**

![Settings panel, before](<scratch>/before.png)

**After**

![Settings panel, after](<scratch>/after.png)
```

**A screen recording** earns its place when the change is an interaction rather than a state — a drag, a transition, a multi-step flow. Save it as mp4, mov, or webm and put the bare reference on a paragraph of its own, `![](<scratch>/demo.mp4)`, which GitHub renders as an inline player. Video takes no alt text, so say what it shows in the sentence above it. Size limits are in [reference/images.md](reference/images.md).

**A runtime transcript** earns its place when the change's value is a return shape or an edge case that reads better as a session than as a test name. Compose it from `mix run -e` output against seeded fixtures. Piping into `iex -S mix` prints the prompt and the result with the input missing — `iex(1)> 2` for an input of `1 + 1` — so the transcript it produces misrepresents what was typed.

**A sketch** is the picture for a change with nothing to screenshot — a refactor, a new control flow, a file reshuffle — whatever its flavor. Use the smallest one that makes the point, placed beside the sentence it supports: a call tree for control flow, a shallow file tree for a layout change, a Mermaid diagram for data flowing between components, or a `diff` of any of these when the point is what moved. Keep only the calls, files and boundaries the point needs.

## 4. Check, then open

Mechanical checks, no judgment in any of them:

- **Title follows the repo's convention.** When a workflow in `.github/workflows/` runs `amannn/action-semantic-pull-request`, the title must match its `types` list and `subjectPattern`; read them from that workflow. With no such workflow, write a plain sentence in the style of the repo's recent PR titles (`gh pr list --state merged --limit 10`).
- **Task link present** — the Asana task URL alone on the first line of the body.
- **Paragraphs are single unwrapped lines.**
- **Every local image or video path in the body is absolute and gets an `--attach` for the same file.** An unmatched reference ships as a broken image, and `gh` still exits 0.

Open it as a **draft**, always. A draft says the PR is not yet asking for review, which leaves the user room to tinker before peers are pulled in. Marking it ready with `gh pr ready` is the user's call.

Open it with a body file rather than an inline `--body`, which loses backticks in fish, silently. Add one `--attach` per referenced file; rewriting an existing PR's body takes the same flags on `gh pr edit <n>`:

```
gh pr create --draft --title "<title>" --body-file <path> --attach <scratch>/before.png --attach <scratch>/after.png
```

A failed attachment still creates the PR and prints its URL, but `gh` exits non-zero. Recover with `gh pr edit <n> --body-file <path>` and every `--attach` again, since the original body file still holds the local paths.

Report the PR as a draft, and say that `gh pr ready <n>` asks for peer review once the user is happy with it. Reviews come from people after that, so the work is not finished when the draft exists. `implement` step 6 owns the review loop and its script.
