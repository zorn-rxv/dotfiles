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

### Zed settings — `zed/`

My [Zed](https://zed.dev) `settings.json`. Its `auto_install_extensions` list makes a fresh machine install the extensions the language-server settings rely on. It also turns off Zed's telemetry. The editor font is [MonoLisa](https://www.monolisa.dev), which is licensed and not in this repo, so install its OTF files by hand. Only that file is tracked. My theme is a built-in, so `themes/` is empty and not tracked. The rules database in `~/.config/zed/prompts/` is binary and stays out.

### zsh environment — `zsh/zshenv`

Fish is my interactive shell, but Claude Code runs its shell commands in zsh, and Zed builds its environment from zsh too. `zshenv` activates mise there, so those tools find the same Elixir, Erlang, and Node versions as fish does. It also puts libpq's `psql` on PATH. zsh reads `zshenv` for every invocation, interactive or not, which is why the activation lives there rather than in `zprofile` or `zshrc`.

## Setup

```bash
~/Repos/dotfiles/bin/link
```

`bin/link` symlinks `claude/CLAUDE.md`, `settings.json`, `keybindings.json`, `statusline-command.sh`, and the `hooks/` directory into `~/.claude/`. It also links `fish/config.fish` into `~/.config/fish/`, `zed/settings.json` into `~/.config/zed/`, and `zsh/zshenv` to `~/.zshenv`. It's idempotent, and it refuses to overwrite anything that already exists as a real file or directory. Editing a linked file takes effect immediately, and a change made in Claude Code's UI writes through the link and shows up here as a diff.

## Secrets

Nothing in this repo is a credential, and nothing ever should be. Secrets and machine-only settings go in untracked sibling files, such as fish's `local.fish`.

[Betterleaks](https://github.com/betterleaks/betterleaks) runs on every pull request as a required check, so a leak blocks the merge. It scans the working tree *and* the commit history, because this repo is public and git history is permanent — a credential that reaches GitHub is already scraped, and deleting it in the next commit fixes nothing.

A pre-commit hook in `githooks/` runs Betterleaks over the staged changes, so a secret is caught before the commit exists rather than after the push. `bin/link` points `core.hooksPath` at it. It refuses the commit when Betterleaks is not installed, because a scan that did not run must not look like a clean one.

To run every check before you push:

```bash
brew install betterleaks actionlint shellcheck jq fish
./bin/check
```

`bin/check` is the same script CI runs, so there's one definition of "green" instead of two that drift apart. Besides the secret scan, it runs [actionlint](https://github.com/rhysd/actionlint) over the workflow files, [shellcheck](https://www.shellcheck.net) over the scripts in `bin/`, `claude/`, and `githooks/`, `bin/test-link`, which runs `bin/link` against a throwaway home directory, and a syntax check and history-filter test over the fish config. If a tool is missing, it exits without checking anything. Name a section, such as `./bin/check secrets`, to run only that one.

Pull request titles must follow [Conventional Commits](https://www.conventionalcommits.org) with a lowercase subject, such as `ci: add checks`. Dependabot bumps the pinned actions monthly in one grouped pull request.
