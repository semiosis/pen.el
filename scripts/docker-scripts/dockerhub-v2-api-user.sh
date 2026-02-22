#!/bin/bash

# Example for the Docker Hub V2 API
# Returns all imagas and tags associated with a Docker Hub user account.
# Requires 'jq': https://stedolan.github.io/jq/

# This does not do what I want
echo This does not do what I want 1>&2
exit 1

# set username and password
UNAME="$(cat $HOME/.myrc.yaml | yq -r '.dockerhub_user')"
UPASS="$(cat $HOME/.myrc.yaml | yq -r '.dockerhub_pass')"

# -------

set -e
echo

# TOKEN="$(cat $HOME/.myrc.yaml | yq -r '.dockerhub_token')"
# aquire token
# cmd curl -s -H "Content-Type: application/json" -X POST -d '{"username": "${UNAME}", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/
# exit 0

# : ${TOKEN:="$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "${UNAME}", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)"}
# echo "$TOKEN"
# exit 1

# get list of repositories for the user account
REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/?page_size=100 | jq -r '.results|.[]|.name')

# build a list of all images & tags
for i in ${REPO_LIST}
do
  # get tags for repo
  IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${i}/tags/?page_size=100 | jq -r '.results|.[]|.name')

  # build a list of images from tags
  for j in ${IMAGE_TAGS}
  do
    # add each tag to list
    FULL_IMAGE_LIST="${FULL_IMAGE_LIST} ${UNAME}/${i}:${j}"
  done
done

# output
for i in ${FULL_IMAGE_LIST}
do
  echo ${i}
done
