#!/bin/sh

tmux split-window -h "unset CLAUDECODE; claude --continue --fork-session"
