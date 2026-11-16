# Worktrunk, Not Herdr, Creates

Parallel agents on verify-doctor each get their own git worktree. worktrunk (`wt`) creates and removes those worktrees, and Herdr only attaches to one after `wt` has made it. worktrunk already handles the plumbing a worktree needs: copying build state, hashing a port per worktree, naming databases safely, and running a teardown hook before removal. Creating worktrees from Herdr would mean rebuilding all of that by hand.

## Consequences & Tradeoffs

The cost is one rule: create and remove worktrees only through `wt`. A worktree made from Herdr's TUI, or removed with `git worktree remove`, skips the hooks. It then shares the primary checkout's port and databases, or leaves its own databases behind. The `wt herdr` alias in [`worktrunk/config.toml`](../../worktrunk/config.toml) keeps the two tools in that order: it creates the worktree with `wt`, then opens it in Herdr.

This follows [zorn/dotfiles ADR 0003](https://github.com/zorn/dotfiles/blob/main/docs/adr/0003-worktrunk-not-herdr-creates.md), which made the same choice for personal Phoenix apps after comparing Herdr's `worktree.created` hook with worktrunk's built-in plumbing.
