extends SceneTree
## Builds the world's art from ArMM1998's CC0 overworld sheet
## (assets/world/source/), so towns, routes, interiors, field objects and the
## battle backdrop all share one style:
##
##   world_tiles.png        every map tile, laid out as in WorldTiles
##   signpost.png, cut_tree.png, smash_rock.png, pc.png
##   battle_background.png  240x160, platforms where BattleScene expects them
##
##   godot --headless --path . --script res://tools/import_world_art.gd
##   godot --headless --path . --import
##
## Tiles with see-through parts are laid over grass (or floor indoors). The
## sheet has no tall grass, ledges, interiors or cracked boulders, so those are
## drawn here in its colors, and the house gets red, blue, slate and teal roofs for
## the MONSTER CENTER, MART, lab and GYM.

const SOURCE := "res://assets/world/source/zelda_like_overworld.png"
const OUT_DIR := "res://assets/world/"
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
## Props from the sheet, laid over the wooden floor.
const PROPS := {
	&"plant": Vector2i(35, 1),
	&"crate": Vector2i(30, 0),
}
## The 2x2 open-water pattern, in WorldTiles.water_at() order.
const WATER := [Vector2i(16, 0), Vector2i(17, 0), Vector2i(16, 1), Vector2i(17, 1)]
const HOUSE := Vector2i(6, 0)
const SIGNPOST := Vector2i(34, 2)
const BUSH := Vector2i(2, 14)

## The sheet's colors, by letter, for the patterns below.
const COLORS := {
	"K": Color("201729"), # ink outline
	"d": Color("563a3f"), "m": Color("79584f"), "l": Color("94785c"), "p": Color("a89080"), # wood, dark to pale
	"c": Color("e0caca"), "W": Color("f4f4f4"), "w": Color("c8b8c0"), # highlights, sheets
	"Q": Color("d8c4b8"), "q": Color("c4aca0"), # wallpaper
	"B": Color("3b5dc9"), "b": Color("29366f"), "R": Color("b13e53"), "r": Color("6e2a45"), "o": Color("d95763"),
	"Y": Color("e3b26f"), "y": Color("b8803f"), "P": Color("9a5aa0"), "C": Color("73eff7"), "n": Color("333c57"),
	"G": Color("29973b"), "g": Color("2d5b3f"), # book greens
	"s": Color(Color("201729"), 0.4), # soft shadow
}
## Grass and foliage greens, for tall grass, ledges and the CUT tree.
const GREENS := {
	"L": Color("6add4b"), "G": Color("29973b"), "D": Color("2d5b3f"),
	"F": Color("2eca35"), "f": Color("62eb3d"), "O": Color("302639"),
	"m": Color("79584f"), "d": Color("563a3f"),
}

