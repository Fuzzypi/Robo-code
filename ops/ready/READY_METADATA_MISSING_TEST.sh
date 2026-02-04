#!/usr/bin/env bash
set -euo pipefail

# This file intentionally has NO matching .json file
# Used to test that runner creates transcript.log even for metadata validation failures

echo "This should never execute because metadata validation will fail first"
exit 1
