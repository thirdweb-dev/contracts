#!/usr/bin/env bash

set -e

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --local)
      local=1
      shift # past argument
      ;;
    --no-build)
      skip_build=1
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo "### Release script started..."
if [[ $skip_build -eq 0 ]]; then
yarn build
fi
echo "### Build finished. Copying abis."
rm -rf contracts/abi
mkdir -p contracts/abi
# copy all abis to contracts/abi
find contract_artifacts ! -iregex ".*([a-zA-Z0-9_]).json" -exec cp {} contracts/abi 2>/dev/null \; 
echo "### Copying README."
# copy root README to contracts folder
cp README.md contracts/README.md
# publish from contracts folder
cd contracts
echo "### Publishing..."
if [[ $local -eq 1 ]]; then
yalc push
else
np --any-branch --no-tests
fi
# delete copied README
rm README.md
# delete copied README
rm -rf node_modules
# delete copied README
rm -rf abi
# back to root folder
cd -
echo "### Done."