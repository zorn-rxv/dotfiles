# verify-doctor Opts In Locally

verify-doctor is a team repo, and only this machine runs worktrees against it, so its worktree setup lives entirely in this repo. A per-project section in the global worktrunk config runs [`hooks/verify-doctor`](../../worktrunk/hooks/verify-doctor), which writes each worktree's database names and port into the gitignored `config/dev.local.exs` and `config/test.local.exs` that verify-doctor already imports. A team PR for tooling one person uses was the larger cost, and this choice can still be promoted to a committed opt-in later.

## Problem Statement

`wt` computes a worktree's port and database names when it creates the worktree. `mix phx.server` and `mix test` need them later, in a shell that worktrunk never touches. So the hooks must leave the values in a file the app reads on its own.

## Consequences & Tradeoffs

The rejected alternative is the committed opt-in from [zorn/dotfiles ADR 0004](https://github.com/zorn/dotfiles/blob/main/docs/adr/0004-worktree-values-in-an-env-file.md). There, the app's `runtime.exs` reads a gitignored `.env.worktree`, and the app's own `.config/wt.toml` and `.worktreeinclude` run the hooks and list the build state. That route is cleaner, but every piece of it is a commit to verify-doctor.

The local route has four costs:

- **The port needs a workaround.** verify-doctor's `runtime.exs` reads `PORT` after the `.local.exs` files, so a port set in config gets overwritten. `dev.local.exs` sets the variable with `System.put_env("PORT", …)` instead.
- **The first compile is a full app rebuild.** Mix treats the new `dev.local.exs` as a config change, so a new worktree recompiles verify-doctor's own files. The cloned `deps` stay compiled.
- **The hook owns the build-state list.** With no `.worktreeinclude`, the hook clones a fixed list of paths, which can drift from what verify-doctor needs.
- **`.env.worktree` is not gitignored there.** The global `pre-start` writes the port to it and adds `/.env.worktree` to the repo's `.git/info/exclude`, so the file never shows as new.

Teardown follows from the same choice. `mix ecto.drop` follows the `.local.exs` files, so it would drop the primary databases if those files were gone. The hook drops with `dropdb` by exact name instead, under state keys only it reads.
