extends SceneTree
## Builds assets/tilesets/town_tiles.png (laid out as in TownTiles) from
## ArMM1998's CC0 overworld sheet in assets/tilesets/source/.
##
##   godot --headless --path . --script res://tools/import_town_tiles.gd
##   godot --headless --path . --import
##
## Tiles with see-through parts (bushes, flowers, fences) are laid over grass.
## Tall grass and ledges are drawn here in the sheet's greens, and the house
## gets red, blue and slate roofs for the MONSTER CENTER, MART and lab.

const SOURCE := "res://assets/tilesets/source/zelda_like_overworld.png"
const T := Grid.TILE_SIZE

## Atlas tile -> [its tile in the source sheet, laid over grass?].
const CUTS := {
	&"grass": [Vector2i(0, 0), false],
	&"path": [Vector2i(2, 32), false],
	&"flowers": [Vector2i(3, 11), true],
	&"sand": [Vector2i(1, 4), false],
	&"tree": [Vector2i(2, 14), true],
	&"cliff": [Vector2i(9, 5), true],
	&"fence": [Vector2i(4, 17), true],
	&"shore_north": [Vector2i(18, 9), false],
}
## The 2x2 open-water pattern, in TownTiles.water_at() order.
const WATER := [Vector2i(16, 0), Vector2i(17, 0), Vector2i(16, 1), Vector2i(17, 1)]
const HOUSE := Vector2i(6, 0)

const GRASS_LIGHT := Color("6add4b")
const GRASS_DARK := Color("29973b")
const GRASS_DEEP := Color("2d5b3f")
## 8x8 clump repeated four times over grass.
const TALL_GRASS := [
	".D....D.",
	"DLD..DLD",
	"DLLDDLLD",
	"DGLLLLGD",
	".DGGGGD.",
	"..DDDD..",
]
## Drawn over grass from row 7: a lit edge, the drop, and its shadow.
const LEDGE := [
	"LLLLLLLLLLLLLLLL",
	"GGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGG",
	"DDDDDDDDDDDDDDDD",
	"DGDDDGDDDGDDDGDD",
	".D...D...D...D..",
]

## The house roof's browns (light, mid, dark) and their replacements.
const ROOF_BROWNS := [Color("94785c"), Color("79584f"), Color("563a3f")]
const ROOFS := {
	&"red": [Color("d95763"), Color("b13e53"), Color("6e2a45")],
	&"blue": [Color("4f8ad8"), Color("3b5dc9"), Color("29366f")],
	&"slate": [Color("94b0c2"), Color("566c86"), Color("333c57")],
}

var _source: Image


func _initialize() -> void:
	_source = Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	_source.convert(Image.FORMAT_RGBA8)
	var atlas := Image.create_empty(TownTiles.ATLAS_SIZE.x * T, TownTiles.ATLAS_SIZE.y * T, false, Image.FORMAT_RGBA8)
	var grass := _tile(CUTS[&"grass"][0])
	for tile_name: StringName in CUTS:
		var cut: Array = CUTS[tile_name]
		_put(atlas, tile_name, _over(grass, _tile(cut[0])) if cut[1] else _tile(cut[0]))
	var shore := _tile(CUTS[&"shore_north"][0])
	shore.flip_y()
	_put(atlas, &"shore_south", shore)
	for i in WATER.size():
		atlas.blit_rect(_tile(WATER[i]), Rect2i(0, 0, T, T), (TownTiles.TILES[&"water"] + Vector2i(i, 0)) * T)
	_put(atlas, &"tall_grass", _draw(grass, TALL_GRASS, 0, true))
	_put(atlas, &"ledge_down", _draw(grass, LEDGE, 7, false))
	for roof: StringName in TownTiles.HOUSES:
		atlas.blit_rect(_house(ROOFS.get(roof, [])), Rect2i(Vector2i.ZERO, TownTiles.HOUSE_SIZE * T), TownTiles.HOUSES[roof] * T)
	var error := atlas.save_png(TownTiles.ATLAS)
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), TownTiles.ATLAS])
	quit()


func _tile(coords: Vector2i) -> Image:
	return _source.get_region(Rect2i(coords * T, Vector2i(T, T)))


func _put(atlas: Image, tile_name: StringName, tile: Image) -> void:
	atlas.blit_rect(tile, Rect2i(0, 0, T, T), TownTiles.TILES[tile_name] * T)


func _over(base: Image, top: Image) -> Image:
	var image := base.duplicate() as Image
	image.blend_rect(top, Rect2i(0, 0, T, T), Vector2i.ZERO)
	return image


## Paints an ASCII pattern (L light, G dark, D deepest green) onto a copy of
## `base`, starting at row `top`. `tiled` repeats an 8x8 pattern 2x2.
func _draw(base: Image, rows: Array, top: int, tiled: bool) -> Image:
	var image := base.duplicate() as Image
	var colors := {"L": GRASS_LIGHT, "G": GRASS_DARK, "D": GRASS_DEEP}
	var offsets := [Vector2i(0, 0), Vector2i(8, 0), Vector2i(0, 8), Vector2i(8, 8)] if tiled else [Vector2i.ZERO]
	for offset: Vector2i in offsets:
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] != ".":
					image.set_pixel(offset.x + x, offset.y + top + y, colors[row[x]])
	return image


## The 5x5 house, with its roof recolored to `roof` (empty = original wood).
## The roof is everything above a shallow V from the eaves to the gable.
func _house(roof: Array) -> Image:
	var image := _source.get_region(Rect2i(HOUSE * T, TownTiles.HOUSE_SIZE * T))
	if roof.is_empty():
		return image
	var middle := image.get_width() / 2.0
	for y in image.get_height():
		for x in image.get_width():
			if y > 36.0 + absf(x - middle) * 18.0 / 37.0:
				continue
			var shade := ROOF_BROWNS.find(image.get_pixel(x, y))
			if shade >= 0:
				image.set_pixel(x, y, roof[shade])
	return image
