#!/bin/bash
echo ------------
echo read .bashrc
echo ------------

export LANG=ja_JP.UTF-8
export LESSCHARSET=utf-8

export GOPATH=~/work/go
[[ ! "$PATH" =~ work/go ]] && export PATH="$PATH:$GOPATH/bin"

#########################
function MACRC(){
  # PATH before
  # TODO tmuxで重複するが、順番がかわるので宣言しなおし
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"

  # bash@3.2 completion
  [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

  # vim
  alias vim="/Applications/MacVim.app/Contents/MacOS/Vim"
  alias gvim="open /Applications/MacVim.app"

  # gcloud
  GCLOUD_HOME="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
  [ -e "$GCLOUD_HOME/path.bash.inc" ] && . "$GCLOUD_HOME/path.bash.inc"
  [ -e "$GCLOUD_HOME/completion.bash.inc" ] && . "$GCLOUD_HOME/completion.bash.inc"

  # kubenetes
  . <(kubectl completion bash)
  alias k="kubectl"
  alias kx="kubectx"
  complete -o default -F __start_kubectl k
  . <(eksctl completion bash)
}

#########################
function WINRC(){

  export PROGRAMFILES86="$PROGRAMFILES (x86)"
  export JAVA_HOME=$PROGRAMFILES/Java/jdk

  # PATH before
  export PATH=$PROGRAMFILES/Git/cmd:$PATH
  export PATH=$PROGRAMFILES/OpenSSH-Win64:$PATH
  export PATH=$PROGRAMFILES/vim80-kaoriya-win64:$PATH
  export PATH=$PROGRAMFILES/Amazon/AWSCLI:$PATH

  # PATH after
  export PATH=$PATH:$JAVA_HOME/bin
  export PATH=$PATH:$NVM_HOME
  export PATH=$PATH:$NVM_SYMLINK
  export PATH=$PATH:$PROGRAMFILES/Docker/Docker/Resources/bin

  # sed drive path
  TMP_DRIVE=$(echo $SYSTEMDRIVE | cut -c 1 | tr '[A-Z]' '[a-z]')
  export PATH=$(echo $PATH | sed "s#$SYSTEMDRIVE#/${TMP_DRIVE}#g" | sed "s#\\\\#/#g")
  unset TMP_DRIVE

  # for windows alias
  alias ls='ls --color=auto --show-control-chars'
  alias powershell='powershell -ExecutionPolicy unrestricted'
}

#########################
# main

#\[\033[31m\] Red \[\033[0m\]
#\[\033[32m\] Green \[\033[0m\]
#\[\033[36m\] Cyan \[\033[0m\]
#\[\033[1;32m\] Light Green \[\033[0m\]
#\[\033[1;36m\] Light Cyan \[\033[0m\]
PS1='\[\033[36m\]\u@\h \[\033[31m\]\w\[\033[0m\]\n$ '

alias lsa='ls -lah'
alias vi='vim -u NONE'

OS=$(uname -s)
[[ "$OS" == "Darwin" ]] && MACRC
[[ "${OS:1:7}" == "MSYS_NT" ]] && WINRC
OS=

[ -e ~/.bashrc_local ] && . ~/.bashrc_local
# sample
# export PATH=$PATH:$SYSTEMDRIVE/opscode/chefdk/embedded/bin

unset MACRC
unset WINRC
