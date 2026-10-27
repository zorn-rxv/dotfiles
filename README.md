# dotfiles

Machine configuration for my RxVortex work laptop. It started as a subset of my personal [zorn/dotfiles](https://github.com/zorn/dotfiles) and is shaped to the needs of my work projects.

## What's here

### Global Claude instructions — `claude/CLAUDE.md`

The instructions every Claude Code session loads no matter which project it's in: how I want git work handled, and how I want Claude to write prose and present findings to me.

### Claude Code settings — `claude/`

My Claude Code `settings.json`, `keybindings.json`, status line script, and the `hooks/` the settings register. The status line and hooks need `jq`.

### fish config — `fish/`

My [fish](https://fishshell.com) `config.fish`. It sets up PATH, including Homebrew, Docker Desktop's CLI, and libpq's `psql`. It keeps commands that carry a secret, such as a token assignment or an auth header, out of fish history. It also sets `DO_NOT_TRACK` to opt out of CLI telemetry. Only that one file is tracked. Fish writes `fish_variables` into the same directory, and installers add their own generated functions and completions there. Those files are machine state, so they stay out of the repo.

Secrets and machine-only settings go in `~/.config/fish/local.fish`, which `config.fish` loads if it exists. It lives outside the repo, so it cannot be committed.

## Setup

```bash
~/Repos/dotfiles/bin/link
```

`bin/link` symlinks `claude/CLAUDE.md`, `settings.json`, `keybindings.json`, `statusline-command.sh`, and the `hooks/` directory into `~/.claude/`. It also links `fish/config.fish` into `~/.config/fish/`. It's idempotent, and it refuses to overwrite anything that already exists as a real file or directory. Editing a linked file takes effect immediately, and a change made in Claude Code's UI writes through the link and shows up here as a diff.
