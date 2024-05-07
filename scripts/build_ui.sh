#!/bin/bash

: "
Build the UI.

Example: `bash scripts/build_ui.sh`.
"

# Stop upon error and undefined variables.
# Print commands before executing.
set -eux

find api/ui -type f ! -name '*.py' -delete
(
    cd ui || exit
    # Build the UI.
    yarn build

)
mv ui/dist/* api/ui/
cp -R ui/public api/ui/
