# Release Needs a Pushed HEAD

> **Amended by [ADR 0005](0005-release-allows-a-stale-head.md)** — the pull request's head may also descend from the worktree's `HEAD`, so a worktree left behind by a teammate's push can still be released.

`/dispatch release` removes a worktree whose work is not merged, so a worktree waiting on review, or abandoned, does not sit on the machine. It removes one only when a pull request for its branch, in any state, has the worktree's `HEAD` as its head commit, the worktree has no uncommitted changes, and no agent in it is working or blocked. The commit match proves GitHub holds every commit, so deleting the local branch with `-D` loses nothing.

## Consequences & Tradeoffs

This extends [ADR 0003](0003-dispatch-cleans-up-via-prune.md), where a pull request closed without merging never qualifies. Release allows it because the user names the worktree, or says `release all`, and confirms the list before anything is removed. Clean still removes without asking, so it keeps its stricter rule.

The worktree's databases are dropped, and a resumed worktree starts with new ones. Resuming uses `wt herdr-resume`, because `wt herdr` passes `--create`, which ignores the remote branch and starts a new one from `main`.
