class_name Boulder
extends StaticBody2D
## A big round boulder. Once a monster has used STRENGTH on the map (press A
## on any boulder with the SHADE BADGE), walking into a boulder shoves it one
## tile, as in Emerald. Boulders go back to where they started when the map
## reloads, so a stuck puzzle can always be retried by leaving and coming back.

const PUSH_TIME := 0.25

@export_multiline var description := "It's a big boulder, but a\nMONSTER may be able to\npush it aside."

var is_moving := false

@onready var _sprite: Sprite2D = $Sprite2D


func interact(_player: GridActor) -> void:
	var map := _map()
	if map and map.strength_on:
		await Dialogue.say(["STRENGTH made it possible\nto move boulders around."])
		return
	await Dialogue.say([description])
	if not GameState.can_use_field_move(&"strength"):
		return
	if await Dialogue.ask("Would you like to use\nSTRENGTH?") != 0:
		return
	if map:
		map.strength_on = true
	Audio.play_sfx(&"strength")
	var lead := GameState.lead_monster()
	var who := lead.get_display_name() if lead else GameState.player_name
	await Dialogue.say(["%s used\nSTRENGTH!" % who, "STRENGTH made it\npossible to move\nboulders around."])


## Shoves the boulder one tile in `dir` and returns true, or returns false and
## stays put when the way is blocked (walls, water, people, other obstacles,
## doors and other step-on spots).
func push(dir: Vector2i) -> bool:
	if is_moving:
		return false
	var cell := Grid.world_to_cell(global_position) + dir
	if not _is_free(cell):
		return false
	is_moving = true
	Audio.play_sfx(&"strength")
	# The body jumps to the new cell at once, so nothing can walk into it
	# mid-push; only the sprite slides.
	global_position = Grid.cell_to_world(cell)
	_sprite.position = Vector2(-dir * Grid.TILE_SIZE)
	var tween := create_tween()
	tween.tween_property(_sprite, "position", Vector2.ZERO, PUSH_TIME)
	tween.tween_callback(func() -> void: is_moving = false)
	return true


func _is_free(cell: Vector2i) -> bool:
	var map := _map()
	if map and not map.is_in_bounds(cell):
		return false
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = Grid.cell_to_world(cell)
	params.exclude = [get_rid()]
	params.collision_mask = PhysicsLayers.WALKER_MASK
	if not space.intersect_point(params, 1).is_empty():
		return false
	params.collision_mask = PhysicsLayers.TRIGGERS
	params.collide_with_areas = true
	params.collide_with_bodies = false
	return space.intersect_point(params, 1).is_empty()


func _map() -> WorldMap:
	var node := get_parent()
	while node and not node is WorldMap:
		node = node.get_parent()
	return node as WorldMap
