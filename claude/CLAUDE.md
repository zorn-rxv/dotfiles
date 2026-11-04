# Global Claude Instructions

## Git commits and pull requests

Do not add promotional, attribution, or co-authorship content to any git artifact — including commit messages, PR titles, PR summaries, or any other version-control record.

This means:
- No `Co-Authored-By:` trailers in commit messages
- No "Generated with [Tool]" footers in PR descriptions
- No AI tool branding, badges, or signatures anywhere in git history

Commits and PRs are attributed solely to the human author running the session.

Write pull request titles as Conventional Commits, `type: subject`, even in a repo that does not enforce them. Use one of `fix`, `feat`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, or `revert`, and add a scope in parentheses only when it helps. Start the subject with a lowercase letter, as in `docs: add a first pass at a ubiquitous language glossary`. When a repo's own lint enforces a different title format, the repo's format wins.

## Review comment threads

When you address a review comment on a pull request, reply in its thread to say what you did, but leave the thread open. Resolve a thread only when I explicitly tell you to.

Resolving collapses the thread, so I lose the chance to check the fix against the comment before it disappears from view. Whether a comment is settled is my call, not yours.

## Asana

Work is tracked as Asana tasks, not GitHub issues. A task's identity is its URL; its GID is the last number in that URL. Read a task with `get_task`, and read the whole comment thread with `get_task_stories` and `resource_subtype: comment_added`, because `get_task` returns only the latest few comments.

Each repo's board:

| Repo | Board | New tasks go in |
| --- | --- | --- |
| `verify-doctor` | [Verify.Doctor Development Board](https://app.asana.com/1/1206675003684155/project/1214048842830262), project GID `1214048842830262` | the Backlog section, GID `1214045680265170` |

When a repo is not listed, ask me which board to use before you create anything.

Write a new task's body in `html_notes`, so its headings and lists render. Leave its custom fields, such as Priority and Status, for the team to set during triage. Leave an existing task's status, section, and assignee as they are unless I ask. The board is shared, and those fields are how the team reads where work stands.

## QuestLog

QuestLog holds my local issues. Work I have not put in Asana yet lives as Markdown files in `~/QuestLog/<repo>/`, where `<repo>` is the repo's directory name. Each file is one issue. They sit outside the repo so that no commit, `git clean`, or new worktree can touch them, and so searching the repo will not find them. When I name an issue, or ask what is open, look in that folder. An issue's identity is its ID, written as `QL-72`, not its file name. An issue file is a valid argument wherever a skill takes a spec path.

`~/QuestLog/README.md` defines the issue format: the frontmatter fields, the tag list, and how to close an issue. Follow it whenever you write an issue. Give every new issue frontmatter with the next free `id` (the build prints it), `status: open`, today's date as `created` and `updated`, and tags from the existing list. Set `updated` to today whenever you change an issue meaningfully. When I ask to close or cancel an issue, set `status: closed` and `closed`, and add a short `## Resolution` section that says what happened. QuestLog has no canceled status, so a dropped issue is closed too, and its Resolution says why. Do not delete the file. Only "open" means the work is still to do. A closed issue is history, not open work.

After changing issues, run `elixir build.exs` in `~/QuestLog` to refresh `index.html`. `~/QuestLog` is a git repository backed up to the private GitHub repo `zorn-rxv/quest_log`. Commit there after a meaningful batch of issue changes, with a Conventional Commits message, and push, without asking first.

## Write to be scanned

Length changes how a reader engages. A long pull request summary does not get read more carefully than a short one — its size pushes the reader into skimming for the part that concerns them. Keep prose tight so that what you wrote is what gets read.

Lead with the outcome. The first sentence should answer what happened or what you found, with the supporting detail after it for whoever wants it. Keep caveats short and spend the bulk of the response on the actual answer. When explaining something, give the high-level version unless depth was asked for.

Being readable and being concise are different things, and readable matters more. Shorten by being selective about what you include — leave out the detail that would not change what the reader does next — rather than by compressing prose into fragments, abbreviations, or stacked bullets. Match the shape to the question: a direct question deserves a direct answer in prose. Reserve lists for genuinely discrete items and tables for short enumerable facts, and let the surrounding prose carry the explanation.

Build each sentence to carry one idea, in the spirit of ASD-STE100 Simplified Technical English — the aerospace controlled-language standard for documentation a non-native reader must not misread. Adopt its writing rules, not its restricted dictionary: prefer short sentences, the active voice, and the present tense, and hold subordinate clauses down. Use one term for one concept, rather than naming the same thing an "issue" on one line and a "ticket" on the next. This governs the sentence; the paragraphs above govern what to include and in what order.

Neither being selective nor tightening sentences means cutting the reasoning — trim ambiguity and drop inert detail, but keep the clause that carries the why. This holds across prose, ADRs, PR summaries, and code comments alike.

## Markdown formatting

Do not hard-wrap prose in Markdown you author. Write each paragraph as a single long line and let the renderer or editor soft-wrap it.

This applies to GitHub issues, pull request bodies, comments, and Markdown documents generally. Hard-wrapped paragraphs produce noisy diffs, since editing one sentence reflows every line after it.

Exceptions: match an existing convention when a file or repo is already consistently hard-wrapped, and leave code blocks, tables, and YAML frontmatter alone.

## Presenting findings and decisions

When you put something to me that I have to answer — review findings, design options, anything needing a call — make it answerable at a glance. The failure to avoid is a wall of detail I have to read closely before I can even tell what is being asked.

Number every item, and lead each one with its claim in a single line. Supporting detail goes underneath, for the two or three I stop on.

Give each item your recommended action and a one-line reason. A list of options with "what do you think?" costs me more than it costs you — you have read the code, so make the call and let me overturn it. Where you genuinely have no preference, say so plainly instead of manufacturing a recommendation; "no objection" must not ratify a call you were not confident making.

Lead each item with a colored verdict, so my eye lands on what needs a call and skims the rest: 🔴 **Fix** to change it, 🟡 **Weigh** for a genuine coin flip with both sides stated, and ⚪ **Keep** to leave it as it is, with the reason. A Weigh I do not mention stays Keep, because leaving it is the reversible choice.

Say at the end that anything I do not mention stands as recommended, and then honor it. The point is that I can accept eight of ten and spend my attention on the two that are wrong.

## US English

Write US spellings — behavior, normalize, defense, analyze. This covers prose, code comments, commit messages, and documentation alike.

It is a consistency rule rather than a correctness one, so it applies to text that arrives from elsewhere too. A file adopted from a British-spelling source gets normalized when it is edited, rather than left to mix registers line by line.

Leave quoted material alone, and leave identifiers alone. A field name, API parameter, or dependency that spells it the British way keeps its own spelling — changing that breaks the reference rather than tidying it.
