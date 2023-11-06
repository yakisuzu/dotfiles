#!/bin/bash
echo ------------
echo read .bashrc
echo ------------

export LANG=ja_JP.UTF-8
export LESSCHARSET=utf-8

export GOPATH=~/work/go
[[ ! "$PATH" =~ work/go ]] && export PATH="$PATH:$GOPATH/bin"

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

#########################
function MACRC(){
  # PATH before
  # TODO tmuxで重複するが、順番がかわるので宣言しなおし

  # homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export BREW_PREFIX="`brew --prefix`"
  export PATH="$BREW_PREFIX/sbin:$PATH"

  # bash@3.2 completion
  [[ -r "$BREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$BREW_PREFIX/etc/profile.d/bash_completion.sh"

  # git completion
  [[ -r "$BREW_PREFIX/opt/git/etc/bash_completion.d/git-completion.bash" ]] && . "$BREW_PREFIX/opt/git/etc/bash_completion.d/git-completion.bash"
  #[[ -r "$BREW_PREFIX/opt/git/etc/bash_completion.d/git-prompt.bash" ]] && . "$BREW_PREFIX/opt/git/etc/bash_completion.d/git-prompt.bash"

  # vim
  alias vim="/Applications/MacVim.app/Contents/MacOS/Vim"
  alias gvim="open /Applications/MacVim.app"

  # gcloud
  export GCLOUD_HOME="$BREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
  [ -e "$GCLOUD_HOME/path.bash.inc" ] && . "$GCLOUD_HOME/path.bash.inc"
  [ -e "$GCLOUD_HOME/completion.bash.inc" ] && . "$GCLOUD_HOME/completion.bash.inc"

  # kubenetes
  . <(kubectl completion bash)
  alias k="kubectl"
  alias kx="kubectx"
  complete -o default -F __start_kubectl k
  . <(eksctl completion bash)

  # ver固定をbrewよりも優先させる
  eval "$(anyenv init -)"

  # GNU
  export PATH="$BREW_PREFIX/opt/grep/libexec/gnubin:$PATH"
  export PATH="$BREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
  export PATH="$BREW_PREFIX/opt/findutils/libexec/gnubin:$PATH"
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

  # git completion
  echo TODO git completion

  # for windows alias
  alias ls='ls --color=auto --show-control-chars'
  alias ps1='powershell -ExecutionPolicy unrestricted'
}

#########################
# main

function PS1RC(){
  local COLOR_END='\[\033[0m\]'
  local COLOR_RED='\[\033[31m\]'
  local COLOR_GREEN='\[\033[32m\]'
  local COLOR_SYAN='\[\033[36m\]'
  local COLOR_LIGHT_GREEN='\[\033[1;32m\]'
  local COLOR_LIGHT_SYAN='\[\033[1;36m\]'
  local PS1_USER_HOST="${COLOR_SYAN}\u@\h${COLOR_END}"
  local PS1_DIR="${COLOR_RED}\w${COLOR_END}"
  local PS1_GIT=${COLOR_LIGHT_GREEN}"\$([ -d ./.git ] && git log --pretty='format:%C(auto)%d' -n 1 && printf \" \$(git config user.name) <\$(git config user.email)>\")"${COLOR_END}
  local PS1_INPUT_LINE='$ '
  export PS1="${PS1_USER_HOST} ${PS1_DIR}${PS1_GIT}\n${PS1_INPUT_LINE}"
}
PS1RC && unset PS1RC

alias lsa='ls -lah'
alias vi='vim -u NONE'

case "$OS_NAME" in
  "Darwin" ) MACRC && unset MACRC ;;
  "MSYS_NT" | "MINGW_NT" ) WINRC && unset WINRC ;;
esac


[ -e ~/.bashrc_local ] && . ~/.bashrc_local
# sample
# export PATH=$PATH:$SYSTEMDRIVE/opscode/chefdk/embedded/bin

