#!/usr/bin/env bash

# Possible tags to bump
V_MAJOR="major"
V_MINOR="minor"
V_PATCH="patch"

ARG_PUSH="-p"

VERSION_BRANCH="v1.19.0"

# Reset and set working directory to dev
git fetch
git checkout $VERSION_BRANCH
git reset --hard origin/$VERSION_BRANCH

# Obtain last tag
LASTTAG=`git describe --tags --abbrev=0`

# Parse major, minor, and patch from git tag
PURETAG="$(echo "${LASTTAG//v}")"
TAGARR=(${PURETAG//./ })
MAJOR="$(echo "${TAGARR[0]}")"
MINOR="$(echo "${TAGARR[1]}")"
PATCH="$(echo "${TAGARR[2]}")"

# Bump version number based on input argument
if [[ $1 == $V_MAJOR ]]; then
    MAJOR="$(echo "$((${TAGARR[0]} + 1))")"
    MINOR="0"
    PATCH="0"
elif [[ $1 == $V_MINOR ]]; then
    MINOR="$(echo "$((${TAGARR[1]} + 1))")"
    PATCH="0"
else
    PATCH="$(echo "$((${TAGARR[2]} + 1))")"
fi
NEWTAG="$(echo "v"$MAJOR"."$MINOR"."$PATCH)"

# Formulate description of the new tag from the commits since the last tag
GITDESCRIPTION="$(echo "$NEWTAG")\n\n$(git log $LASTTAG..HEAD --pretty=format:"* %s")"
git log $LASTTAG..HEAD --pretty=format:"<li>%s</li>" > release_notes.txt

# Checkout master branch
git checkout master
git reset --hard origin/master

# Create new commit based on commits and description
git merge origin/$VERSION_BRANCH --ff-only

git tag -a $NEWTAG -m "$(echo -e "$GITDESCRIPTION")"

git checkout $VERSION_BRANCH
git merge master

# Push new commit, tags, and synchronize branches
if [[ $2 == $ARG_PUSH ]]; then
    git push origin master --tags
    git push origin $VERSION_BRANCH
fi