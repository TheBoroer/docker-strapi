#!/bin/sh
set -ea

_stopStrapi() {
  echo "Stopping strapi"
  kill -SIGINT "$strapiPID"
  wait "$strapiPID"
}

trap _stopStrapi SIGTERM SIGINT

cd /app

# Disable Strict Host checking for non interactive git clones

mkdir -p -m 0700 /root/.ssh
echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

# Setup git variables
if [ ! -z "$GIT_EMAIL" ]; then
 git config --global user.email "$GIT_EMAIL"
fi
if [ ! -z "$GIT_NAME" ]; then
 git config --global user.name "$GIT_NAME"
 git config --global push.default simple
fi

# Dont pull code down if the .git folder exists
if [ ! -d "/app/.git" ]; then
 # Pull down code from git for our site!
 if [ ! -z "$GIT_REPO" ]; then
   # Remove the test index file
   rm -Rf /app/*
   if [ ! -z "$GIT_BRANCH" ]; then
     if [ -z "$GIT_USERNAME" ] && [ -z "$GIT_PERSONAL_TOKEN" ]; then
       git clone --recursive -b $GIT_BRANCH $GIT_REPO /app/
     else
       git clone --recursive -b ${GIT_BRANCH} https://${GIT_USERNAME}:${GIT_PERSONAL_TOKEN}@${GIT_REPO} /app
     fi
   else
     if [ -z "$GIT_USERNAME" ] && [ -z "$GIT_PERSONAL_TOKEN" ]; then
       git clone --recursive $GIT_REPO /app/
     else
       git clone --recursive https://${GIT_USERNAME}:${GIT_PERSONAL_TOKEN}@${GIT_REPO} /app
     fi
   fi
 fi
else
 if [ ! -z "$GIT_REPULL" ]; then
   git -C /app rm -r --quiet --cached /app
   git -C /app fetch --all -p
   git -C /app reset HEAD --quiet
   git -C /app checkout "$GIT_BRANCH"
   git -C /app pull
   git -C /app submodule update --init
 fi
fi

## Install Node Packages
if [ -f "/app/package.json" ] ; then
  npm install && echo "NPM modules installed"
fi

strapi start &

strapiPID=$!
wait "$strapiPID"
