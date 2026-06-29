#!/usr/bin/env bash
set -euo pipefail

REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "This must be run from inside the project Git repository." >&2
    exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "Deploying ${REMOTE}/${BRANCH} to ${ROOT}"

git fetch "$REMOTE" "$BRANCH"
git reset --hard "$REMOTE/$BRANCH"

composer install --no-dev --prefer-dist --optimize-autoloader

php craft project-config/apply
php craft migrate/all
php craft clear-caches/all

echo "Deploy complete."
