#!/bin/sh

if [ -z "$(which github-changes)" ]; then
  # specify version because github-changes "is under heavy development. Things
  # may break between releases" until 0.1.0
  echo "First, do: [sudo] npm install -g github-changes@0.0.14"
  exit 1
fi

if [ -d .git/refs/remotes/upstream ]; then
  remote=upstream
else
  remote=origin
fi

# Increment v2.x.y -> v2.x+1.0
npm version minor || exit 1

# Generate changelog from pull requests
github-changes -o maxcanna \
  -r node-lightify-rest \
  --verbose \
  --file CHANGELOG.md \
  --only-pulls --use-commit-body \
  --date-format 'YYYY-MM-DD' \
  --title 'Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).' \
  || exit 1

# Since the tag for the new version hasn't been pushed yet, any changes in it
# will be marked as "upcoming"
version="$(grep '"version"' package.json | cut -d'"' -f4)"
sed -i -e "s/^### upcoming/### v$version -/" CHANGELOG.md

# This may fail if no changelog updates
git add CHANGELOG.md; git commit -m 'Update changelog'

# Publish the new version to npm
npm publish || exit 1

# Increment v2.x.0 -> v2.x.1
# For rationale, see:
# https://github.com/request/oauth-sign/issues/10#issuecomment-58917018
npm version patch || exit 1

# Push back to the main repo
git push $remote master --tags || exit 1
