#!/bin/sh

brew upgrade
brew upgrade --cask
anyenv update

# conf
echo ""
echo "-----------------------------"
echo "- jenv versions"
jenv versions
echo "- jenv available"
/usr/libexec/java_home -V 2>&1 | tail -n +2 | head -n -2 | sed -e 's/^  //'

echo ""
echo "-----------------------------"
echo "- nodenv versions"
nodenv versions
echo "- nodenv available"
nodenv install -L | grep '^22\.' | tail -3
nodenv install -L | grep '^24\.' | tail -3

echo ""
echo "-----------------------------"
echo "- pyenv versions"
pyenv versions
echo "- pyenv available"
pyenv install -l | grep '^  2.[0-9]\+.[0-9]\+$' | tail -3
pyenv install -l | grep '^  3.[0-9]\+.[0-9]\+$' | tail -3
