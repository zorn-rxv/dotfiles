# Dispatch Cleans Up via Prune

`/dispatch` launches agents into verify-doctor worktrees, one per Asana task or QuestLog issue, and later removes the finished ones. It removes a worktree only when two checks agree. A dry run of `wt step prune` must list it, so its work is in `main`. A pull request must have merged from the worktree's own `HEAD`. Prune alone cannot tell a finished worktree from one whose agent just started, and GitHub alone cannot tell whether removing the branch loses work.

## Consequences & Tradeoffs

`--min-age 0s` lets a worktree merged the same day qualify, but it also lists a worktree with no commits yet. Prune reports that one as `same commit as main`, or as `ancestor of` once another agent's PR merges. Removing it would kill an agent just starting there. The merged PR tells the two apart. It must match the worktree's `HEAD` commit, not only its branch name, because a follow-up branch can reuse a merged `zorn/<slug>` name.

GitHub alone was rejected because a merged PR can leave commits behind on its branch, and removal would discard them. A live `wt step prune` was rejected because it cannot leave out a single candidate. A PR closed without merging never qualifies, so its worktree stays until a person decides. A worktree whose agent is working, or blocked on a question, is skipped, because removal closes its Herdr workspace.

This follows [zorn/dotfiles ADR 0006](https://github.com/zorn/dotfiles/blob/main/docs/adr/0006-dispatch-cleans-up-via-prune.md), which settled the same two-check rule for GitHub-issue branches.
