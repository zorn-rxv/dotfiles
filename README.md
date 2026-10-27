# dotfiles

Machine configuration for my RxVortex work laptop. It started as a subset of my personal [zorn/dotfiles](https://github.com/zorn/dotfiles) and is shaped to the needs of my work projects.

## What's here

### Global Claude instructions — `claude/CLAUDE.md`

The instructions every Claude Code session loads no matter which project it's in: how I want git work handled, and how I want Claude to write prose and present findings to me.

### Claude Code settings — `claude/`

My Claude Code `settings.json`, `keybindings.json`, status line script, and the `hooks/` the settings register. The status line and hooks need `jq`.

## Setup

```bash
~/Repos/dotfiles/bin/link
```

`bin/link` symlinks `claude/CLAUDE.md`, `settings.json`, `keybindings.json`, `statusline-command.sh`, and the `hooks/` directory into `~/.claude/`. It's idempotent, and it refuses to overwrite anything that already exists as a real file or directory. Editing a linked file takes effect immediately, and a change made in Claude Code's UI writes through the link and shows up here as a diff.
