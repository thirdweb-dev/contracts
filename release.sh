#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

yarn compile
cd contracts
np --any-branch --no-tests
cd -