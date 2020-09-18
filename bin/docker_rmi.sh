#!/bin/bash -e

TARGET_REPO="$1"

DELETE_REPO=`
  if [ "$TARGET_REPO" != "" ]; then
    docker images $TARGET_REPO -q
  else
    docker images -f "dangling=true" -q
  fi
`

if [ "$DELETE_REPO" != "" ]; then
  docker rmi -f $DELETE_REPO
else
  echo 削除対象なし $TARGET_REPO
fi

echo ""
docker images --format "{{.Repository}}" | sort | uniq

