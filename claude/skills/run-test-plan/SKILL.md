---
name: run-test-plan
description: Run a PR's manual test plan in headless Chrome, ticking each Check and saving screenshots — writing the plan first when none exists.
argument-hint: "PR number, or a plan path"
disable-model-invocation: true
---

You are the reviewer, working through a **test plan** (see `to-test-plan`) in a browser you drive with a script. The plan file is the record: a Check is ticked only once the script saw it pass, and a failure stays unticked with what you saw written under it.

## Steps

1. **Check the repo.** Work out the PR number from the argument, or from a plan path's `pr-<n>-manual-test-plan.md` file name. When the working tree has uncommitted changes, stop and tell the user, since checking out the PR would carry them into the app under test. Record the current branch, so step 11 can switch back to it. Done when you have the PR number, the original branch, and a clean tree.

2. **Ask the three questions** in one round, each with its default, and wait for answers:
   1. May I reset the dev database? Default: yes.
   2. Should I tick the plan's boxes as I go? Default: yes.
   3. Where should the screenshots go? Default: `pr-<n>-screenshots/` beside the plan.

   These are the only questions in the run. Every later step follows these answers and proceeds without stopping.

3. **Find the plan** at `~/Documents/Review Artifacts/pr-<n>-manual-test-plan.md`, or at the path given. When none exists, read `~/.claude/skills/to-test-plan/SKILL.md` and follow its steps to write one, then continue here. Done when the plan file exists.

4. **Start the app.** Check out the PR with `gh pr checkout <n>`, and stop any running server. When a reset is allowed, run `mix ecto.reset` and delete the harness's `state/` folder, whose saved logins the reset invalidates. Without a reset, note which sections need seeded data that may already be gone. Run `mix phx.server` in the background with its log in the scratchpad. Done when `http://localhost:4000` answers.

5. **Set up the harness** in a scratchpad folder: `npm init -y && npm install playwright-core`, then copy [`scripts/lib.mjs`](scripts/lib.mjs) beside `node_modules`. It must sit there, because Node resolves `playwright-core` from the importing file's folder. Read `lib.mjs` once for its helpers.

6. **Write one runner script**, `run-plan.mjs`, that walks every section in order. First read the app's facts section in `~/.claude/skills/to-test-plan/SKILL.md`, such as `## verify-doctor`, since the plan may predate a fact there. Wrap each section in `section(n, fn, { dir })`, so an error fails that section and the run moves on to the next. Each Check becomes one `check(section, label, pass, note)` call, and each named screenshot one `shot()` call. Take each shot while the checked state is on screen, and pass a selector when one element proves it. Setup the plan does in a terminal, such as `mix run -e`, runs through `execSync` inside the runner. Done when every Check in the plan has its `check()` call.

7. **Run it and triage each failure.** A failure is either the harness, such as a wrong selector or a missed wait, or the app. Rule out the harness first: read the server log, the section's `debug` screenshot, and the snags below. Fix harness failures and re-run. When a re-run needs seeded data an earlier run consumed, reset again first if resets are allowed; otherwise re-run only the sections whose data remain, and mark the rest as not re-run. Done when every remaining failure is an app failure you can describe.

8. **View every screenshot.** Open each image and compare it with the Check it stands for. Reshoot any that does not show the checked state, such as a search already cleared or the top of the page instead of the form. Note anything on screen the plan didn't predict, for a `Run note:` in the next step. Done when every screenshot shows what its Check verified.

9. **Record the run in the plan.** Fill in the Run record. When ticking is allowed, tick each step and each passing Check, and leave failing Checks unticked with a `Run note:` under them. When it is not, leave the boxes as they are and list each Check's result in the Run record. Either way, add a `Run note:` wherever the app did something the plan didn't predict. Done when every Check's result is in the plan.

10. **Fix the plan's own mistakes.** Every run so far has found wrong wording in the plan: a button label, a flash message, a step that needed an extra click. Correct the plan text, and list each correction for the user.

11. **Restore and report.** Stop the server and switch back to the branch from step 1. Run the plan's Clean up section when resets are allowed; otherwise tell the user what the run left in their dev database. Report the pass and fail counts, each failure with its note, the plan corrections, and the plan's path. Then offer the follow-ups below.

## Harness rules

`lib.mjs` encodes these; keep them when writing anything outside it.

- One browser context per account, standing in for a private window. `session()` caches each account's `storageState` in `state/` beside `lib.mjs`, so later sessions skip the login, and it logs in again when a cached session has expired.
- Wait for `.phx-connected` after each navigation before acting, or LiveView drops the click. `visit()` does this; pass `live: false` for a page LiveView doesn't render, such as the dev mailbox.
- Screenshots are 1440×900 at `deviceScaleFactor: 2`, with the mouse moved to `0,0` first so no hover style shows.
- Every dialog is logged and accepted, and `page.lastDialog` holds its message, so a Check can assert the confirm wording.

## Snags

- `node` and `npm` are mise shims, and the scratchpad has no mise config, so they fail there. Run them as `mise exec node@<version> -- …`, with the version the repo's `mise.toml` pins. Leave out `--cd <repo>`: it runs the command inside the repo, and npm and the saved logins would land in its working tree.
- LiveView streams dev log lines to the browser console, and Tidewave raises page errors. Both look like crashes. Check the server log before calling a step failed.
- The flash markup has a hidden second copy, so reading flash text naively returns it twice. Use `flashText()`.
- TOTP digit inputs submit their form when the sixth digit lands. Click submit only if the inputs are still on the page. The dev SMS stub accepts only `123456`.
- The dev mailbox lists emails as JSON at `/dev/mailbox/json`; `mailbox()` returns them. Oban delivers within a few seconds, so wait before counting.
- The audit log's action filter is a select menu. Choose its option by value, such as `selectOption('staff.change_role')`, since the visible labels are humanized oddly.
- Some seed emails are substrings of others, such as `reviewer@` inside `senior-reviewer@`. Pick a row by an exact match on its email cell: `filter({ has: page.getByText(email, { exact: true }) })`.

## Follow-ups to offer

- Add a short "how we verified" note to the PR description.
- Attach key screenshots with `gh pr edit <n> --body-file body.md --attach ./shot.png`.
- For someone else's PR, share the plan as a secret gist and link it from the review.
