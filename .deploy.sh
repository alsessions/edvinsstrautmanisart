#!/usr/bin/env bash
set -euo pipefail

REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-main}"
PHP_BIN="${PHP_BIN:-php}"

if [[ -z "${COMPOSER:-}" ]]; then
    for composer_path in composer /usr/local/bin/composer /usr/bin/composer /opt/cpanel/composer/bin/composer; do
        if command -v "$composer_path" >/dev/null 2>&1; then
            COMPOSER="$composer_path"
            break
        fi
    done
fi

if [[ -z "${COMPOSER:-}" ]]; then
    echo "Composer was not found on this server." >&2
    echo "Install Composer, add it to PATH, or run with COMPOSER=/path/to/composer ./.deploy.sh" >&2
    exit 1
fi

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

echo "Using Composer: ${COMPOSER}"
"$COMPOSER" install --no-dev --prefer-dist --optimize-autoloader

"$PHP_BIN" craft project-config/apply
"$PHP_BIN" craft migrate/all
"$PHP_BIN" craft clear-caches/all

echo "Deploy complete."
