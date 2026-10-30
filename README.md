# dotfiles

Machine configuration for my RxVortex work laptop. It started as a subset of my personal [zorn/dotfiles](https://github.com/zorn/dotfiles) and is shaped to the needs of my work projects.

## What's here

### Global Claude instructions — `claude/CLAUDE.md`

The instructions every Claude Code session loads no matter which project it's in: how I want git work handled, and how I want Claude to write prose and present findings to me.

### Claude Code settings — `claude/`

My Claude Code `settings.json`, `keybindings.json`, status line script, and the `hooks/` the settings register. The status line and hooks need `jq`.

Auto mode's `autoMode` block does not live here. It describes the trust boundaries of my work projects: private repo names, internal domains, and which files hold sensitive data. That is a map of private code, and this repo is public. Claude Code reads `autoMode` only from user settings, managed settings, or a `--settings` file. It [ignores a project's `.claude/settings.local.json`](https://code.claude.com/docs/en/auto-mode-config.md), so a cloned repo cannot inject its own rules. User settings are `claude/settings.json` through the symlink, and a `--settings` flag is easy to forget. So the block lives in managed settings at `/Library/Application Support/ClaudeCode/managed-settings.json`, a root-owned file that holds only `autoMode`. Editing it needs `sudo`. On a fresh machine, it has to be recreated by hand. Run `claude auto-mode config` to confirm Claude Code reads it.

When Claude Code's auto mode setup runs, it writes a new `autoMode` block into `~/.claude/settings.json`, which shows up here as a diff. Move that block into the managed file rather than committing it. Claude Code also reorders keys whenever it saves the file, so a large diff here may hold only one real change. Comparing both versions with `jq -S` shows what changed.

### Claude Code skills — `claude/skills/`

[Agent Skills](https://agentskills.io) I maintain. Each is a directory with a `SKILL.md`, plus optional `scripts/` and `reference/` material. They come from my personal [zorn/dotfiles](https://github.com/zorn/dotfiles/tree/main/claude/skills), minus `dispatch`, which is built around worktrunk, and `wayfinder`, which is built around GitHub issues. The rest track work in Asana rather than GitHub issues; `claude/CLAUDE.md` names each repo's board.

Most began as forks of [mattpocock/skills](https://github.com/mattpocock/skills) and were reshaped to fit how I work. Every forked skill records where it came from in its `metadata` frontmatter, and `claude/skills/LICENSE` carries the upstream notice.

A skill with malformed frontmatter fails silently. It never activates, and nothing reports an error. So `bin/check-skills` validates every skill against the [Agent Skills spec](https://agentskills.io/specification) on each pull request. It also checks that relative links resolve and that bundled Python compiles.

### Herdr config — `herdr/`

My [Herdr](https://herdr.dev) `config.toml`: the theme, mouse capture, and onboarding turned off. Only that file is tracked. Herdr keeps its sockets, logs, and session snapshots in the same directory, and those are machine state.

### espanso config — `espanso/`

My [espanso](https://espanso.org) text expander config: `config/default.yml` and the snippets in `match/base.yml`. Only those two files are tracked. `espanso install` writes packages into `match/packages/`, and those come back from reinstalling. Snippets too private for a public repo, like my phone number, live in `~/Library/Application Support/espanso/match/private.yml` instead. That file sits outside the repo, so it cannot be committed, and espanso loads it alongside `base.yml` with no import. On a fresh machine it has to be recreated by hand.

### fish config — `fish/`

My [fish](https://fishshell.com) `config.fish`. It sets up PATH, including Homebrew, Docker Desktop's CLI, and libpq's `psql`. It keeps commands that carry a secret, such as a token assignment or an auth header, out of fish history. It also sets `DO_NOT_TRACK` to opt out of CLI telemetry. Only that one file is tracked. Fish writes `fish_variables` into the same directory, and installers add their own generated functions and completions there. Those files are machine state, so they stay out of the repo.

Secrets and machine-only settings go in `~/.config/fish/local.fish`, which `config.fish` loads if it exists. It lives outside the repo, so it cannot be committed.

Docker Desktop sometimes adds its own `export PATH=...` block to the top of `config.fish`, because it does not recognize the `fish_add_path` line that already adds `~/.docker/bin`. That block only duplicates the entry, so discard it with `git checkout fish/config.fish`.

### Global git ignore — `git/ignore`

The patterns every repo ignores: editor backups, `.DS_Store`, Claude Code's local settings and agent worktrees, and Python bytecode. Git reads `~/.config/git/ignore` only while `core.excludesFile` is unset, so `bin/link` warns when that setting points elsewhere.

### Zed settings — `zed/`

My [Zed](https://zed.dev) `settings.json`. Its `auto_install_extensions` list makes a fresh machine install the extensions the language-server settings rely on. It also turns off Zed's telemetry. The editor font is [MonoLisa](https://www.monolisa.dev), which is licensed and not in this repo, so install its OTF files by hand. Only that file is tracked. My theme is a built-in, so `themes/` is empty and not tracked. The rules database in `~/.config/zed/prompts/` is binary and stays out.

### zsh environment — `zsh/zshenv`

Fish is my interactive shell, but Claude Code runs its shell commands in zsh, and Zed builds its environment from zsh too. `zshenv` activates mise there, so those tools find the same Elixir, Erlang, and Node versions as fish does. It also puts libpq's `psql` on PATH and sets `DO_NOT_TRACK`, as `config.fish` does. zsh reads `zshenv` for every invocation, interactive or not, which is why the activation lives there rather than in `zprofile` or `zshrc`.

## Setup

```bash
~/Repos/dotfiles/bin/link
```

`bin/link` symlinks `claude/CLAUDE.md`, `settings.json`, `keybindings.json`, `statusline-command.sh`, and the `hooks/` directory into `~/.claude/`, and each skill into `~/.claude/skills/`. It also links `herdr/config.toml` into `~/.config/herdr/`, the espanso files into `~/Library/Application Support/espanso/`, `fish/config.fish` into `~/.config/fish/`, `git/ignore` into `~/.config/git/`, `zed/settings.json` into `~/.config/zed/`, and `zsh/zshenv` to `~/.zshenv`. It's idempotent, and it refuses to overwrite anything that already exists as a real file or directory. Re-run it after adding a skill. It reports, but does not delete, a link left behind by a renamed or removed skill. Editing a linked file takes effect immediately, and a change made in Claude Code's UI writes through the link and shows up here as a diff.

## Secrets

Nothing in this repo is a credential, and nothing ever should be. Secrets and machine-only settings go in untracked sibling files, such as fish's `local.fish`, or in files outside the repo, such as Claude Code's managed settings.

[Betterleaks](https://github.com/betterleaks/betterleaks) runs on every pull request as a required check, so a leak blocks the merge. It scans the working tree *and* the commit history, because this repo is public and git history is permanent — a credential that reaches GitHub is already scraped, and deleting it in the next commit fixes nothing.

A pre-commit hook in `githooks/` runs Betterleaks over the staged changes, so a secret is caught before the commit exists rather than after the push. `bin/link` points `core.hooksPath` at it. It refuses the commit when Betterleaks is not installed, because a scan that did not run must not look like a clean one.

To run every check before you push:

```bash
brew install betterleaks actionlint shellcheck python jq fish
./bin/check
```

`bin/check` is the same script CI runs, so there's one definition of "green" instead of two that drift apart. Besides the secret scan, it runs [actionlint](https://github.com/rhysd/actionlint) over the workflow files, [shellcheck](https://www.shellcheck.net) over the scripts in `bin/`, `claude/`, and `githooks/`, `bin/check-skills` over the skills, `bin/test-link`, which runs `bin/link` against a throwaway home directory, and a syntax check and history-filter test over the fish config. If a tool is missing, it exits without checking anything. Name a section, such as `./bin/check secrets`, to run only that one.

Pull request titles must follow [Conventional Commits](https://www.conventionalcommits.org) with a lowercase subject, such as `ci: add checks`. Dependabot bumps the pinned actions monthly in one grouped pull request.
