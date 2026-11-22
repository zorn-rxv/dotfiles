#!/usr/bin/env bash
#
# Check one Launch row and print a JSON verdict for it.
#
#   preflight.sh <branch> <agent-name> <search-term>
#   preflight.sh --pr <PR number or URL>
#
# The search term is what an earlier PR's body would name: an Asana task's
# GID, or a QuestLog ID such as QL-90. Run it from the primary checkout. It
# runs `git fetch --prune`, so the remote checks see GitHub as it is now, and
# changes nothing else. It prints:
#
#   checkout   {branch, clean} of the primary checkout
#   postgres   whether `pg_isready -h localhost` answers
#   verdict    "clear", "skip", "resume", or "rename"
#   reason     why, for every verdict but "clear"
#   branch     the branch to launch: the planned one, or the PR's on "resume"
#   fast_forward  true when a leftover local branch must be fast-forwarded to
#              origin before the launch
#
# The verdicts follow Launch step 4 of the dispatch skill:
#   skip    any one of these:
#           - an agent already has the name
#           - an open PR of mine names the work item and has a worktree here
#           - an open PR of mine names the work item, and its local branch has
#             commits origin lacks
#           - more than one open PR of mine names the work item and was released
#           - the planned branch or its worktree exists here, unless it is the
#             one released PR's own branch
#   resume  exactly one open PR of mine names the work item, with no worktree
#           and no live agent of that name, so it was released. Its branch
#           may still exist here, even under the planned name.
#   rename  the planned branch name is taken on GitHub by an earlier branch or PR
#   clear   none of the above
#
# With --pr, the row is a PR row: a pull request, not a work item. Its verdict
# is "pr", "skip", or "refuse". The output adds number, agent (pr-<number>),
# title, author, and mine, which is true when the gh user is the author:
#   refuse  the PR belongs to another repo, is not open, or comes from a fork
#   skip    its worktree exists here, its local branch has commits origin
#           lacks, or its agent is already live
#   pr      none of the above; launch it on the PR's branch

set -euo pipefail

if [ "${1:-}" = --pr ]; then
  [ $# -eq 2 ] || { sed -n '3,7p' "$0" >&2; exit 2; }
  pr_ref="$2"
else
  [ $# -eq 3 ] || { sed -n '3,7p' "$0" >&2; exit 2; }
  pr_ref="" branch="$1" agent="$2" term="$3"
fi

git fetch --prune -q

checkout_branch="$(git branch --show-current)"
[ -z "$(git status --porcelain)" ] && clean=true || clean=false
pg_isready -h localhost >/dev/null 2>&1 && postgres=true || postgres=false

worktree_branches="$(git worktree list --porcelain | awk '/^branch /{b=substr($0,8); sub("^refs/heads/","",b); print b}')"
has_worktree() { grep -qxF "$1" <<<"$worktree_branches"; }
branch_taken() { [ -n "$(git branch --list "$1")" ] || has_worktree "$1"; }
# A plain wt remove keeps an unmerged local branch, and wt herdr-resume reuses
# it instead of origin/<branch>. Prints "none", "behind" when origin holds all
# of it so a fast-forward is safe, or "ahead" when it has commits origin lacks.
leftover() {
  if [ -z "$(git branch --list "$1")" ]; then echo none
  elif git merge-base --is-ancestor "refs/heads/$1" "refs/remotes/origin/$1" 2>/dev/null; then echo behind
  else echo ahead; fi
}
# Read Herdr once, outside any condition. Inside an `if`, set -e does not fire.
# A failed lookup would then read as "no such agent", and dispatch would launch
# a second agent onto the work.
agents_json="$(herdr agent list)"
# A zero exit with no agents array would read the same way, so it aborts too.
jq -e '.result.agents | type == "array"' <<<"$agents_json" >/dev/null
agent_live() { jq -e --arg a "$1" 'any(.result.agents[]; .name == $a)' <<<"$agents_json" >/dev/null; }

if [ -n "$pr_ref" ]; then
  pr="$(gh pr view "$pr_ref" --json number,url,state,headRefName,isCrossRepository,title,author)"
  me="$(gh api user | jq -r .login)"
  repo="$(gh repo view --json nameWithOwner | jq -r .nameWithOwner)"
  number="$(jq -r .number <<<"$pr")"
  head_ref="$(jq -r .headRefName <<<"$pr")"
  agent="pr-$number"
  verdict=pr reason="" fast_forward=false

  # gh pr view opens a URL from any repo, so the PR must be this repo's.
  # GitHub names are case-insensitive.
  if ! jq -e --arg r "$repo" '(.url | ascii_downcase) | startswith("https://github.com/" + ($r | ascii_downcase) + "/pull/")' <<<"$pr" >/dev/null; then
    verdict=refuse reason="PR #$number belongs to another repo, not $repo"
  # A closed or merged PR has no review or second round left to work on.
  elif [ "$(jq -r .state <<<"$pr")" != OPEN ]; then
    verdict=refuse reason="PR #$number is $(jq -r '.state | ascii_downcase' <<<"$pr"), not open"
  # wt herdr-resume builds from origin/<branch>, and origin has no fork branch.
  elif [ "$(jq -r .isCrossRepository <<<"$pr")" = true ]; then
    verdict=refuse reason="PR #$number comes from a fork, so origin has no $head_ref"
  elif has_worktree "$head_ref"; then
    verdict=skip reason="a worktree for $head_ref already exists"
  elif [ "$(leftover "$head_ref")" = ahead ]; then
    verdict=skip reason="local branch $head_ref has commits origin lacks"
  elif agent_live "$agent"; then
    verdict=skip reason="an agent named $agent is already live"
  elif [ "$(leftover "$head_ref")" = behind ]; then
    fast_forward=true
  fi

  jq -n \
    --arg cb "$checkout_branch" --argjson clean "$clean" --argjson pg "$postgres" \
    --arg verdict "$verdict" --arg reason "$reason" --argjson pr "$pr" --arg me "$me" \
    --arg agent "$agent" --argjson ff "$fast_forward" \
    '{checkout: {branch: $cb, clean: $clean}, postgres: $pg, verdict: $verdict,
      reason: (if $reason == "" then null else $reason end),
      branch: $pr.headRefName, number: $pr.number, agent: $agent,
      mine: ($pr.author.login == $me), title: $pr.title, author: $pr.author.login,
      fast_forward: $ff}'
  exit 0
fi

# Quote the term, so search does not split QL-90 into QL and 90. --author @me
# keeps a teammate's PR that names the same task from being resumed.
my_prs="$(gh pr list --state open --author @me --search "\"$term\" in:body" --json number,headRefName)"

