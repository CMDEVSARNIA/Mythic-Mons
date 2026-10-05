#!/usr/bin/env sh
# Regenerates the procedural placeholder art, then any missing TileSet, maps
# and monster data (moves, abilities, species).
#
#   tools/rebuild_placeholders.sh            # keeps the TileSet/maps/data you've edited
#   tools/rebuild_placeholders.sh --force    # also rebuilds them from tools/build_*.gd
#
# Set GODOT to your Godot 4.7 binary if it isn't on PATH as "godot".
set -e
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

echo "== 1/5 Import project (builds the script class cache)"
"$GODOT" --headless --path . --import
echo "== 2/5 Generate placeholder PNGs"
"$GODOT" --headless --path . --script res://tools/generate_placeholder_art.gd
echo "== 3/5 Import the new PNGs"
"$GODOT" --headless --path . --import
echo "== 4/5 Build TileSet and maps"
"$GODOT" --headless --path . --script res://tools/build_world.gd -- "$@"
echo "== 5/5 Build monster data"
"$GODOT" --headless --path . --script res://tools/build_monster_data.gd -- "$@"
