# Release Allows a Stale HEAD

`/dispatch release` now removes a worktree when a pull request's head commit equals the worktree's `HEAD` or descends from it. Before, the two had to be equal. `/dispatch <PR>` opens worktrees on pull requests that teammates keep pushing to. Each push left the worktree behind, and Release then refused it. Ancestry keeps the guarantee from [ADR 0004](0004-release-needs-a-pushed-head.md), which this amends: GitHub holds every commit in the worktree, so deleting the local branch with `-D` loses nothing.

## Consequences & Tradeoffs

The comparison needs the pull request's head commit locally. `worktree-status.sh` fetches a missing one from `refs/pull/<n>/head`, not from the branch, because a squash merge can delete the branch while GitHub keeps the pull request ref. When the commit is still missing, the pull request does not count as holding the worktree's `HEAD`, so the worktree stays.

Clean keeps the equality rule from [ADR 0003](0003-dispatch-cleans-up-via-prune.md). Clean removes without asking. Release now gives a stale worktree a way out, so Clean does not need a looser rule.

Refreshing a stale review worktree in place was rejected. It would add a third Launch path for one edge case, while a release followed by `/dispatch <PR>` gives the same result.
