#!/bin/bash
echo ------------------
echo read .bash_profile
echo ------------------

OS=$(uname -s) && echo OS=$OS `uname -m`
if [[ "$OS" == "Darwin" ]]; then
  # PATH before
  [[ ! "$PATH" =~ anyenv/bin ]] && export PATH="$HOME/.anyenv/bin:$PATH"
  [[ ! "$PATH" =~ anyenv/envs ]] && eval "$(anyenv init -)"

  # update
  #brew update
  #anyenv update
elif [[ "${OS:1:7}" == "MSYS_NT" ]]; then
  # init ssh
  eval `ssh-agent` > /dev/null
  ssh-add.exe ~/.ssh/id_rsa 2> /dev/null
fi
OS=

[ -f ~/.bashrc ] && . ~/.bashrc

[[ ! "$PATH" =~ dotfiles ]] && export PATH="$PATH:~/dotfiles/bin"

echo PATH
echo ----
echo "$PATH" | awk 'BEGIN{FS=":";OFS="\n"}{$1=$1;print $0}'
