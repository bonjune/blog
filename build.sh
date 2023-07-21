#!/bin/bash

REMOTE=origin
BRANCH=main

# Reference: https://github.com/Integerous/Integerous.github.io

echo "\033[0;32mDeploying updates to GitHub...\033[0m"

# Build the project.
hugo

# Go To Public folder
cd public
# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
echo "$msg"

cp ../CNAME CNAME

git add CNAME

git commit -m "$msg"

# Push source and build repos.
git push $REMOTE $BRANCH --force

# Come Back up to the Project Root
cd ..

# blog 저장소 Commit & Push
git add .

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

git push $REMOTE $BRANCH