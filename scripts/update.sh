#!/usr/bin/env bash
# Keeps ETEA up to date from the git clone it runs from.
#   update.sh info    "commit|date|branch" of what's running
#   update.sh check   how many new commits there are, then their titles
#   update.sh apply   moves to the latest version; the Updater service then reloads the shell,
#                     or restarts it when the update printed "restart" (shaders changed)
#   update.sh catchup on a branch of its own, moves it up to the main line, when that's a
#                     straight move
# Exits 2 when the server can't be reached, 3 when this isn't a clone that follows one,
# 4 when files were changed here by hand, 5 when the history went elsewhere.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 3

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 3
# ETEA's own clone, not some bigger repository it happens to sit in, like a dotfiles one
[[ "$(git rev-parse --show-toplevel)" == "$(pwd -P)" ]] || exit 3

# Says "restart" when the move from $1 changed the shaders: Qt keeps the old ones until the
# shell restarts, a reload isn't enough
shaders_changed() {
    git diff --quiet "$1" HEAD -- shaders/ || echo restart
}

# The remote's main line, like origin/main, whatever the branch followed here
main_line() {
    local remote="${1%%/*}"
    git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null || echo "$remote/main"
}

case "${1:-}" in
    info)
        printf '%s|%s|%s\n' "$(git rev-parse --short HEAD)" "$(git log -1 --format=%cs)" "$(git branch --show-current)"
        ;;
    check)
        upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || exit 3
        timeout 30 git fetch --quiet "${upstream%%/*}" 2>/dev/null || exit 2
        git rev-list --count 'HEAD..@{u}'
        git log --format=%s 'HEAD..@{u}' | head -8
        # On a branch of its own: what the main line has that this one doesn't, merges aside
        main="$(main_line "$upstream")"
        if [[ "$main" != "$upstream" ]] && git rev-parse --verify --quiet "$main" >/dev/null; then
            echo "@ ${main#*/}"
            git rev-list --count --no-merges "HEAD..$main"
            git log --no-merges --format=%s "HEAD..$main" | head -8
        fi
        ;;
    apply)
        git rev-parse '@{u}' >/dev/null 2>&1 || exit 3
        # Never over someone's own changes
        [[ -z "$(git status --porcelain --untracked-files=no)" ]] || exit 4
        before="$(git rev-parse HEAD)"
        git merge --ff-only --quiet '@{u}' 2>/dev/null || exit 5
        shaders_changed "$before"
        ;;
    catchup)
        upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || exit 3
        [[ -z "$(git status --porcelain --untracked-files=no)" ]] || exit 4
        before="$(git rev-parse HEAD)"
        git merge --ff-only --quiet "$(main_line "$upstream")" 2>/dev/null || exit 5
        shaders_changed "$before"
        ;;
    *)
        sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
