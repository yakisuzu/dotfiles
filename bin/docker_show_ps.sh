#!/bin/bash -e

docker ps -a --format "{{.Status}}\t{{.Image}}\t{{.Names}}" | sort
