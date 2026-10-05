class_name TownTiles
extends RefCounted
## Outdoor tiles and houses converted from ArMM1998's CC0 "Zelda-like tilesets
## and sprites" by tools/import_town_tiles.gd. tools/build_world.gd paints a
## map tile from here when its name is listed, and from PixelArt's generated
## atlas (interiors) otherwise.

const ATLAS := "res://assets/tilesets/town_tiles.png"
const ATLAS_SIZE := Vector2i(20, 6)

## Single tiles, all in the atlas's top row.
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
