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
DEPLOY_COMMIT="$(git rev-parse FETCH_HEAD)"
echo "Fetched ${BRANCH} at ${DEPLOY_COMMIT}"

git reset --hard "$DEPLOY_COMMIT"
echo "Working tree reset to $(git rev-parse --short HEAD)"

composer install --no-dev --prefer-dist --optimize-autoloader

php craft project-config/apply
php craft migrate/all
php craft clear-caches/all

echo "Deploy complete."
