#!/bin/sh

brew upgrade
brew cask upgrade
anyenv update

# conf
echo "goenv versions"
goenv versions
echo "goenv available"
goenv install -l | tail -3

echo "jenv versions"
jenv versions
echo "jenv available"
/usr/libexec/java_home -V 2>&1 | tail -n +2 | head -n -2

echo "nodenv versions"
nodenv versions
echo "nodenv available"
nodenv install -l | grep '^  8\.' | tail -3
nodenv install -l | grep '^  10\.' | tail -3
nodenv install -l | grep '^  12\.' | tail -3

echo "pyenv versions"
pyenv versions
echo "pyenv available"
pyenv install -l | grep '^  2' | tail -3
pyenv install -l | grep '^  3' | tail -3

echo "rbenv versions"
rbenv versions
echo "rbenv available"
rbenv install -l | grep '^  2' | tail -3
