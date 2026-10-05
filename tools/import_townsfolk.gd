extends SceneTree
## Converts townsfolk from a downloaded 16x16 character sheet into the game's
## 48x64 walking-sheet layout (see PixelArt.character_sheet) and palette.
##
##   godot --headless --path . --script res://tools/import_townsfolk.gd
##   godot --headless --path . --import
##
## The source sheet puts each character in a 64x64 block: 3 columns (stand,
## step A, step B) by 3 rows (down, right, up). Each character uses 3 NES
## colors, the darkest doubling as its outline. Every color is swapped for a
## palette color, and the outer edge of the darkest one becomes INK so the
## townsfolk match the hand-drawn cast.

const SOURCE := "res://assets/characters/townsfolk/source/rpg_characters_16x16.png"
const OUT_DIR := "res://assets/characters/townsfolk/"
const BLOCK := 64
const T := PixelArt.TILE
## The source's skin color, shared by every character.
const SKIN := "fae39f"
## Source row for each of our rows (down, up, left, right); true = mirrored.
const ROWS := [[0, false], [2, false], [1, true], [1, false]]

## id -> [block in the source sheet, {source color: palette color}]. The first
## color is the character's outline color.
const TOWNSFOLK := {
	&"youngster": [Vector2i(0, 0), {"a30000": PixelArt.RED, "efbb3b": PixelArt.ORANGE}],
	&"officer": [Vector2i(2, 0), {"000000": PixelArt.INK, "0000a7": PixelArt.BLUE, "3f2b00": PixelArt.INK}],
	&"mystic": [Vector2i(1, 1), {"23178b": PixelArt.NAVY, "bb00bb": PixelArt.PINK_DARK}],
	&"fighter": [Vector2i(2, 1), {"173b5b": PixelArt.NIGHT, "737373": PixelArt.FOG}],
	&"gardener": [Vector2i(3, 1), {"004f00": PixelArt.DEEP, "efbb3b": PixelArt.SAND}],
}


func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	source.convert(Image.FORMAT_RGBA8)
	for id: StringName in TOWNSFOLK:
		var recipe: Array = TOWNSFOLK[id]
		var path := OUT_DIR + "%s.png" % id
		var error := _convert(source, recipe[0], recipe[1]).save_png(path)
		print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), path])
	quit()


func _convert(source: Image, block: Vector2i, colors: Dictionary) -> Image:
	var outline: String = colors.keys()[0]
	var sheet := Image.create_empty(T * 3, T * 4, false, Image.FORMAT_RGBA8)
	for row in ROWS.size():
		for col in 3:
			var cell := Vector2i(col, ROWS[row][0]) * T
			var frame := source.get_region(Rect2i(block * BLOCK + cell, Vector2i(T, T)))
			if ROWS[row][1]:
				frame.flip_x()
			for y in T:
				for x in T:
					var pixel := frame.get_pixel(x, y)
					if pixel.a == 0.0:
						continue
					# Unmapped colors show up magenta.
					var key := pixel.to_html(false)
					var color: Color = PixelArt.SKIN if key == SKIN else colors.get(key, Color.MAGENTA)
					if key == outline and _on_edge(frame, Vector2i(x, y)):
						color = PixelArt.INK
					sheet.set_pixel(col * T + x, row * T + y, color)
	return sheet


func _on_edge(frame: Image, p: Vector2i) -> bool:
	for d in Grid.DIRECTIONS:
		var q := p + d
		if q.x < 0 or q.y < 0 or q.x >= T or q.y >= T or frame.get_pixelv(q).a == 0.0:
			return true
	return false
