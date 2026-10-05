extends SceneTree
## Writes the placeholder art (see PixelArt) to PNG files.
##
## Usually run through tools/rebuild_placeholders.sh. To run it alone:
##   godot --headless --path . --script res://tools/generate_placeholder_art.gd
## Godot's class cache must exist first (open the project once, or run
## `godot --headless --path . --import`).

const OUT_DIR := "res://assets/placeholder/"


func _initialize() -> void:
	for id: StringName in PixelArt.CHARACTERS:
		var file := "player" if id == &"player" else "npc_%s" % id
		_save(PixelArt.character_sheet(id), "characters/%s.png" % file)
	_save(PixelArt.surf_mount(), "objects/surf_mount.png")
	_save(PixelArt.shadow(), "objects/shadow.png")
	for id: StringName in PixelArt.MONSTERS:
		_save(PixelArt.monster(id), "monsters/%s.png" % id)
		_save(PixelArt.monster(id, true), "monsters/%s_back.png" % id)
	for id: StringName in PixelArt.GENERATED_MONSTERS:
		var recipe: Array = PixelArt.GENERATED_MONSTERS[id]
		_save(PixelArt.generated_monster(recipe[0], recipe[1]), "monsters/%s.png" % id)
		_save(PixelArt.generated_monster(recipe[0], recipe[1], true), "monsters/%s_back.png" % id)
	for id: StringName in PixelArt.ORBS:
		var colors: Array = PixelArt.ORBS[id]
		_save(PixelArt.orb(colors[0], colors[1]), "items/%s.png" % id)

	# Project icon: the fire starter at 4x.
	var icon := PixelArt.monster(&"flamlet")
	icon.resize(128, 128, Image.INTERPOLATE_NEAREST)
	_report(icon.save_png("res://icon.png"), "res://icon.png")
	quit()


func _save(image: Image, relative_path: String) -> void:
	var path := OUT_DIR + relative_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_report(image.save_png(path), path)


func _report(error: Error, path: String) -> void:
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), path])
