#!/bin/bash -xe

sudo rm -rf $(xcode-select -print-path)
xcode-select --install
