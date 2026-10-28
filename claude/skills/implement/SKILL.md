---
name: implement
description: Build an Asana task end to end — branch, TDD, review, PR, and the review feedback loop.
argument-hint: "Asana task URL, or a spec path"
license: MIT
disable-model-invocation: true
metadata:
  forked-from: https://github.com/mattpocock/skills
  forked-skill: implement
  forked-on: "2026-08-03"
  upstream-copyright: Copyright (c) 2026 Matt Pocock, MIT
  editor: Mike Zornek
  note: substantially rewritten — upstream was five lines with no branch, PR, or review-response steps
---

Take a piece of work from an Asana task to a pull request with its review threads answered. The steps are ordered and each has a bar to clear; do not run ahead of them.

## 1. Read the work

The argument is an Asana task URL, or a path to a spec. For a task, read its description, subtasks, and dependencies with `get_task`, **and every comment** with `get_task_stories`, as the global Asana rule says. Decisions get made in comment threads, and a read of the description alone misses them.

If the work is not settled enough to build, stop and say so. `/grill` settles it; `/to-tickets` splits it when it is settled but too big for one branch. Neither is something to push through.

## 2. Branch

You are in a linked worktree when the two paths that `git rev-parse --path-format=absolute --git-dir --git-common-dir` prints differ. A worktree keeps the branch it was made with and serves one pull request, so check the branch's PR first:

- **The PR has merged or closed:** stop, and ask the user to open a new worktree for this work.
- **The PR links a different task from the one you were given:** stop and ask the same way. Each task gets its own worktree.
- **No PR, or the PR is still open, for this task:** work on the current branch, and skip the commands below.

In the primary checkout, branch off updated `main`:

```
git checkout main && git pull --ff-only
git checkout -b zorn/<short-slug>
```

The slug is a few kebab-case words taken from the task's name, not the whole name. The task URL goes in the PR body, and that link is what ties the work back to its task.

## 3. Build with TDD

Hand off to `tdd` and stay inside its loop. Its rules bind here: seams confirmed with the user before any test is written, one vertical slice at a time, red before green.

Run the project's typecheck and the test file under change as you go; run the full suite once before moving on.

## 4. Review before the PR exists

Run `diff-review` against `main`. Reviewing here rather than after pushing is the whole point of the ordering — the diff is still cheap to change.

Apply what it recommends. Findings arrive as a numbered decision list, and that skill's contract governs how the user's reply is read.

`/code-review ultra` is Anthropic's deeper multi-agent cloud pass, and is **user-triggered only** — this skill cannot launch it. When a change is large or risky enough to want it, say so and let the user type it, rather than proceeding as though the pass happened. This repo's own reviewer is named `diff-review` precisely so that the two invocations cannot be confused.

## 5. Push and open the PR

Push the branch, then hand off to `pull-request`. It owns the body and the opening — the story, the flavor, the reviewer's evidence, and the checks that run before `gh pr create`. Pass it the task URL so it can read the work behind the change.

One thing it needs from here that it cannot see on its own: carry over anything `diff-review` surfaced in step 4 that you declined, since a declined finding is a judgment call the reviewer might overturn.

## 6. Work the review feedback

Reviews come from people once the user marks the draft ready, and they can arrive hours later. Watch the checks and any early comments — **as a `Monitor` command, never as a blocking foreground call**:

```
Monitor(
  description: "PR feedback and checks on #<pr-number>",
  command: "WATCH_SETTLE=1 WATCH_SETTLE_REVIEWS=0 ~/.claude/skills/implement/scripts/watch-pr-feedback.sh <pr-number>",
)
```

The script polls until told to stop, so running it in the foreground buys nothing and burns the whole tool timeout while showing you nothing. `Monitor` turns each new item into a notification that arrives while you keep working. `WATCH_SETTLE=1` with `WATCH_SETTLE_REVIEWS=0` ends the watch once the checks finish and the PR goes quiet, instead of waiting for a review that may not come today.

When the user says reviews have arrived, run the same command again. It reports only what it has not reported before.

It emits one line per new inline review comment, review summary, or PR comment, and one per check that fails or is canceled — so a crashed job does not read as silence. It remembers what it has already reported, so nothing is announced twice, which also means a second run against the same PR is silent until you delete its state file. Progress goes to stderr, so `Read` the monitor's output file to see elapsed time and the check rollup without waiting for an event.

**Evaluate every comment before acting on it.** Declining a comment is a legitimate outcome; ignoring one is not.

Reply in each thread:

```
gh api repos/<owner>/<repo>/pulls/<pr>/comments/<comment-id>/replies -f body="$(cat reply.md)"
```

Write the body to a file and pass it with `$(cat …)` — an inline body loses backticks in fish, silently.

A reply is a sentence or two saying what you did or why you did not. "Fixed in `<sha>`" is complete; so is a declined finding with its reason. An unanswered thread reads as one you missed.

## 7. Done

The work is done when checks are green, the branch is pushed, and every review thread that has arrived has a reply. While the PR is still a draft, say so, and say that `gh pr ready <n>` asks for peer review.

Report which comments you applied and which you declined. A summary listing only the fixes hides the judgment calls, and those are the ones worth the user's attention.

Say what the change needs beyond merging — a re-link, a reload, a restart, or a doc that now describes it wrongly — or that it needs nothing. The user should not have to ask.

Then remind the user they may want to run `/code-review`. It hunts correctness bugs, which none of `diff-review`'s axes target — so it is worth a look even though step 4 already reviewed the diff. Leave it as a line in the report, not a step to run yourself; the user triggers it when they are ready.

Marking the PR ready and merging it are the user's calls. Leave both to them.
