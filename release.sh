#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

echo "### Release script started..."
yarn build
echo "### Build finished. Copying abis."
rm -rf contracts/abi
mkdir -p contracts/abi
# copy all abis to contracts/abi
find artifacts/contracts ! -iregex ".*([a-zA-Z0-9_]).json" -exec cp {} contracts/abi 2>/dev/null \; 
# remove non-abi files
rm contracts/abi/*.dbg.json
echo "### Copying README."
# copy root README to contracts folder
cp README.md contracts/README.md
# publish from contracts folder
cd contracts
echo "### Publishing..."
np --any-branch --no-tests
# delete copied README
rm README.md
# back to root folder
cd -
echo "### Done."