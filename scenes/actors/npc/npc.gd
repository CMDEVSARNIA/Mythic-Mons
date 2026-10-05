class_name NPC
extends GridActor
## A townsperson who wanders near home and talks when the player presses A.

@export var sprite_sheet: Texture2D
@export var lines: PackedStringArray = ["Hello there!"]
## How far, in tiles, the NPC may wander from where it was placed. 0 = stays put.
@export_range(0, 8) var wander_radius := 2
## Random pause between wander decisions, in seconds (min, max).
@export var wander_interval := Vector2(1.0, 3.0)
## After talking, restore the player's whole party (e.g. MOM).
@export var heals_party := false

var _home := Vector2i.ZERO
var _timer := 0.0
var _talking := false


func _ready() -> void:
	super()
	if sprite_sheet:
		sprite.texture = sprite_sheet
	_home = get_cell()
	_timer = randf_range(wander_interval.x, wander_interval.y)


func interact(player: GridActor) -> void:
	_talking = true
	face(-player.facing)
	await _talk()
	_talking = false


## What happens when the player talks to this NPC. Override for story NPCs.
func _talk() -> void:
	await Dialogue.say(lines)
	if heals_party and not GameState.party.is_empty():
		GameState.heal_party()
		Audio.play_sfx(&"heal")
		await Dialogue.say(["Your MONSTERS are\nfully rested!"])


func _idle_update(delta: float, _just_stepped: bool) -> void:
	if _talking or wander_radius <= 0:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(wander_interval.x, wander_interval.y)
	var dir: Vector2i = Grid.DIRECTIONS.pick_random()
	var target := get_cell() + dir
	var from_home := target - _home
	var too_far := maxi(absi(from_home.x), absi(from_home.y)) > wander_radius
	if randf() < 0.35 or too_far or not _is_walkable(target) or not can_step(dir):
		face(dir)
		return
	start_step(dir)


## NPCs never wander onto warps, water, ledges or tall grass.
func _is_walkable(cell: Vector2i) -> bool:
	if not query_cell(cell, PhysicsLayers.TRIGGERS, true).is_empty():
		return false
	return _map == null or _map.get_terrain(cell) == Terrain.NONE
