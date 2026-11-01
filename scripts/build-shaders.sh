#!/usr/bin/env bash
# Builds the shaders. Run dev.sh start afterwards, Qt holds on to the old ones.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../shaders"
for shader in *.frag; do
    /usr/lib/qt6/bin/qsb --glsl "320 es,330" -o "$shader.qsb" "$shader"
done
