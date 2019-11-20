#!/bin/bash
echo ------------------
echo read .bash_profile
echo ------------------

OS=$(uname -s) && echo OS=$OS `uname -m`
OS_WIN=$(echo $OS | sed 's/[\.0-9-]//g')
if [[ "$OS" == "Darwin" ]]; then
  echo
elif [[ "$OS_WIN" == "MSYS_NT" ]]; then
  echo OS_WIN=$OS_WIN
  # init ssh
  eval `ssh-agent` > /dev/null
  ssh-add.exe ~/.ssh/id_rsa 2> /dev/null
fi

[ -f ~/.bashrc ] && . ~/.bashrc

[[ ! "$PATH" =~ dotfiles ]] && export PATH="$PATH:~/dotfiles/bin"

echo ----
echo PATH
echo ----
echo "$PATH" | awk 'BEGIN{FS=":";OFS="\n"}{$1=$1;print $0}'
