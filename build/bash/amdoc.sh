#!/usr/bin/env bash
screen -S OC_AMD -d -m
sleep .1
screen -S OC_AMD -X stuff $"wolfamdctrl -i 1 --mem-clock 2200\n"
sleep .1
screen -S OC_AMD -X stuff $"wolfamdctrl -i 1 --core-clock 1130\n"
sleep .1
