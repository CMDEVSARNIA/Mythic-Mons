class_name Player
extends GridActor
## The player character: reads input, interacts with whatever it faces, and
## owns the field moves that change how it moves (SURF, ledge hops).
##
## Controls: arrows/WASD move, hold Shift/X to run, Z/Space interacts.

## A tap on a new direction only turns; it must be held this long to walk.
const TURN_DELAY := 0.1
## Emerald's running shoes and surfing both cover a tile in 8 frames.
const RUN_SPEED := 7.5
const SURF_SPEED := 7.5

const _MOVE_ACTIONS := {
	&"move_down": Vector2i.DOWN,
	&"move_up": Vector2i.UP,
	&"move_left": Vector2i.LEFT,
	&"move_right": Vector2i.RIGHT,
}

var is_surfing := false

var _lock_count := 0
var _turn_timer := 0.0
var _held: Array[Vector2i] = [] # Held directions, most recently pressed last.

@onready var camera: Camera2D = $Visual/Camera2D
@onready var surf_mount: Sprite2D = $Visual/SurfMount


## Blocks player control during dialogue, menus, cutscenes and map changes.
## Calls nest: every lock() needs a matching unlock().
func lock() -> void:
	_lock_count += 1


func unlock() -> void:
	_lock_count = maxi(_lock_count - 1, 0)


func is_locked() -> bool:
	return _lock_count > 0


## Standing still and accepting input (safe to open menus or interact).
func is_idle() -> bool:
	return not is_moving and not is_locked()


## Places the player on a freshly loaded map.
func arrive(cell: Vector2i, dir: Vector2i) -> void:
	place_at(cell, dir)
	if is_surfing and (_map == null or _map.get_terrain(cell) != Terrain.WATER):
		set_surfing(false)


func set_camera_limits(limits: Rect2) -> void:
	camera.limit_left = floori(limits.position.x)
	camera.limit_top = floori(limits.position.y)
	camera.limit_right = ceili(limits.end.x)
	camera.limit_bottom = ceili(limits.end.y)
	camera.reset_smoothing()


func _physics_process(delta: float) -> void:
	_poll_directions()
	super(delta)


func _process(_delta: float) -> void:
	if not is_surfing:
		return
	# Gentle bob while riding the surf mount.
	var time := Time.get_ticks_msec()
	var bob := roundf(sin(time * 0.006))
	sprite.position.y = bob - 2.0
	surf_mount.position.y = 3.0 + bob
	surf_mount.frame = int(time / 250.0) % 2
	surf_mount.flip_h = facing == Vector2i.RIGHT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"confirm") and is_idle():
		get_viewport().set_input_as_handled()
		_interact()


func _idle_update(delta: float, just_stepped: bool) -> void:
	if is_locked():
		return
	var dir: Vector2i = _held.back() if not _held.is_empty() else Vector2i.ZERO
	if dir == Vector2i.ZERO:
		_turn_timer = 0.0
		return
	if dir != facing and not just_stepped:
		# From a standstill a tap only turns; holding the key then starts walking.
		face(dir)
		_turn_timer = TURN_DELAY
		return
	if _turn_timer > 0.0:
		_turn_timer -= delta
		return
	_try_step(dir)


func _try_step(dir: Vector2i) -> void:
	var target := get_cell() + dir
	var terrain := _map.get_terrain(target) if _map else Terrain.NONE
	# Ledges are solid, except that they can be hopped over in their direction.
	if not is_surfing and Terrain.ledge_direction(terrain) == dir and can_step(dir, target):
		Audio.play_sfx(&"jump")
		start_step(dir, 2, walk_speed, true)
		return
	if not can_step(dir):
		Audio.play_sfx(&"bump")
		bump(dir)
		return
	if is_surfing and terrain != Terrain.WATER:
		set_surfing(false) # Hop back onto land.
		start_step(dir, 1, walk_speed, true)
		return
	var running := Input.is_action_pressed(&"run")
	start_step(dir, 1, SURF_SPEED if is_surfing else (RUN_SPEED if running else walk_speed))


func _on_step_finished(cell: Vector2i) -> void:
	for area in query_cell(cell, PhysicsLayers.TRIGGERS, true):
		if area.has_method(&"on_player_entered"):
			area.on_player_entered(self)
			return
	if _map and _map.get_terrain(cell) == Terrain.TALL_GRASS:
		var species := _map.roll_encounter()
		if not species.is_empty():
			Events.wild_encounter.emit(species)


## Presses A on the faced cell: talk, read, use a field move, or start surfing.
func _interact() -> void:
	lock()
	var target := get_cell() + facing
	var handled := false
	for body in query_cell(target, PhysicsLayers.INTERACT_MASK):
		if body.has_method(&"interact"):
			await body.interact(self)
			handled = true
			break
	if not handled and not is_surfing and _map and _map.get_terrain(target) == Terrain.WATER:
		await _offer_surf()
	unlock()


func _offer_surf() -> void:
	if not GameState.can_use_field_move(&"surf"):
		await Dialogue.say(["The water is dyed a deep blue..."])
		return
	if await Dialogue.ask("The water is dyed a deep blue...\nWould you like to SURF?") != 0:
		return
	set_surfing(true)
	if not can_step(facing): # Something else is already on that water tile.
		set_surfing(false)
		return
	Audio.play_sfx(&"surf")
	start_step(facing, 1, walk_speed, true)


func set_surfing(on: bool) -> void:
	is_surfing = on
	surf_mount.visible = on
	if on:
		collision_mask &= ~PhysicsLayers.WATER
	else:
		collision_mask |= PhysicsLayers.WATER
		sprite.position = Vector2.ZERO


func _poll_directions() -> void:
	for action: StringName in _MOVE_ACTIONS:
		var dir: Vector2i = _MOVE_ACTIONS[action]
		if Input.is_action_pressed(action):
			if dir not in _held:
				_held.append(dir)
		else:
			_held.erase(dir)
