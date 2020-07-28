# Build folder:

This is core codebase for SWARM.

## api

Contains the codebase for SWARM regarding communicating with other programs/websites.

## bash

Contains linux bash codebase

## powershell

Contains powershell codebase.

## cmd

Contains .bat files for PATH resolution for Windows.

## apps

Contains third party applications that SWARM uses.

## data

Placeholder for data files, such as vendor identification list, and photos for wiki.

## lib64.tar.gz

Libs for linux that miners require to run. On firs time run (HiveOS) or install (Linux),
SWARM creates the location ``/usr/local/swarm``, and places these libs there. When new
miner instances are loaded through ``screen``, SWARM will export the lib64 folder located
there.
