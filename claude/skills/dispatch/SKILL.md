---
name: dispatch
description: Dispatch parallel agents into worktrunk worktrees from the primary checkout, one per Asana task or QuestLog issue, report on them, and clean up merged ones.
argument-hint: "Asana task URLs or QuestLog IDs to launch, or \"status\", or \"clean\""
disable-model-invocation: true
metadata:
  forked-from: https://github.com/zorn/dotfiles
  forked-skill: dispatch
  forked-on: "2026-11-16"
  upstream-copyright: Copyright (c) 2026 Mike Zornek, MIT
  note: work items are Asana tasks and QuestLog issues, and branches are zorn/<slug>
---

You are the dispatcher. You send agents out to their own worktrees, know where each one is, and bring the finished ones back. Your work is coordination; each work item's work belongs to its agent.

A **work item** is an Asana task, named by its URL, or a QuestLog issue, named by its ID such as `QL-90`. Pick the mode from the argument: one or more work items, in any mix, mean **Launch**; `status` means **Status**; `clean`, or `clean up`, means **Clean**. With no argument, run Status.

## Rules for every mode

- **Read `herdr --skill` before your first `herdr` command.** Herdr maintains it, and it covers agent readiness, `blocked` states, and timeouts.
- **Stay in the primary checkout.** Run every command from it, and never `cd` your shell into a worktree ([herdrdev/herdr#4293](https://github.com/herdrdev/herdr/issues/4293)). The global Worktrees rule says how to detect a linked worktree. If you are in one, stop and say so.
- **Follow the runbook.** [`worktrunk/README.md`](https://github.com/zorn-rxv/dotfiles/blob/main/worktrunk/README.md) covers `wt herdr`, `wt remove`, and what to do when a removal stops.
- **Ask Herdr about agents.** Run `herdr agent list` before you say anything about an agent. It gives each agent's `cwd` and `agent_status`. Your memory of what you started is not evidence of what is running.
- **Refresh before you report a remote branch.** Run `git fetch --prune` before you say whether a branch exists on GitHub. `gh` reads pull requests from GitHub directly.

## Launch

1. **Check the repo isolates worktrees.** Run `wt hook show pre-start`. It must list a hook besides the global `profile`, from a `[projects]` section in the user config or from the repo's own `.config/wt.toml`. Without one, every agent shares the primary checkout's port and databases, so stop and say so.

2. **Check each work item belongs to this repo.** An Asana task must be in the project that the global Asana table lists for this repo; read its `memberships` with `get_task`. A QuestLog issue must have a file in `~/QuestLog/<repo>/` whose frontmatter `id` matches. If one belongs elsewhere, stop, name it, and launch none of the batch.

3. **Check the primary checkout and Postgres.** The checkout must be on `main` with a clean tree; if not, stop and say what is wrong. Run `git pull --ff-only`, so every worktree starts from the latest `main`. Then run `pg_isready`. Each worktree creates its databases in a background step, which fails without telling anyone when Postgres is down.

4. **Plan, and wait for "go".** Read each work item's name and state: `get_task` for a task, the frontmatter for a QuestLog issue. Give each one:

   - **An agent name** that carries the work item: `ql-90` for a QuestLog issue, and `asana-` plus the last six digits of the GID for a task.
   - **A branch** named `zorn/<slug>`, as `/implement`'s Branch step names it. The slug is a few kebab-case words from the work item's name.

   Show one row per work item with its ID, name, agent name, and branch. Mark a row "skip" when its task is completed or its issue is closed, or when it is already dispatched. It is already dispatched when any of these exists: the planned branch (`git branch --list <branch>`, `git worktree list`), a live agent with the same name (`herdr agent list`), or an open pull request whose body names the task URL or the QuestLog ID (`gh pr list --state open --search "<url or ID> in:body"`). A fresh slug can differ from an earlier run's, so the branch check alone misses a re-dispatch.

   The user may edit any branch name in the table. `/implement` keeps the branch its worktree was made with, so the name chosen here is final. Wait for "go" before you create anything, then launch only the rows not marked "skip".

5. **Create each worktree.** Run `wt herdr <branch>`. Its last line is JSON. Read the new pane's ID from `.result.root_pane.pane_id`.

6. **Start each agent** under its agent name:

   ```sh
   herdr agent start ql-90 --kind claude --pane <pane-id>
   herdr agent prompt ql-90 "/implement QL-90" --wait --until working --until blocked
   ```

   For a task, the prompt is `/implement <task URL>`. The prompt returns once the agent starts its turn. Each agent pauses when `/implement` needs a decision, so `blocked` is expected, at once or later.

Launch is done when `herdr agent list` shows one agent per launched work item, each with its `cwd` in its own worktree. Report the Status table.

## Status

Status runs once for each request. Build one row per linked worktree from `git worktree list`:

| Column | Source |
| --- | --- |
| Label | `herdr workspace list`, matched on `worktree.checkout_path` |
| Branch | `git worktree list` |
| Agent | `herdr agent list`, matched on `cwd`; its name names the work item; "none" when no agent matches |
| Pull request | `gh pr list --head <branch> --state all --json number,state,createdAt`; the newest one |
| Checks | `gh pr checks <number>`, when a pull request exists |

Status is done when every linked worktree has a row with all five columns filled, or marked "none".

## Clean

[ADR 0003](https://github.com/zorn-rxv/dotfiles/blob/main/docs/adr/0003-dispatch-cleans-up-via-prune.md) records why removal needs both checks below.

1. **Refresh `main`.** The primary checkout must be on `main` with a clean tree; if not, stop and say what is wrong. Run `git pull --ff-only`. worktrunk compares a branch against the local `main` for `same commit as`, so a stale `main` misreads it.

2. **Find the candidates.** A worktree qualifies only when git and GitHub both say it is finished:

   - **Git:** it appears in `wt step prune --dry-run --min-age 0s --format=json` with `kind` `worktree`. That means its work is in `main`.
   - **GitHub:** a pull request for its branch is `MERGED`, and that pull request's `headRefOid` equals the worktree's `HEAD`. Use `gh pr list --head <branch> --state merged --json headRefOid` and `git -C <path> rev-parse HEAD`.

   A worktree with no commits also appears in prune, as `same commit as`, or as `ancestor of` once `main` moves on. Its agent is just starting. Only a merged pull request at the worktree's own `HEAD` tells it apart, because a follow-up branch can reuse a merged branch's name. Leave any worktree that fails either check, including one whose pull request lookup fails, and report it with its reason.

3. **Remove.** Show the list, then remove each candidate without asking: its work is already in `main`, and `wt remove` refuses uncommitted changes. For each one in turn, check `herdr agent list` first. Skip it when its agent is `working` or `blocked`, because removal closes the workspace and kills the agent, along with any question it is waiting on. Otherwise run `wt remove --foreground <branch>`, so its result is known before you go on. When `wt remove` refuses, follow its message. If a Herdr workspace stays open after a removal, close it with `herdr workspace close <id>`.

Clean is done when every candidate is removed or reported with its reason for staying. Report the skipped worktrees, so the user knows to run `/dispatch clean` again.
