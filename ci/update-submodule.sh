#!/bin/bash

set -e
set -x

get_submodule_commit() {
    cd $SUBMODULE_PATH
    submodule_commit=$(git rev-parse HEAD)
    cd ..
    echo $submodule_commit
}

echo "TEST_FROM_UI: ${TEST_FROM_UI}"


SUBMODULE_PATH=$1
BRANCH=$2

if [[ "$BRANCH" != "master" ]]; then
    git fetch origin $BRANCH:$BRANCH
fi

# Needed even on master since on Travis you are on a detached (git clone
# followed by git checkout)
git checkout $BRANCH

git submodule update --init
CURRENT_SUBMODULE_COMMIT=$(get_submodule_commit)

git submodule update --remote
NEW_SUBMODULE_COMMIT=$(get_submodule_commit)

if [[ "$CURRENT_SUBMODULE_COMMIT" == "$NEW_SUBMODULE_COMMIT" ]]; then
    echo 'No update in the submodule since last sync, exiting'
    exit 0
fi

git diff

git config user.email "loic.esteve@ymail.com"
git config user.name lesteve

git add $SUBMODULE_PATH
git commit -m "Update submodule to commit $NEW_SUBMODULE_COMMIT"

PUSH_REMOTE=origin
if [[ -n "$TRAVIS" ]]; then
    git remote add origin-with-token https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}
    PUSH_REMOTE=origin-with-token
fi

git push $PUSH_REMOTE $BRANCH
