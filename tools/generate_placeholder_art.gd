extends SceneTree
## Writes the procedural placeholder art (see PixelArt) to PNG files.
##
## Usually run through tools/rebuild_placeholders.sh. To run it alone:
##   godot --headless --path . --script res://tools/generate_placeholder_art.gd
## Godot's class cache must exist first (open the project once, or run
## `godot --headless --path . --import`).

const OUT_DIR := "res://assets/placeholder/"


func _initialize() -> void:
	_save(PixelArt.overworld_tiles(), "tiles/overworld_tiles.png")
	_save(PixelArt.character_sheet(PixelArt.PLAYER_COLORS), "characters/player.png")
	for id: StringName in PixelArt.NPC_COLORS:
		_save(PixelArt.character_sheet(PixelArt.NPC_COLORS[id]), "characters/npc_%s.png" % id)
	_save(PixelArt.surf_mount(), "objects/surf_mount.png")
	_save(PixelArt.shadow(), "objects/shadow.png")
	_save(PixelArt.cut_tree(), "objects/cut_tree.png")
	_save(PixelArt.smash_rock(), "objects/smash_rock.png")
	_save(PixelArt.signpost(), "objects/signpost.png")
	for id: StringName in PixelArt.MONSTERS:
		var recipe: Array = PixelArt.MONSTERS[id]
		_save(PixelArt.monster(recipe[0], recipe[1]), "monsters/%s.png" % id)
		_save(PixelArt.monster(recipe[0], recipe[1], true), "monsters/%s_back.png" % id)
	_save(PixelArt.battle_background(), "battle/background.png")

	# Project icon: the fire starter at 4x.
	var icon := PixelArt.monster(PixelArt.MONSTERS[&"flamlet"][0], &"fire")
	icon.resize(128, 128, Image.INTERPOLATE_NEAREST)
	_report(icon.save_png("res://icon.png"), "res://icon.png")
	quit()


func _save(image: Image, relative_path: String) -> void:
	var path := OUT_DIR + relative_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_report(image.save_png(path), path)


func _report(error: Error, path: String) -> void:
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), path])
