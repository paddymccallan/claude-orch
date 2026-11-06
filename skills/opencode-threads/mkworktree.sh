#!/usr/bin/env bash
# Create a task worktree next to the main checkout, on a new branch.
# Usage: mkworktree.sh <repo> <branch> [base=main] [dir-suffix]
#   -> <repo>-<suffix>   (suffix defaults to the branch name with / replaced by -)
# Gitignored inputs the worktree needs (node_modules, local data, opencode.json...) can be
# listed one per line in <repo>/.orch-links; each is symlinked into the new worktree.
set -euo pipefail
[[ $# -ge 2 ]] || { sed -n '2,6p' "$0"; exit 2; }
main=$(realpath "$1") branch=$2 base=${3:-main} suffix=${4:-${2//\//-}}
wt=$main-$suffix
git -C "$main" worktree add -q "$wt" -b "$branch" "$base"
if [[ -f $main/.orch-links ]]; then
  while IFS= read -r p; do
    [[ -z $p || $p == \#* ]] && continue
    [[ -e $main/$p ]] || continue
    mkdir -p "$(dirname "$wt/$p")"; ln -sfn "$main/$p" "$wt/$p"
  done < "$main/.orch-links"
fi
echo "$wt"
