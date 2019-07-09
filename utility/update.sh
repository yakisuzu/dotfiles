#!/bin/sh

brew upgrade
brew cask upgrade
anyenv update

# conf
anyenv versions

echo "goenv available"
goenv install -l | tail -3

echo "nodenv available"
nodenv install -l | grep '^  8\.' | tail -3
nodenv install -l | grep '^  10\.' | tail -3
nodenv install -l | grep '^  12\.' | tail -3

echo "pyenv available"
pyenv install -l | grep '^  2' | tail -3
pyenv install -l | grep '^  3' | tail -3

echo "rbenv available"
rbenv install -l | grep '^  2' | tail -3
