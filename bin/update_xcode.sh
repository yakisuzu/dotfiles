#!/bin/bash -xe

P=$(xcode-select -print-path)
if [ "$P" != "" ]; then
  sudo rm -rf $P
  xcode-select --install
fi
