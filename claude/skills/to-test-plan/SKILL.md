---
name: to-test-plan
description: Turn a pull request into a manual test plan — a checklist a reviewer works through in local dev, saved beside a screenshots folder in Review Artifacts.
argument-hint: "PR number"
disable-model-invocation: true
---

A **test plan** is a checklist a reviewer can follow cold: every step names the exact link to open, the account to use, and the value to type, and every expected result is a separate **Check** the reviewer ticks. `run-test-plan` executes the same file line by line in a headless browser, so write each step precisely enough for a script to follow too.

The plan goes to `~/Documents/Review Artifacts/pr-<n>-manual-test-plan.md`, and its screenshots to the `pr-<n>-screenshots/` folder beside it.

## Steps

1. **Read the PR.** Read its description and diff with `gh pr view <n>` and `gh pr diff <n>`, and the tests it adds. List each behavior a user can see change, plus any branch the PR touches indirectly that deserves a regression check. Done when every changed behavior has a line on that list, and each line is marked as reachable in a browser or covered by tests only.

2. **Gather the dev facts.** Look up what the reviewer needs in the repo itself: seed accounts in the seeds file, dev-only routes in the router, and the commands to reset and start the app. Add the app's quirks from the section below. Done when every account and URL a step will name exists in the seeds or the router.

3. **Order the sections.** One behavior per section. When a section consumes seeded data, such as deciding a review, say which section's data it uses, and order sections so none needs data an earlier section destroyed. Done when a reviewer could run the sections top to bottom on a fresh reset.

4. **Write the plan** in the format below. Done when the file exists at the path above.

5. **Report** the plan's path and a one-line summary per section. When `run-test-plan` sent you here, return to its next step instead.

## Plan format

Open with a `# Manual Test Plan: PR #<n>` title, a link to the PR, and a short paragraph on how to use the plan: tick each step as you do it, tick each Check once you see the result, and leave a failed Check unticked with a note under it.

Then these sections, in order:

- **Run record.** Date, commit and branch, how the run was done, the result, and a link to the screenshots folder. Before a run, it reads "Not run yet."
- **Before you start.** Checkbox steps to check out the branch, reset the database, and start the server. Then a bulleted list of dev facts the reviewer needs, then a table of the seed accounts the plan uses, with each account's email and role.
- **Numbered sections**, `## 1. <behavior stated as a fact>`, such as "A blank reason shows an inline error". Steps and Checks are separate checkboxes:

  ```markdown
  - [ ] Open [http://localhost:4000/staff/login](http://localhost:4000/staff/login) and choose Review Staff from the dev quick-login menu.
    - [ ] **Check:** the decision bar shows no Override Approve button.
  ```

  A step that needs a second account opens it in a private window, so the two sessions keep separate cookies. Quote exact UI text, flash messages, and confirm-dialog wording, so a Check can compare against it. Write every URL as a full clickable `localhost` link. End each section with a `Screenshots:` line naming its shots as `<section>-<nn>-<slug>`, such as `2-01-override-panel-open`.
- **What the tests cover instead.** Each behavior a browser can't reach, and the test file that covers it.
- **Clean up.** How to restore the dev database, and what the plan changed if the reviewer skips that.

A run adds indented `Run note:` lines under a Check for anything surprising. Leave room for them; write none yourself.

## verify-doctor

These are facts a reviewer can't find in the seeds or router:

- The staff and provider login pages have a dev quick-login menu that skips the password and the second factor.
- Emails go to the dev mailbox at `http://localhost:4000/dev/mailbox` and are never sent. Oban runs in dev, so a queued email arrives within a few seconds.
- `mix ecto.reset` can't drop the database while the server holds connections, so the reset step and the clean-up step stop the server first.
- The dev SMS stub accepts only the code `123456`. The TOTP digit inputs submit their form when the sixth digit lands.
- A data setup the seeds lack, such as a credentials-only review, goes in a `mix run -e '…'` block the reviewer pastes into a second terminal.
