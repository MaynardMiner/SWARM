#!/usr/bin/env bash
ps aux |  awk '{print $2"\t"$11}' | grep -E '^\d+\t'"$1"'$' | awk '{print $1}' | xargs kill -SIGTERM