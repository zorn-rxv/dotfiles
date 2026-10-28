# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Machine configuration for a work laptop, symlinked into the home directory by `bin/link`. `README.md` describes each config area and why it exists.

This is a public repo on GitHub. Everything committed is world-readable, and it stays in git history even after a later commit removes it.

`claude/CLAUDE.md` is not this repo's instructions. It is the global instruction file that `bin/link` links to `~/.claude/CLAUDE.md`, so every Claude Code session on the machine loads it. Edit it only when the change is meant for all projects.

Every tracked config file is live. `claude/settings.json`, the hooks, the skills, `fish/config.fish`, `git/ignore`, `herdr/config.toml`, the two `espanso/` files, `zed/settings.json`, and `zsh/zshenv` are symlink targets, so an edit here changes the running setup at once. A change made in Claude Code's or Zed's UI writes through the link and appears here as a diff.

## Commands

```bash
./bin/check                 # every check CI runs
./bin/check skills link     # only the named sections
./bin/link                  # create or refresh the symlinks; idempotent
```

The sections are `secrets`, `workflows`, `shell`, `skills`, `link`, and `fish`. CI runs exactly this script, one job per section, so a local pass means a green pull request. The tools are `betterleaks`, `actionlint`, `shellcheck`, `python3`, `jq`, and `fish`. `bin/check` exits without checking anything if a selected section's tool is missing.

The individual tests can run alone: `bin/check-skills` (and `bin/check-skills --self-test`), `bin/test-link`, `bin/test-check`, `bin/test-hexdocs-hook`, and `bin/test-fish-history`.

## How the pieces connect

- `bin/link` uses one `link_path` helper for every file. A new config category is a new `link_path` call there. It never overwrites a real file or directory, and `bin/test-link` checks that against a throwaway `HOME`. It also sets `core.hooksPath` to `githooks/`, which runs the Betterleaks pre-commit scan.
- A hook script goes in `claude/hooks/` and is registered in `claude/settings.json` by its `~/.claude/hooks/` path. `bin/test-link` fails when a registered hook does not resolve to a linked script.
- The `shell` section finds bash scripts by shebang under `bin/`, `claude/`, and `githooks/`, so a new script is linted without registration. It also runs `bin/test-check` and `bin/test-hexdocs-hook`.
- Each CI job name in `.github/workflows/ci.yml` is a required status check on the `protect-main` ruleset. Renaming or adding a job means updating the ruleset too, or the check silently stops being required. A new `bin/check` section also needs its own job, and `bin/test-check` verifies that each section asks only for its own tool.
- CI installs its tools at a pinned version with a SHA-256 checksum. A version bump must update the checksum with it.

## Skills (`claude/skills/`)

Each skill is a directory with a `SKILL.md` and optional `scripts/` and `reference/`. A malformed skill never activates and reports no error, which is why `bin/check-skills` exists. It enforces rules beyond the Agent Skills spec:

- Frontmatter goes through a narrow parser, not PyYAML. Quote any value that contains `: ` or ` #`.
- Relative links must resolve and must stay inside the skill's own directory. Each skill is linked into `~/.claude/skills/` separately, so a `../` link points nowhere.
- Python under `scripts/` must compile.
- Skill prose must use US spellings.

A skill forked from upstream records its origin in `metadata` frontmatter (`forked-from`, `forked-skill`, `forked-on`, and `upstream-copyright`). These skills track work in Asana, not GitHub issues. Run `bin/link` after adding a skill. It reports a link left behind by a renamed skill but does not delete it.

## Conventions

- Pull request titles follow Conventional Commits with a lowercase subject, such as `ci: add checks`.
- Because the repo is public, Betterleaks scans the full commit history. Secrets and machine-only settings go in untracked files such as `~/.config/fish/local.fish`.
- Scripts here carry header and inline comments that explain why each check exists and what failure it prevents. New scripts and checks follow the same style.
