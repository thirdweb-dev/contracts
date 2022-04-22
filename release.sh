#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

yarn build
rm -rf contracts/abi
mkdir -p contracts/abi
# copy all abis to contracts/abi
find artifacts/contracts ! -iregex ".*([a-zA-Z0-9_]).json" -exec cp {} contracts/abi \;
find artifacts/@openzeppelin ! -iregex ".*([a-zA-Z0-9_]).json" -exec cp {} contracts/abi \;
# remove non-abi files
rm contracts/abi/*.dbg.json
# publish from contracts folder
cd contracts
np --any-branch --no-tests
# back to root folder
cd -