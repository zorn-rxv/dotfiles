---
name: dispatch
description: Dispatch parallel agents into worktrunk worktrees from the primary checkout, one per Asana task, QuestLog issue, or pull request, report on them, release ones whose work is on GitHub, and clean up merged ones.
argument-hint: "Asana task URLs, QuestLog IDs, or PR numbers or URLs to launch, or \"status\", \"release <IDs, PRs, or all>\", or \"clean\""
disable-model-invocation: true
license: MIT
metadata:
  forked-from: https://github.com/zorn/dotfiles
  forked-skill: dispatch
  forked-on: "2026-11-16"
  upstream-copyright: Copyright (c) 2026 Mike Zornek, MIT
  note: work items are Asana tasks and QuestLog issues, and branches are zorn/<slug>
---

You are the dispatcher. You send agents out to their own worktrees, know where each one is, and bring the finished ones back. Your job is coordination; each work item belongs to its agent.

A **work item** is an Asana task, named by its URL, or a QuestLog issue, named by its ID such as `QL-90`. A **PR row** launches an agent on a pull request, named by its number or URL. A work item gets an agent that runs `/implement`. A PR row gets an agent that waits for instructions. Use one to review a teammate's pull request with the app running, or to work a second round on your own. Pick the mode from the argument:

- **Launch:** one or more work items or PR rows, in any mix.
- **Status:** `status`, or no argument.
- **Release:** `release`, followed by work items, pull requests, branches, or `all`.
- **Clean:** `clean`, or `clean up`.

## Rules for every mode

