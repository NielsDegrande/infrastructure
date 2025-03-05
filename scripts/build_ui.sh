#!/bin/bash

: "
Build the UI.

Example: bash scripts/build_ui.sh.
"

# Stop upon error and undefined variables.
# Print commands before executing.
set -eux

(
    cd ui || exit
    # Bundle the UI.
    bun run build

)
rsync -av --remove-source-files ui/dist/ api/ui/
cp -R ui/public api/ui/
