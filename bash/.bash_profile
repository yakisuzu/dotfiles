#!/bin/bash

# インタラクティブシェル判定（最初に実行して後続ファイルで使用）
if [[ "$-" == *i* ]]; then
  export IS_INTERACTIVE=true
  echo "Interactive Mode"
else
  export IS_INTERACTIVE=false
  echo "Non-interactive Mode"
fi

if [[ "$IS_INTERACTIVE" == "true" ]]; then
  echo ------------------
  echo read .bash_profile
  echo ------------------
fi

TERM="xterm"
OS_NAME=$(uname -s | sed 's/[\.0-9-]//g')
case "$OS_NAME" in
  "Darwin" | "MSYS_NT" | "MINGW_NT" )
    if [[ "$IS_INTERACTIVE" == "true" ]]; then
      echo OS_NAME=$OS_NAME `uname -m`
    fi
    ;;
  * ) echo "$OS_NAME not found" ;;
esac
#########################

[ -f ~/.bashrc ] && . ~/.bashrc
[[ ! "$PATH" =~ dotfiles ]] && export PATH="$PATH:~/dotfiles/bin"

if [[ "$IS_INTERACTIVE" == "true" ]]; then
  echo ----
  echo PATH
  echo ----
  echo "$PATH" | awk 'BEGIN{FS=":";OFS="\n"}{$1=$1;print $0}'
fi

#########################
case "$OS_NAME" in
  "MSYS_NT" | "MINGW_NT" )
    eval `ssh-agent` > /dev/null
    ssh-add.exe ~/.ssh/id_rsa 2> /dev/null
    ;;
esac
