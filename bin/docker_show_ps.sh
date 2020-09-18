#!/bin/bash -e

docker ps -a --format "table {{.Status}}\t{{.Image}}\t{{.Names}}" | tail -n +2 | sort

