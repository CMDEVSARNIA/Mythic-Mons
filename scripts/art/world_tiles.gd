class_name WorldTiles
extends RefCounted
## Layout of assets/world/world_tiles.png, the atlas every map is painted
## with. tools/import_world_art.gd builds it from ArMM1998's CC0 overworld
## sheet, plus interior tiles drawn in that sheet's colors.

const ATLAS := "res://assets/world/world_tiles.png"
const ATLAS_SIZE := Vector2i(20, 7)

## Single tiles: outdoors on the top row, indoors on the bottom row.
const TILES := {
	&"grass": Vector2i(0, 0),
	&"tall_grass": Vector2i(1, 0),
	&"path": Vector2i(2, 0),
	&"flowers": Vector2i(3, 0),
	&"sand": Vector2i(4, 0),
	&"ledge_down": Vector2i(5, 0),
	&"tree": Vector2i(6, 0),
	&"cliff": Vector2i(7, 0),
	&"fence": Vector2i(8, 0),
	## Water with land along its north edge (a line of foam on top).
	&"shore_north": Vector2i(9, 0),
	## Water with land along its south edge (foam along the bottom).
	&"shore_south": Vector2i(10, 0),
	## Open water: the first of four tiles that repeat as a 2x2 pattern.
	&"water": Vector2i(11, 0),
	&"floor": Vector2i(0, 6),
	&"indoor_wall": Vector2i(1, 6),
	&"shelf": Vector2i(2, 6),
	&"table": Vector2i(3, 6),
	&"bed": Vector2i(4, 6),
	&"mat": Vector2i(5, 6),
	&"counter": Vector2i(6, 6),
	&"mart_shelf": Vector2i(7, 6),
	&"plant": Vector2i(8, 6),
	&"crate": Vector2i(9, 6),
	&"void": Vector2i(10, 6),
}
const WATER_TILES: Array[StringName] = [&"water", &"shore_north", &"shore_south"]

const HOUSE_SIZE := Vector2i(5, 5)
## A house's door, counted from its top-left tile.
const HOUSE_DOOR := Vector2i(2, 4)
## Roof color -> the house's top-left tile in the atlas.
const HOUSES := {
	&"wood": Vector2i(0, 1),
	&"red": Vector2i(5, 1),
	&"blue": Vector2i(10, 1),
	&"slate": Vector2i(15, 1),
}


## The atlas tile for open water at `cell`, so the ripples line up.
static func water_at(cell: Vector2i) -> Vector2i:
	return TILES[&"water"] + Vector2i(posmod(cell.x, 2) + 2 * posmod(cell.y, 2), 0)