# Assign these outside any condition, so a failed lookup aborts. Inside the
# condition, it would read as "the name is unused".
# A bare name matches any ref that ends in it, such as alice/<branch>.
remote_head="$(git ls-remote --heads origin "refs/heads/$branch")"
old_pr_count="$(gh pr list --head "$branch" --state all --json number | jq length)"

verdict=clear reason="" launch="$branch" fast_forward=false

# Read every open PR, not only the first. Any one that is still dispatched
# here skips the row, and more than one released PR leaves no single branch
# to resume.
dispatched_reason="" resumable=0 number="" head_ref=""
while read -r n ref; do
  [ -n "$ref" ] || continue
  if has_worktree "$ref"; then
    dispatched_reason="open PR #$n names $term and its worktree exists"
  elif [ "$(leftover "$ref")" = ahead ]; then
    dispatched_reason="open PR #$n names $term, but local branch $ref has commits origin lacks"
  else
    resumable=$((resumable + 1)) number="$n" head_ref="$ref"
  fi
done <<<"$(jq -r '.[] | "\(.number) \(.headRefName)"' <<<"$my_prs")"

# Open PRs come before the planned branch. A plain wt remove keeps the local
# branch, and a re-dispatch can derive the same slug. So the planned branch
# can belong to a released PR that should resume. Under any other name, it
# means the work item is still being worked on here.
if agent_live "$agent"; then
  verdict=skip reason="an agent named $agent is already live"
elif [ -n "$dispatched_reason" ]; then
  verdict=skip reason="$dispatched_reason"
elif [ "$resumable" -gt 1 ]; then
  verdict=skip reason="$resumable open PRs of mine name $term; release or close all but one"
elif [ "$resumable" -eq 1 ] && [ "$branch" != "$head_ref" ] && branch_taken "$branch"; then
  verdict=skip reason="branch $branch already exists here, beside released PR #$number"
elif [ "$resumable" -eq 1 ]; then
  [ "$(leftover "$head_ref")" = behind ] && fast_forward=true
  verdict=resume reason="open PR #$number names $term and was released; the resumed worktree gets new databases" launch="$head_ref"
elif branch_taken "$branch"; then
  verdict=skip reason="branch $branch already exists here"
elif [ -n "$remote_head" ] || [ "$old_pr_count" -gt 0 ]; then
  verdict=rename reason="$branch is taken on GitHub by an earlier branch or PR; pick another slug"
fi

jq -n \
  --arg cb "$checkout_branch" --argjson clean "$clean" --argjson pg "$postgres" \
  --arg verdict "$verdict" --arg reason "$reason" --arg branch "$launch" \
  --argjson ff "$fast_forward" \
  '{checkout: {branch: $cb, clean: $clean}, postgres: $pg, verdict: $verdict,
    reason: (if $reason == "" then null else $reason end), branch: $branch,
    fast_forward: $ff}'