# 8x8 clump, repeated four times over grass.
const TALL_GRASS := [
	".D....D.",
	"DLD..DLD",
	"DLLDDLLD",
	"DGLLLLGD",
	".DGGGGD.",
	"..DDDD..",
]
# Drawn over grass from row 7: a lit edge, the drop, and its shadow.
const LEDGE := [
	"LLLLLLLLLLLLLLLL",
	"GGGGGGGGGGGGGGGG",
	"GGGGGGGGGGGGGGGG",
	"DDDDDDDDDDDDDDDD",
	"DGDDDGDDDGDDDGDD",
	".D...D...D...D..",
]
const FLOOR := [
	"pppppppppppppppp",
	"llllllllllldllll",
	"lllmllllllldllll",
	"dddddddddddddddd",
	"ppppdppppppppppp",
	"llllldlllllllmll",
	"llllldllllllllll",
	"dddddddddddddddd",
	"pppppppppppdpppp",
	"lllmlllllllldlll",
	"llllllllllldllll",
	"dddddddddddddddd",
	"ppppppdppppppppp",
	"lllllldlllllllll",
	"llllllldllmlllll",
	"dddddddddddddddd",
]
const WALL := [
	"QQQqQQQQQQQqQQQQ",
	"QQQqQQQQQQQqQQQQ",
	"QQQqQQQQQQQqQQQQ",
	"QQQqQQQQQQQqQQQQ",
	"QQQqQQQQQQQqQQQQ",
	"QQQqQQQQQQQqQQQQ",
	"QQQqQQQQQQQqQQQQ",
	"QQQqQQQQQQQqQQQQ",
	"qqqqqqqqqqqqqqqq",
	"KKKKKKKKKKKKKKKK",
	"llllllllllllllll",
	"mmmdmmmmmmmdmmmm",
	"mmmdmmmmmmmdmmmm",
	"mmmdmmmmmmmdmmmm",
	"dddddddddddddddd",
	"KKKKKKKKKKKKKKKK",
]
const SHELF := [
	"KKKKKKKKKKKKKKKK",
	"KddddddddddddddK",
	"KdRRbBBGGyYRrbdK",
	"KdRrbBbGgYYRrBdK",
	"KdRrbBbGgYyRrBdK",
	"KdRrbBbGgYyRrBdK",
	"KllllllllllllldK",
	"KdmmmmmmmmmmmmdK",
	"KdGGYyBBRrPPGgdK",
	"KdGgYyBbRrPPGgdK",
	"KdGgYyBbRrPpGgdK",
	"KdGgYyBbRrPpGgdK",
	"KllllllllllllldK",
	"KdmmmmmmmmmmmmdK",
	"KddddddddddddddK",
	"KKKKKKKKKKKKKKKK",
]
const TABLE := [
	"................",
	"................",
	".KKKKKKKKKKKKKK.",
	".KccccccccccccK.",
	".KppppppppppppK.",
	".KppppppppppppK.",
	".KppppppppppppK.",
	".KppppppppppppK.",
	".KppppppppppppK.",
	".KllllllllllllK.",
	".KmmmmmmmmmmmmK.",
	".KKKKKKKKKKKKKK.",
	".KdK........KdK.",
	".KKK........KKK.",
	"................",
	"................",
]
const BED := [
	"..KKKKKKKKKKKK..",
	"..KddddddddddK..",
	"..KdWWWWWWWWdK..",
	"..KdWwwwwwwWdK..",
	"..KdWWWWWWWWdK..",
	"..KdBBBBBBBBdK..",
	"..KdBbBBBBbBdK..",
	"..KdBBBBBBBBdK..",
	"..KdBBbBBbBBdK..",
	"..KdBBBBBBBBdK..",
	"..KdBbBBBBbBdK..",
	"..KdBBBBBBBBdK..",
	"..KdbbbbbbbbdK..",
	"..KddddddddddK..",
	"..KmK......KmK..",
	"..KKK......KKK..",
]
const MAT := [
	"................",
	"................",
	".KKKKKKKKKKKKKK.",
	".KRRRRRRRRRRRRK.",
	".KRooooooooooRK.",
	".KRoRRoRRoRRoRK.",
	".KRooooooooooRK.",
	".KRoRRoRRoRRoRK.",
	".KRooooooooooRK.",
	".KRRRRRRRRRRRRK.",
	".KKKKKKKKKKKKKK.",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const COUNTER := [
	"KKKKKKKKKKKKKKKK",
	"cccccccccccccccc",
	"pppppppppppppppp",
	"pppppppppppppppp",
	"llllllllllllllll",
	"llllllllllllllll",
	"llllllllllllllll",
	"mmmmmmmmmmmmmmmm",
	"KKKKKKKKKKKKKKKK",
	"dmmmmmmddmmmmmmd",
	"dmllllmddmllllmd",
	"dmlmmlmddmlmmlmd",
	"dmllllmddmllllmd",
	"dmmmmmmddmmmmmmd",
	"dddddddddddddddd",
	"KKKKKKKKKKKKKKKK",
]
# A MART display: orbs on top, potions below.
const MART_SHELF := [
	"KKKKKKKKKKKKKKKK",
	"KddddddddddddddK",
	"KdnnnnnnnnnnnndK",
	"KdnnRRnnnnRRnndK",
	"KdnRRRRnnRRRRndK",
	"KdnWWWWnnWWWWndK",
	"KdnnWWnnnnWWnndK",
	"KllllllllllllldK",
	"KdnnnnnnnnnnnndK",
	"KdnnCCnnnnCCnndK",
	"KdnnPPnnnnPPnndK",
	"KdnPPPPnnPPPPndK",
	"KdnPWPPnnPWPPndK",
	"KdnPPPPnnPPPPndK",
	"KllllllllllllldK",
	"KKKKKKKKKKKKKKKK",
]
# A sapling, smaller and brighter than the bushes around it.
const CUT_TREE := [
	"................",
	"................",
	"......OOOO......",
	"....OOffFFOO....",
	"...OfffFFFFFO...",
	"..OFffFFFFFFGO..",
	"..OFFFFFFFFFGO..",
	"..OFFFFFFFFGGO..",
	"..OGFFFFFFGGGO..",
	"...OGGFFGGGGO...",
	"....OOGGGGOO....",
	"......OmdO......",
	"......OmdO......",
	".....OmmddO.....",
	".....OOOOOO.....",
	"................",
]
# The MONSTER CENTER's PC: a monitor with a blue screen, on its stand, with a keyboard.
const PC := [
	"................",
	"..KKKKKKKKKKKK..",
	"..KWwwwwwwwwwK..",
	"..KwKKKKKKKKwK..",
	"..KwKCCBBBBKwK..",
	"..KwKCBBBBBKwK..",
	"..KwKBBBBBbKwK..",
	"..KwKBBBbbbKwK..",
	"..KwKKKKKKKKwK..",
	"..KwwwwwwwGwwK..",
	"..KKKKKKKKKKKK..",
	".....KwwwwK.....",
	".KKKKKKKKKKKKKK.",
	".KWcWcWcWcWcWcK.",
	".KKKKKKKKKKKKKK.",
	"................",
]
const SMASH_ROCK := [
	"................",
	"................",
	".....KKKKKK.....",
	"...KKpplllKKK...",
	"..KpplllKllllK..",
	"..KplllllKlllmK.",
	".KplllllKKllmmK.",
	".KllllllKllmmmK.",
	".KlllllKlllmmmK.",
	".KlllmKKlllmmdK.",
	".KllllKllllmmdK.",
	".KmllllllmmmddK.",
	"..KmmmmmmmmddK..",
	"...KKKKKKKKKK...",
	"..ssssssssssss..",
	"................",
]

## The house roof's browns (light, mid, dark) and their replacements.
const ROOF_BROWNS := [Color("94785c"), Color("79584f"), Color("563a3f")]
const ROOFS := {
	&"red": [Color("d95763"), Color("b13e53"), Color("6e2a45")],
	&"blue": [Color("4f8ad8"), Color("3b5dc9"), Color("29366f")],
	&"slate": [Color("94b0c2"), Color("566c86"), Color("333c57")],
	&"teal": [Color("73eff7"), Color("38a7b0"), Color("257179")],
}

const SKY_TOP := Color("c8ecf8")
const SKY_LOW := Color("8cd0f0")

var _source: Image


func _initialize() -> void:
	_source = Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	_source.convert(Image.FORMAT_RGBA8)
	_save(_atlas(), WorldTiles.ATLAS)
	_save(_tile(SIGNPOST), OUT_DIR + "signpost.png")
	_save(_draw(_empty(), CUT_TREE, GREENS), OUT_DIR + "cut_tree.png")
	_save(_draw(_empty(), SMASH_ROCK, COLORS), OUT_DIR + "smash_rock.png")
	_save(_draw(_empty(), PC, COLORS), OUT_DIR + "pc.png")
	_save(_battle_background(), OUT_DIR + "battle_background.png")
	quit()


func _atlas() -> Image:
	var size := WorldTiles.ATLAS_SIZE * T
	var atlas := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var grass := _tile(CUTS[&"grass"][0])
	for tile_name: StringName in CUTS:
		var cut: Array = CUTS[tile_name]
		_put(atlas, tile_name, _over(grass, _tile(cut[0])) if cut[1] else _tile(cut[0]))
	var shore := _tile(CUTS[&"shore_north"][0])
	shore.flip_y()
	_put(atlas, &"shore_south", shore)
	for i in WATER.size():
		atlas.blit_rect(_tile(WATER[i]), Rect2i(0, 0, T, T), (WorldTiles.TILES[&"water"] + Vector2i(i, 0)) * T)
	_put(atlas, &"tall_grass", _draw(grass, TALL_GRASS, GREENS, Vector2i.ZERO, true))
	_put(atlas, &"ledge_down", _draw(grass, LEDGE, GREENS, Vector2i(0, 7)))
	for roof: StringName in WorldTiles.HOUSES:
		atlas.blit_rect(_house(ROOFS.get(roof, [])), Rect2i(Vector2i.ZERO, WorldTiles.HOUSE_SIZE * T), WorldTiles.HOUSES[roof] * T)

	var floor_tile := _draw(_empty(), FLOOR, COLORS)
	_put(atlas, &"floor", floor_tile)
	_put(atlas, &"indoor_wall", _draw(_empty(), WALL, COLORS))
	_put(atlas, &"shelf", _draw(_empty(), SHELF, COLORS))
	_put(atlas, &"table", _draw(floor_tile, TABLE, COLORS))
	_put(atlas, &"bed", _draw(floor_tile, BED, COLORS))
	_put(atlas, &"mat", _draw(floor_tile, MAT, COLORS))
	_put(atlas, &"counter", _draw(_empty(), COUNTER, COLORS))
	_put(atlas, &"mart_shelf", _draw(_empty(), MART_SHELF, COLORS))
	for prop: StringName in PROPS:
		_put(atlas, prop, _over(floor_tile, _tile(PROPS[prop])))
	var void_tile := _empty()
	void_tile.fill(COLORS["K"])
	_put(atlas, &"void", void_tile)
	return atlas


## Sky, a hedge on the horizon, a grass field, and the two platforms
## (centered where BattleScene puts the monsters' feet).
func _battle_background() -> Image:
	var image := Image.create_empty(240, 160, false, Image.FORMAT_RGBA8)
	for y in 52:
		for x in 240:
			var threshold := (((x % 2) * 2 + (y % 2)) + 0.5) / 4.0
			image.set_pixel(x, y, SKY_LOW if y / 52.0 > threshold else SKY_TOP)
	var grass := _tile(CUTS[&"grass"][0])
	for y in range(40, 160, T):
		for x in range(0, 240, T):
			image.blit_rect(grass, Rect2i(0, 0, T, T), Vector2i(x, y))
	var bush := _tile(BUSH)
	for row: Vector2i in [Vector2i(-8, 28), Vector2i(0, 36)]:
		for x in range(row.x, 240, T):
			image.blend_rect(bush, Rect2i(0, 0, T, T), Vector2i(x, row.y))
	for platform: Rect2 in [Rect2(176, 68, 46, 10), Rect2(64, 114, 56, 12)]:
		var center := platform.position
		var radius := platform.size
		_ellipse(image, center, radius, GREENS["D"])
		_ellipse(image, center + Vector2(0, -0.5), radius - Vector2(2, 1.5), GREENS["G"])
		_ellipse(image, center + Vector2(0, -1.5), radius - Vector2(6, 3.5), GREENS["L"])
		_ellipse(image, center + Vector2(0, -2.0), radius - Vector2(10, 5.0), Color("3abe41"))
	return image


func _ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
		for x in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			if ((Vector2(x, y) + Vector2(0.5, 0.5) - center) / radius).length_squared() <= 1.0:
				image.set_pixel(x, y, color)


func _tile(coords: Vector2i) -> Image:
	return _source.get_region(Rect2i(coords * T, Vector2i(T, T)))


func _empty() -> Image:
	return Image.create_empty(T, T, false, Image.FORMAT_RGBA8)


func _put(atlas: Image, tile_name: StringName, tile: Image) -> void:
	atlas.blit_rect(tile, Rect2i(0, 0, T, T), WorldTiles.TILES[tile_name] * T)


func _over(base: Image, top: Image) -> Image:
	var image := base.duplicate() as Image
	image.blend_rect(top, Rect2i(0, 0, T, T), Vector2i.ZERO)
	return image


## Paints an ASCII pattern onto a copy of `base`, each letter looked up in
## `colors` ("." is skipped). `tiled` repeats an 8x8 pattern 2x2.
func _draw(base: Image, rows: Array, colors: Dictionary, offset := Vector2i.ZERO, tiled := false) -> Image:
	var image := base.duplicate() as Image
	var copies := [Vector2i(0, 0), Vector2i(8, 0), Vector2i(0, 8), Vector2i(8, 8)] if tiled else [Vector2i.ZERO]
	for copy: Vector2i in copies:
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] == ".":
					continue
				var p := offset + copy + Vector2i(x, y)
				var color: Color = colors[row[x]]
				image.set_pixelv(p, image.get_pixelv(p).blend(color) if color.a < 1.0 else color)
	return image


## The 5x5 house, with its roof recolored to `roof` (empty = original wood).
## The roof is everything above a shallow V from the eaves to the gable.
func _house(roof: Array) -> Image:
	var image := _source.get_region(Rect2i(HOUSE * T, WorldTiles.HOUSE_SIZE * T))
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


func _save(image: Image, path: String) -> void:
	var error := image.save_png(path)
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), path])
