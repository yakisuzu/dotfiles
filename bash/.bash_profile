#!/bin/bash
echo ------------------
echo read .bash_profile
echo ------------------

TERM="xterm"
OS_NAME=$(uname -s | sed 's/[\.0-9-]//g')
case "$OS_NAME" in
  "Darwin" | "MSYS_NT" | "MINGW_NT" )
    echo OS_NAME=$OS_NAME `uname -m`
    ;;
  * ) echo "$OS_NAME not found" ;;
esac
#########################

[ -f ~/.bashrc ] && . ~/.bashrc
[[ ! "$PATH" =~ dotfiles ]] && export PATH="$PATH:~/dotfiles/bin"

echo ----
echo PATH
echo ----
echo "$PATH" | awk 'BEGIN{FS=":";OFS="\n"}{$1=$1;print $0}'

#########################
case "$OS_NAME" in
  "MSYS_NT" | "MINGW_NT" )
    eval `ssh-agent` > /dev/null
    ssh-add.exe ~/.ssh/id_rsa 2> /dev/null
    ;;
esac
