#!/usr/bin/env sh
# Regenerates all the art (the procedural placeholders, plus the world tiles
# and townsfolk converted from the CC0 sheets in assets/), then any missing
# game data (moves, abilities, species, items), TileSet and maps.
#
#   tools/rebuild_placeholders.sh            # keeps the TileSet/maps/data you've edited
#   tools/rebuild_placeholders.sh --force    # also rebuilds them from tools/build_*.gd
#
# Set GODOT to your Godot 4.7 binary if it isn't on PATH as "godot".
set -e
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

echo "== 1/6 Import project (builds the script class cache)"
"$GODOT" --headless --path . --import
echo "== 2/6 Generate placeholder PNGs"
"$GODOT" --headless --path . --script res://tools/generate_placeholder_art.gd
echo "== 3/6 Convert the world tiles and townsfolk from their CC0 sheets"
"$GODOT" --headless --path . --script res://tools/import_world_art.gd
"$GODOT" --headless --path . --script res://tools/import_townsfolk.gd
echo "== 4/6 Import the new PNGs"
"$GODOT" --headless --path . --import
echo "== 5/6 Build game data (moves, abilities, species, items)"
"$GODOT" --headless --path . --script res://tools/build_game_data.gd -- "$@"
echo "== 6/6 Build TileSet and maps (MART clerks stock the items from step 5)"
"$GODOT" --headless --path . --script res://tools/build_world.gd -- "$@"
