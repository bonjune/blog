#!/bin/bash
set -e

REMOTE=origin
BRANCH=main

# Reference: https://github.com/Integerous/Integerous.github.io

echo "Deploying updates to GitHub..."

# Build the project.
hugo

# Go to public submodule
cd public

# stage newly built site
git add .

msg="[Hugo] rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
echo "$msg"

# recover deleted CNAME (hugo always deletes this!)
git restore CNAME
git commit -m "$msg"

# push site to the deployment repo
git push "$REMOTE" "$BRANCH" --force

# Come Back up to the Project Root
cd ..

# you need this to bump the public submodule
git add .

git commit -m "[Bump] bump newly built site"
git push "$REMOTE" "$BRANCH"
