#!/bin/sh

git branch --merged | grep -v "\*" | grep -v "main" | grep -v "master" | xargs -n 1 git branch -d
