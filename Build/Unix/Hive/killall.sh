#!/usr/bin/env bash

SESSION_NAME=$1
screen -ls "$SESSION_NAME" | (
  IFS=$(printf '\t');
  sed "s/^$IFS//" |
  while read -r name stuff; do
      screen -S "$name" -X quit  >/dev/null 2>&1
      screen -S "$name" -X quit  >/dev/null 2>&1
  done
)
