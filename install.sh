#!/bin/bash
pushd `dirname $0` > /dev/null

# ------------------------------
function LINK_OVERRIDE(){
  SRC_PATH="$1"
  DEST_PATH="$2"

  if [ -L "$DEST_PATH" ] || [ -f "$DEST_PATH" ]; then
    rm "$DEST_PATH"
    echo "rm $DEST_PATH"
  elif [ -d "$DEST_PATH" ]; then
    rm -rf "$DEST_PATH"
    echo "rm -rf $DEST_PATH"
  fi

  echo "make $DEST_PATH"
  ln -s "$SRC_PATH" "$DEST_PATH"
}

# ------------------------------
# base (repo管理) を実体ファイルへ deep-merge する
# 実体は untracked のままなのでツールの自動書き込みで repo が汚れない
# base のキーは base が勝ち、実体にしかないキーは温存される
function MERGE_JSON(){
  BASE_PATH="$1"
  DEST_PATH="$2"

  if [ -L "$DEST_PATH" ]; then
    rm "$DEST_PATH"
    echo "rm $DEST_PATH"
  fi

  if ! command -v jq > /dev/null; then
    echo "jq not found, fallback to copy"
    COPY_NOT_EXISTS "$BASE_PATH" "$DEST_PATH"
    return 0
  fi

  if [ ! -e "$DEST_PATH" ]; then
    echo "cp $DEST_PATH"
    cp "$BASE_PATH" "$DEST_PATH"
    return 0
  fi

  echo "merge $DEST_PATH"
  jq -s '.[0] * .[1]' "$DEST_PATH" "$BASE_PATH" > "$DEST_PATH.tmp" \
    && mv "$DEST_PATH.tmp" "$DEST_PATH"
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
LINK_OVERRIDE "$PWD/vim/_gvimrc.vim" "$HOME/_gvimrc"
LINK_OVERRIDE "$PWD/vim/_vimrc.vim" "$HOME/_vimrc"
COPY_NOT_EXISTS "$PWD/vim/_vimrc_local.vim" "$HOME/_vimrc_local"
COPY_NOT_EXISTS "$PWD/vim/.fern_bookmark.json" "$HOME/.fern_bookmark.json"
LINK_OVERRIDE "$PWD/vim/.ideavimrc" "$HOME/.ideavimrc"
LINK_OVERRIDE "$PWD/vim/.vscodevimrc" "$HOME/.vscodevimrc"
mkdir -p "$HOME/.vim"
LINK_OVERRIDE "$PWD/vim/.vim/after" "$HOME/.vim/after"
LINK_OVERRIDE "$PWD/vim/.vim/ftdetect" "$HOME/.vim/ftdetect"
LINK_OVERRIDE "$PWD/vim/.vim/syntax" "$HOME/.vim/syntax"

echo --------------------
echo init claude
mkdir -p "$HOME/.claude"
MERGE_JSON "$PWD/claude/settings.base.json" "$HOME/.claude/settings.json"
LINK_OVERRIDE "$PWD/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
LINK_OVERRIDE "$PWD/claude/hooks" "$HOME/.claude/hooks"
LINK_OVERRIDE "$PWD/claude/rules" "$HOME/.claude/rules"
LINK_OVERRIDE "$PWD/claude/skills" "$HOME/.claude/skills"
COPY_NOT_EXISTS "$PWD/claude/CLAUDE.local.md" "$HOME/.claude/CLAUDE.local.md"

echo --------------------
echo init codex
mkdir -p "$HOME/.codex"
LINK_OVERRIDE "$PWD/codex/personal.config.toml" "$HOME/.codex/personal.config.toml"

unset LINK_OVERRIDE
unset MERGE_JSON
unset COPY_NOT_EXISTS
popd > /dev/null
