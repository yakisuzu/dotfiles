#!/bin/sh

brew upgrade
brew upgrade --cask
mise plugins update

# conf
echo ""
echo "-----------------------------"
echo "- mise versions"
mise ls
echo "- mise outdated"
mise outdated

echo ""
echo "-----------------------------"
echo "- java available"
mise ls-remote java | grep '^corretto-2[15]\.' | tail -3

echo ""
echo "-----------------------------"
echo "- node available"
mise ls-remote node 24 | tail -3
mise ls-remote node 26 | tail -3

echo ""
echo "-----------------------------"
echo "- python available"
mise ls-remote python | grep '^3\.[0-9]\+\.[0-9]\+$' | tail -3
