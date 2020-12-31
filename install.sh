#!/bin/bash
pushd `dirname $0` > /dev/null

# ------------------------------
function LINK_OVERRIDE(){
  SRC_PATH="$1"
  DEST_PATH="$2"

  [ -L "$DEST_PATH" ] \
    && rm "$DEST_PATH" \
    && echo "rm $DEST_PATH"

  echo "make $DEST_PATH"
  ln -s "$SRC_PATH" "$DEST_PATH"
}

# ------------------------------
function COPY_NOT_EXISTS(){
  SRC_PATH="$1"
  DEST_PATH="$2"

  [ -e "$DEST_PATH" ] \
    && echo "exists $DEST_PATH" \
    && return 0

  echo "cp $DEST_PATH"
  cp "$SRC_PATH" "$DEST_PATH"
}

echo --------------------
echo init bash
LINK_OVERRIDE "$PWD/bash/.bash_profile" "$HOME/.bash_profile"
LINK_OVERRIDE "$PWD/bash/.bashrc" "$HOME/.bashrc"
COPY_NOT_EXISTS "$PWD/bash/.bashrc_local" "$HOME/.bashrc_local"
LINK_OVERRIDE "$PWD/bash/.inputrc" "$HOME/.inputrc"
LINK_OVERRIDE "$PWD/bash/.tmux.conf" "$HOME/.tmux.conf"

echo --------------------
echo init git
LINK_OVERRIDE "$PWD/git/.gitconfig" "$HOME/.gitconfig"
LINK_OVERRIDE "$PWD/git/.gitattributes" "$HOME/.gitattributes"
COPY_NOT_EXISTS "$PWD/git/.gitconfig_local" "$HOME/.gitconfig_local"
COPY_NOT_EXISTS "$PWD/git/.gitignore_local" "$HOME/.gitignore_local"

echo --------------------
echo init vim
LINK_OVERRIDE "$PWD/vim/gvimrc.vim" "$HOME/_gvimrc"
LINK_OVERRIDE "$PWD/vim/vimrc.vim" "$HOME/_vimrc"
COPY_NOT_EXISTS "$PWD/vim/vimrc_local.vim" "$HOME/_vimrc_local"
COPY_NOT_EXISTS "$PWD/vim/.NERDTreeBookmarks" "$HOME/.NERDTreeBookmarks"
mkdir -p "$HOME/.vim"
LINK_OVERRIDE "$PWD/vim/.vim/after" "$HOME/.vim/after"
LINK_OVERRIDE "$PWD/vim/.vim/ftdetect" "$HOME/.vim/ftdetect"
LINK_OVERRIDE "$PWD/vim/.vim/syntax" "$HOME/.vim/syntax"

unset LINK_OVERRIDE
unset COPY_NOT_EXISTS
popd > /dev/null
