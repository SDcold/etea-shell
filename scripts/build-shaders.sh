#!/usr/bin/env bash
# Builds the shaders. Run dev.sh start afterwards, Qt holds on to the old ones.
set -euo pipefail

# Arch keeps qsb in /usr/lib, Fedora in /usr/lib64
qsb="$(command -v qsb || ls /usr/lib/qt6/bin/qsb /usr/lib64/qt6/bin/qsb 2>/dev/null | head -1)"

cd "$(dirname "${BASH_SOURCE[0]}")/../shaders"
for shader in *.frag; do
    "$qsb" --glsl "320 es,330" -o "$shader.qsb" "$shader"
done
