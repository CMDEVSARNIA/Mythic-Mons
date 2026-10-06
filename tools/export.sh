#!/usr/bin/env sh
# Builds release versions of the game into build/ (git-ignored), using the
# presets in export_presets.cfg:
#
#   tools/export.sh                  # Windows, Linux, macOS and Web
#   tools/export.sh Linux Web        # just these presets
#
# Needs the Godot 4.7 export templates (Editor > Manage Export Templates >
# Download and Install). Set GODOT to your Godot 4.7 binary if it isn't on
# PATH as "godot".
set -e
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

[ "$#" -gt 0 ] || set -- "Windows Desktop" Linux macOS Web
for preset in "$@"; do
	case "$preset" in
		"Windows Desktop") out=build/windows/MythicMons.exe ;;
		Linux) out=build/linux/MythicMons.x86_64 ;;
		macOS) out=build/macos/MythicMons.zip ;;
		Web) out=build/web/index.html ;;
		*) echo "Unknown preset: $preset" >&2; exit 1 ;;
	esac
	mkdir -p "$(dirname "$out")"
	echo "== $preset -> $out"
	"$GODOT" --headless --path . --export-release "$preset" "$out"
done
