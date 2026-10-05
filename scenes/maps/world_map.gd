class_name WorldMap
extends Node2D
## Root script of every map scene (towns, routes, interiors).
##
## Expected children:
##   Ground     TileMapLayer painted with the overworld TileSet. Add more layers
##              (decor, overhead) freely; terrain is read from the topmost tile.
##   Entities   Node2D with Y Sort enabled: NPCs, signs, field obstacles.
##              The player is moved in here when the map loads.
##   Warps      Warp areas (doors, map edges).
##   Spawns     SpawnPoint markers that warps and Fly arrive at.

@export var display_name := "???"
## Visited towns become Fly destinations.
@export var is_town := false
## Interiors and caves turn this off.
@export var allow_fly := true
## Track id played by the Audio autoload (see Songs, assets/audio/music/).
@export var music: StringName = &"town"

@export_group("Wild Encounters")
## Chance of an encounter per step in tall grass.
@export_range(0.0, 1.0, 0.01) var encounter_rate := 0.1
## Species ids (files in res://data/species/). Repeat an id to make it more common.
@export var wild_monsters: Array[StringName] = []
## Wild monsters appear at a random level from x to y.
@export var wild_levels := Vector2i(2, 4)
## Species met while surfing here (same levels). Empty = quiet water.
@export var water_monsters: Array[StringName] = []
## Chance of an encounter per step while surfing.
@export_range(0.0, 1.0, 0.01) var water_encounter_rate := 0.05

var _layers: Array[TileMapLayer] = []
var _bounds := Rect2i()

@onready var entities: Node2D = $Entities
@onready var spawns: Node = $Spawns


func _ready() -> void:
	for child in get_children():
		if child is TileMapLayer:
			var used: Rect2i = child.get_used_rect()
			_bounds = used if _layers.is_empty() else _bounds.merge(used)
			_layers.append(child)


## The cell's terrain tag (see Terrain), from the topmost layer that sets one.
func get_terrain(cell: Vector2i) -> StringName:
	for i in range(_layers.size() - 1, -1, -1):
		var data := _layers[i].get_cell_tile_data(cell)
		if data:
			var terrain: StringName = data.get_custom_data(&"terrain")
			if not terrain.is_empty():
				return terrain
	return Terrain.NONE


## What pressing A on the cell's tile says (see EXAMINE in
## tools/build_world.gd), or "" if there's nothing to read.
func get_examine_text(cell: Vector2i) -> String:
	for i in range(_layers.size() - 1, -1, -1):
		var data := _layers[i].get_cell_tile_data(cell)
		if data and data.has_custom_data(&"examine"):
			var text: String = data.get_custom_data(&"examine")
			if not text.is_empty():
				return text
	return ""


## Cells covered by any tile layer. Actors can't walk outside it.
func get_bounds() -> Rect2i:
	return _bounds


func is_in_bounds(cell: Vector2i) -> bool:
	return _bounds.has_point(cell)


## The SpawnPoint named `id`, falling back to "default", then to the first one.
func get_spawn(id: StringName) -> SpawnPoint:
	var spawn := spawns.get_node_or_null(NodePath(id)) as SpawnPoint
	if spawn == null:
		spawn = spawns.get_node_or_null(^"default") as SpawnPoint
	if spawn == null and spawns.get_child_count() > 0:
		spawn = spawns.get_child(0) as SpawnPoint
	return spawn


## Returns a species id if a step onto `terrain` (tall grass, or water while
## surfing) triggers a wild encounter, else &"".
func roll_encounter(terrain: StringName = Terrain.TALL_GRASS) -> StringName:
	var on_water := terrain == Terrain.WATER
	var pool := water_monsters if on_water else wild_monsters
	if pool.is_empty() or randf() >= (water_encounter_rate if on_water else encounter_rate):
		return &""
	return pool.pick_random()


## Camera limits in pixels. Maps smaller than the screen get centered.
func get_camera_limits(view_size: Vector2) -> Rect2:
	var rect := Rect2(Rect2i(_bounds.position * Grid.TILE_SIZE, _bounds.size * Grid.TILE_SIZE))
	var pad := (view_size - rect.size).max(Vector2.ZERO) * 0.5
	return rect.grow_individual(pad.x, pad.y, pad.x, pad.y)
