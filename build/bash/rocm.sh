#!/usr/bin/env bash
mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $(< $mydir/dir.sh)/build/txt
sudo timeout -s9 30 rocm-smi -P > amdpower.txt