- **Read `herdr --skill` before your first `herdr` command.** Herdr maintains it, and it covers agent readiness, `blocked` states, and timeouts.
- **Stay in the primary checkout.** Run every command from it, and never `cd` your shell into a worktree ([herdrdev/herdr#4293](https://github.com/herdrdev/herdr/issues/4293)). The global Worktrees rule says how to detect a linked worktree. If you are in one, stop and say so.
- **Follow the runbook.** [`worktrunk/README.md`](https://github.com/zorn-rxv/dotfiles/blob/main/worktrunk/README.md) covers `wt herdr`, `wt remove`, and what to do when a removal stops.
- **Ask Herdr about agents.** Run `herdr agent list` before you say anything about an agent. It gives each agent's `cwd` and `agent_status`. Your memory of what you started is not evidence of what is running.
- **Refresh before you report a remote branch.** Run `git fetch --prune` before you say whether a branch exists on GitHub. `gh` reads pull requests from GitHub directly.

## Launch

1. **Check the repo isolates worktrees.** Run `wt config show`. The repo isolates worktrees in either of two cases:

   - **The user config has a section for it:** a `[projects."<pattern>".pre-start]` section whose pattern matches the Identifier under PROJECT CONFIG. A `*` in the pattern matches any run of characters.
   - **The repo has its own config:** PROJECT CONFIG shows a `.config/wt.toml` with a `pre-start` hook.

   `wt hook show` cannot settle this, because it lists global and per-project user hooks together. Without either case, every agent shares the primary checkout's port and databases, so stop and say so.

2. **Check each work item belongs to this repo.** An Asana task must be in the project that the global Asana table lists for this repo; read its `memberships` with `get_task`. A QuestLog issue must have a file in `~/QuestLog/<repo>/` whose frontmatter `id` matches. If one belongs elsewhere, stop, name it, and launch none of the batch. A PR row's repo is checked in step 4.

3. **Check the primary checkout and Postgres.** The checkout must be on `main` with a clean tree; if not, stop and say what is wrong. Run `git pull --ff-only`, so every worktree starts from the latest `main`. Then run `pg_isready -h localhost`, and stop if Postgres is not accepting connections. Keep the `-h`. Without it, `pg_isready` tries the Unix socket in `/tmp`. This machine's Postgres listens only on TCP, so the socket check reports "no response" while Postgres is up. Each worktree creates its databases in a background step, which fails without telling anyone when Postgres is down.

4. **Plan, and wait for "go".** Read each work item's name and state: `get_task` for a task, the frontmatter for a QuestLog issue. Give each one:

   - **An agent name** that carries the work item: `ql-90` for a QuestLog issue, and `asana-` plus the last six digits of the GID for a task.
   - **A branch** named as `/implement`'s Branch step names it.

   Show one row per work item with its ID, name, agent name, and branch. Mark a row "skip" when its task is completed or its issue is closed, when its branch or agent name repeats an earlier row's, or when it is already dispatched. It is already dispatched when any of these exists:

   - **The planned branch:** `git branch --list <branch>`, `git worktree list`.
   - **A live agent with the same name:** `herdr agent list`.
   - **An open pull request of yours whose body names the work item:** `gh pr list --state open --author @me --search '"<GID or ID>" in:body' --json number,headRefName`. Search for the task's GID, not its URL, because Asana writes one task's URL in several forms. Quote the term, so search does not split `QL-90` into `QL` and `90`. Keep `--author @me`: a teammate's pull request can name the same task, and resuming it would push to their branch. One exception: when no worktree exists for that pull request's `headRefName` and no live agent has the row's agent name, the work item is **released**, not dispatched. A local branch may still exist, because a plain `wt remove` keeps an unmerged branch. When that branch has commits origin lacks, mark the row "skip" and name the branch. Otherwise mark its row "resume", not "skip", and use the pull request's `headRefName` as its branch. Say on the row that the resumed worktree gets new databases, so dev data from before the release is gone. Check every such pull request, not only the first. Skip the row when any one is still dispatched, or when more than one was released, because then no single branch is the one to resume. A released pull request wins over the planned-branch check: its branch can be the planned branch, because a re-dispatch can derive the same slug.

   A lookup that fails stops the check. Never read a failed `herdr`, `git`, or `gh` call as "nothing found", because that launches a second agent onto dispatched work.

   A fresh slug can differ from an earlier run's, so the branch check alone misses a re-dispatch.

   [`scripts/preflight.sh`](scripts/preflight.sh) `<branch> <agent name> <GID or ID>` runs every check in this step, including the GitHub name check below, and prints a JSON verdict: `clear`, `skip`, `resume`, or `rename`, with its reason and the branch to launch. Run it once per row. The rules here say what each verdict means.

   For a row that is neither skipped nor resumed, check that the planned branch name is unused on GitHub too: `git ls-remote --heads origin <branch>` and `gh pr list --head <branch> --state all`. A work item whose earlier pull request closed or merged gets the same slug again. Reusing it would branch from `main` beside the old remote branch, and `/implement` would find the old pull request and stop. When the name is taken, pick a different slug, for example by adding a word from the work item's name.

   For a PR row, run `scripts/preflight.sh --pr <number or URL>` instead. Its row uses the pull request's branch and the agent name `pr-<number>`. Its verdict is one of three:

   - **`refuse`:** the pull request belongs to another repo, is not open, or comes from a fork. Stop, name it, and launch none of the batch.
   - **`skip`:** its worktree already exists here, its local branch has commits origin lacks, or its agent is live.
   - **`pr`:** launch it. Say on the row whether `mine` is true, because the agent's prompt depends on it.

   To get `/implement`'s review feedback loop on your own pull request, name its work item.

   The user may edit any branch name in the table, except on a "resume" row or a PR row, whose branch must match its pull request. `/implement` keeps the branch its worktree was made with, so the name chosen here is final. Wait for "go" before you create anything, then launch only the rows not marked "skip".

5. **Create each worktree.** Run `wt herdr <branch>`. For a "resume" row or a PR row, run `wt herdr-resume <branch>` instead. `wt herdr` passes `--create`, which ignores the remote branch and starts a new one from `main` without the pull request's commits. When preflight reported `fast_forward: true`, first run `git fetch origin <branch>:<branch>`, so `wt herdr-resume` builds on the pull request's commits rather than a stale local branch. Either command's last line is JSON. Read the new pane's ID from `.result.root_pane.pane_id`.

6. **Start each agent** under its agent name:

   ```sh
   herdr agent start ql-90 --kind claude --pane <pane-id>
   herdr agent prompt ql-90 "/implement QL-90" --wait --until working --until blocked
   ```

   For a task, the prompt is `/implement <task URL>`. The prompt returns once the agent starts its turn. Each agent pauses when `/implement` needs a decision, so `blocked` is expected. A resumed agent finds its open pull request, and `/implement` sends it straight to the review feedback.

   A PR row's prompt names no skill. The user decides what runs, and `/code-review` in particular needs an effort level that only the user picks:

   ```sh
   herdr agent prompt pr-123 "This worktree holds PR #123 (<title>) by <author>, on branch <branch>. Wait for instructions." --wait --until working --until blocked
   ```

   When `mine` is false, add "Do not commit or push." to the prompt. The branch belongs to a teammate.

Launch is done when `herdr agent list` shows one agent per launched work item or PR row, each with its `cwd` in its own worktree. Report the Status table.

## Status

Build the table once for each request, and do not poll. Run [`scripts/worktree-status.sh`](scripts/worktree-status.sh), which prints one JSON row per linked worktree, and render each row as a table row:

| Column | Field |
| --- | --- |
| Label | `label` |
| Branch | `branch` |
| Agent | `agents`, named with their status; the agent name identifies the work item or pull request; "none" when empty |
| Pull request | `pr`, or "none" |
| Checks | `checks`, the counts by bucket, when a pull request exists; "unavailable" when the lookup failed |
| Releasable | `releasable` |

Status is done when every linked worktree has a row with all six columns filled, or marked "none".

## Release

Release removes a worktree whose work is safe on GitHub, so the user can move on while its pull request waits. The pull request and the remote branch stay. Launch resumes it later. [ADR 0004](https://github.com/zorn-rxv/dotfiles/blob/main/docs/adr/0004-release-needs-a-pushed-head.md) records why Release, unlike Clean, removes unmerged work.

1. **Find the worktrees.** The argument names work items, branches, pull requests, or `all`. A pull request's number or URL names its `headRefName`, from `gh pr view <number or URL> --json headRefName,url,isCrossRepository`. Refuse a pull request from another repo or a fork, as Launch does, because its branch name can match an unrelated worktree here. For a work item, search as Launch step 4 does, with `--author @me`, but with `--state all --json number,state,headRefName,headRefOid`. The search can return several pull requests, such as an earlier merged one. Use the one whose `headRefName` has a linked worktree in `git worktree list`. When none does, report the work item as not releasable. `all` means every linked worktree that passes the check in step 2. Never release the primary checkout.

2. **Check each one.** A worktree is releasable only when all of these hold:

   - **A pull request holds its work:** a pull request for its branch, in any state, has a `headRefOid` that equals the worktree's `HEAD` or descends from it. That proves GitHub has every commit. [ADR 0005](https://github.com/zorn-rxv/dotfiles/blob/main/docs/adr/0005-release-allows-a-stale-head.md) records why a pull request that has moved on still counts.
   - **Its tree is clean:** `git -C <path> status --porcelain` prints nothing.
   - **Its agent is idle:** every agent in `herdr agent list` with its `cwd` in the worktree is `idle` or `done`. Herdr reports `unknown` when it cannot tell, often on a fresh pane, so `unknown` and any other status count as not idle. Removal kills the agent, along with any question it is waiting on.

   `scripts/worktree-status.sh <branch>` applies all three, and its `releasable` field is `yes` or the first reason that fails. Leave any worktree that fails a check, and report the reason. Never push, commit, or stash to make one pass, and never pass `-f`. Those choices are the user's.

3. **Wait for "go", then remove.** Show the list, and say that releasing drops each worktree's dev and test databases. Wait for "go", because `-D` deletes local branches that are not merged. Then, for each one in turn, run step 2's three checks again with `scripts/worktree-status.sh <branch>`. An idle agent can wake during the wait, for example on review feedback, and commit without pushing. A clean tree does not stop `wt remove`, so `-D` would delete that commit. Skip any worktree that now fails, and report why. Otherwise run `wt remove --foreground -D <branch>`. When `wt remove` refuses, follow its message. If a Herdr workspace stays open after a removal, close it with `herdr workspace close <workspace_id>`, using the `workspace_id` from the row the re-check printed. Labels can repeat, so never close one by its label.

Release is done when every named worktree is removed or reported with its reason for staying. For each released worktree whose pull request is open, tell the user that `/dispatch <work item>` resumes it, or `/dispatch <PR>` for a PR row.

## Clean

[ADR 0003](https://github.com/zorn-rxv/dotfiles/blob/main/docs/adr/0003-dispatch-cleans-up-via-prune.md) records why removal needs both checks below.

1. **Refresh `main`.** The primary checkout must be on `main` with a clean tree; if not, stop and say what is wrong. Run `git pull --ff-only`. worktrunk compares a branch against the local `main` for `same commit as`, so a stale `main` misreads it.

2. **Find the candidates.** A worktree qualifies only when git and GitHub both say it is finished:

   - **Git:** it appears in `wt step prune --dry-run --min-age 0s --format=json` with `kind` `worktree`. That means its work is in `main`.
   - **GitHub:** at least one merged pull request for its branch has a `headRefOid` equal to the worktree's `HEAD`. Use `gh pr list --head <branch> --state merged --json headRefOid`, and compare every result with `git -C <path> rev-parse HEAD`.

   A worktree with no commits also appears in prune, as `same commit as`, or as `ancestor of` once `main` moves on. Its agent has likely just started. Only a merged pull request at the worktree's own `HEAD` tells a finished worktree from a new one, because a follow-up branch can reuse a merged branch's name. Leave any worktree that fails either check, including one whose pull request lookup fails, and report it with its reason.

3. **Remove.** Show the list, then remove each candidate without asking: its work is already in `main`, and `wt remove` refuses uncommitted changes. For each one in turn, run `scripts/worktree-status.sh <branch>` first. Skip it unless every agent in its row's `agents` is `idle` or `done`, because removal closes the workspace and kills the agent, along with any question it is waiting on. Otherwise run `wt remove --foreground <branch>`, so its result is known before you go on. When `wt remove` refuses, follow its message. If a Herdr workspace stays open after a removal, close it with `herdr workspace close <workspace_id>`, using the `workspace_id` from that row.

Clean is done when every candidate is removed or reported with its reason for staying. Report the skipped worktrees, so the user knows to run `/dispatch clean` again.
