#!/usr/bin/env bash
#
# Check one Launch row and print a JSON verdict for it.
#
#   preflight.sh <branch> <agent-name> <search-term>
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

set -euo pipefail

[ $# -eq 3 ] || { sed -n '3,6p' "$0" >&2; exit 2; }
branch="$1" agent="$2" term="$3"

git fetch --prune -q

checkout_branch="$(git branch --show-current)"
[ -z "$(git status --porcelain)" ] && clean=true || clean=false
pg_isready -h localhost >/dev/null 2>&1 && postgres=true || postgres=false

worktree_branches="$(git worktree list --porcelain | awk '/^branch /{b=substr($0,8); sub("^refs/heads/","",b); print b}')"
has_worktree() { grep -qxF "$1" <<<"$worktree_branches"; }

live_agent=false
herdr agent list | jq -e --arg a "$agent" 'any(.result.agents[]; .name == $a)' >/dev/null && live_agent=true

# Quote the term, so search does not split QL-90 into QL and 90. --author @me
# keeps a teammate's PR that names the same task from being resumed.
mine="$(gh pr list --state open --author @me --search "\"$term\" in:body" --json number,headRefName)"

verdict=clear reason="" launch="$branch"

if [ -n "$(git branch --list "$branch")" ] || has_worktree "$branch"; then
  verdict=skip reason="branch $branch already exists here"
elif [ "$live_agent" = true ]; then
  verdict=skip reason="an agent named $agent is already live"
elif [ "$(jq length <<<"$mine")" -gt 0 ]; then
  number="$(jq -r '.[0].number' <<<"$mine")"
  head_ref="$(jq -r '.[0].headRefName' <<<"$mine")"
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
