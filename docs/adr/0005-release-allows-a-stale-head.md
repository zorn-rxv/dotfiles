# Release Allows a Stale HEAD

`/dispatch release` now removes a worktree when a pull request's head commit equals the worktree's `HEAD` or descends from it. Before, the two had to be equal. `/dispatch <PR>` opens worktrees on pull requests that teammates keep pushing to, and each push left the worktree behind and impossible to release. Ancestry keeps the guarantee from [ADR 0004](0004-release-needs-a-pushed-head.md), which this amends: GitHub holds every commit in the worktree, so deleting the local branch with `-D` loses nothing.

## Consequences & Tradeoffs

The pull request's head commit must be in the local repo to compare, so `worktree-status.sh` runs `git fetch --prune` first. A head commit that is still missing reads as not holding, which errs toward keeping the worktree.

Clean keeps the equality rule from [ADR 0003](0003-dispatch-cleans-up-via-prune.md). Clean removes without asking, and Release now gives a stale worktree a way out, so Clean has no reason to loosen.

Refreshing a stale review worktree in place was rejected. It would add a third Launch path for one edge case, while a release followed by `/dispatch <PR>` gives the same result.
