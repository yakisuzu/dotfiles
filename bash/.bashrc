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
  # FIXME https://github.com/syndbg/goenv/issues/72
  export GOENV_DISABLE_GOPATH=1
  # TODO tmuxで重複するが、順番がかわるので宣言しなおし
  eval "$(anyenv init -)"

  # homebrew
  BREW_PREFIX="`brew --prefix`"
  export PATH="$BREW_PREFIX/sbin:$PATH"

  # bash@3.2 completion
  [[ -r "$BREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$BREW_PREFIX/etc/profile.d/bash_completion.sh"

  # vim
  alias vim="/Applications/MacVim.app/Contents/MacOS/Vim"
  alias gvim="open /Applications/MacVim.app"

  # gcloud
  GCLOUD_HOME="$BREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
  [ -e "$GCLOUD_HOME/path.bash.inc" ] && . "$GCLOUD_HOME/path.bash.inc"
  [ -e "$GCLOUD_HOME/completion.bash.inc" ] && . "$GCLOUD_HOME/completion.bash.inc"

  # kubenetes
  . <(kubectl completion bash)
  alias k="kubectl"
  alias kx="kubectx"
  complete -o default -F __start_kubectl k
  . <(eksctl completion bash)

  # GNU
  export PATH="$BREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
  export PATH="$BREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"

  # openssl
  export PATH="$BREW_PREFIX/opt/openssl@1.1/bin:$PATH"
  export LDFLAGS="-L$BREW_PREFIX/opt/openssl@1.1/lib"
  export CPPFLAGS="-I$BREW_PREFIX/opt/openssl@1.1/include"
}

#########################
function WINRC(){
  export PROGRAMFILES86="$PROGRAMFILES (x86)"
  export JAVA_HOME=$PROGRAMFILES/Java/jdk

  # PATH before
  export PATH=$PROGRAMFILES/vim-kaoriya:$PATH
  export PATH=$PROGRAMFILES/Git/cmd:$PATH
  export PATH=$PROGRAMFILES/OpenSSH-Win64:$PATH
  #export PATH=$PROGRAMFILES/Amazon/AWSCLI:$PATH

  # PATH after
  export PATH=$PATH:$JAVA_HOME/bin
  export PATH=$PATH:$NVM_HOME
  export PATH=$PATH:$NVM_SYMLINK
  export PATH=$PATH:$PROGRAMFILES/Docker/Docker/Resources/bin

  # sed drive path
  TMP_DRIVE=$(echo $SYSTEMDRIVE | cut -c 1 | tr '[A-Z]' '[a-z]')
  export PATH=$(echo $PATH | sed "s#$SYSTEMDRIVE#/${TMP_DRIVE}#g" | sed "s#\\\\#/#g")

  # for windows alias
  alias ls='ls --color=auto --show-control-chars'
  alias ps1='powershell -ExecutionPolicy unrestricted'
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

case "$OS_NAME" in
  "Darwin" ) MACRC ;;
  "MSYS_NT" | "MINGW_NT" ) WINRC ;;
esac

[ -e ~/.bashrc_local ] && . ~/.bashrc_local
# sample
# export PATH=$PATH:$SYSTEMDRIVE/opscode/chefdk/embedded/bin

unset MACRC
unset WINRC
