#!/usr/bin/env sh
# Regenerates the procedural placeholder art, then any missing TileSet/maps.
#
#   tools/rebuild_placeholders.sh            # keeps the TileSet and maps you've edited
#   tools/rebuild_placeholders.sh --force    # also rebuilds them from tools/build_world.gd
#
# Set GODOT to your Godot 4.7 binary if it isn't on PATH as "godot".
set -e
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

echo "== 1/4 Import project (builds the script class cache)"
"$GODOT" --headless --path . --import
echo "== 2/4 Generate placeholder PNGs"
"$GODOT" --headless --path . --script res://tools/generate_placeholder_art.gd
echo "== 3/4 Import the new PNGs"
"$GODOT" --headless --path . --import
echo "== 4/4 Build TileSet and maps"
"$GODOT" --headless --path . --script res://tools/build_world.gd -- "$@"
