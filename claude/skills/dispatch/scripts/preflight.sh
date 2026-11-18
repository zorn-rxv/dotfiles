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
#
# The verdicts follow Launch step 4 of the dispatch skill:
#   skip    the branch or its worktree exists here, an agent already has the
#           name, or an open PR of mine names the work item and has a worktree
#   resume  an open PR of mine names the work item, with no worktree and no
#           live agent of that name, so it was released
#   rename  the planned branch name is taken on GitHub by an earlier branch or PR
#   clear   none of the above
#
# With --pr, the row is a PR row: a pull request, not a work item. Its verdict
# is "pr", "skip", or "refuse". The output adds number, agent (pr-<number>),
# title, author, and mine, which is true when the gh user is the author:
#   refuse  the PR belongs to another repo, is not open, or comes from a fork
#   skip    its branch or worktree exists here, or its agent is already live
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
agent_live() { herdr agent list | jq -e --arg a "$1" 'any(.result.agents[]; .name == $a)' >/dev/null; }

if [ -n "$pr_ref" ]; then
  pr="$(gh pr view "$pr_ref" --json number,url,state,headRefName,isCrossRepository,title,author)"
  me="$(gh api user | jq -r .login)"
  repo="$(gh repo view --json nameWithOwner | jq -r .nameWithOwner)"
  number="$(jq -r .number <<<"$pr")"
  head_ref="$(jq -r .headRefName <<<"$pr")"
  agent="pr-$number"
  verdict=pr reason=""

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
  # A local branch would make wt reuse it instead of origin/<branch>.
  elif branch_taken "$head_ref"; then
    verdict=skip reason="branch $head_ref already exists here"
  elif agent_live "$agent"; then
    verdict=skip reason="an agent named $agent is already live"
  fi

  jq -n \
    --arg cb "$checkout_branch" --argjson clean "$clean" --argjson pg "$postgres" \
    --arg verdict "$verdict" --arg reason "$reason" --argjson pr "$pr" --arg me "$me" \
    --arg agent "$agent" \
    '{checkout: {branch: $cb, clean: $clean}, postgres: $pg, verdict: $verdict,
      reason: (if $reason == "" then null else $reason end),
      branch: $pr.headRefName, number: $pr.number, agent: $agent,
      mine: ($pr.author.login == $me), title: $pr.title, author: $pr.author.login}'
  exit 0
fi

# Quote the term, so search does not split QL-90 into QL and 90. --author @me
# keeps a teammate's PR that names the same task from being resumed.
my_prs="$(gh pr list --state open --author @me --search "\"$term\" in:body" --json number,headRefName)"

verdict=clear reason="" launch="$branch"

if branch_taken "$branch"; then
  verdict=skip reason="branch $branch already exists here"
elif agent_live "$agent"; then
  verdict=skip reason="an agent named $agent is already live"
elif [ "$(jq length <<<"$my_prs")" -gt 0 ]; then
  number="$(jq -r '.[0].number' <<<"$my_prs")"
  head_ref="$(jq -r '.[0].headRefName' <<<"$my_prs")"
  if has_worktree "$head_ref"; then
    verdict=skip reason="open PR #$number names $term and its worktree exists"
  else
    verdict=resume reason="open PR #$number names $term and was released; the resumed worktree gets new databases" launch="$head_ref"
  fi
elif [ -n "$(git ls-remote --heads origin "$branch")" ] ||
  [ "$(gh pr list --head "$branch" --state all --json number | jq length)" -gt 0 ]; then
  verdict=rename reason="$branch is taken on GitHub by an earlier branch or PR; pick another slug"
fi

jq -n \
  --arg cb "$checkout_branch" --argjson clean "$clean" --argjson pg "$postgres" \
  --arg verdict "$verdict" --arg reason "$reason" --arg branch "$launch" \
  '{checkout: {branch: $cb, clean: $clean}, postgres: $pg, verdict: $verdict,
    reason: (if $reason == "" then null else $reason end), branch: $branch}'
