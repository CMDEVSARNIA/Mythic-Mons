class_name GridActor
extends CharacterBody2D
## Base class for anything that walks on the tile grid (the player and NPCs).
##
## Movement model: when a step starts, the physics body jumps straight to the
## destination cell, so the tile is reserved at once and every other actor's
## collision check sees it as taken. Only the `Visual` child is offset back to
## the starting cell and slid to zero over the step. The result is tile-locked
## logic with smooth pixel motion, and two actors can never claim the same cell.
##
## Expected children:
##   CollisionShape2D   12x12 rectangle centered on the cell
##   Shadow             (optional) Sprite2D shown under the actor while hopping
##   Visual             Node2D that receives the slide offset
##     Sprite2D         3 columns (stand, step A, step B) x 4 rows (down, up, left, right)

signal step_finished(cell: Vector2i)

## Height in pixels of the arc used for ledge jumps and surf mount/dismount hops.
const HOP_HEIGHT := 6.0

## Tiles per second. Emerald walks one tile every 16 frames at 60 FPS = 3.75.
@export var walk_speed := 3.75
@export_enum("Down", "Up", "Left", "Right") var start_facing := 0

var facing := Vector2i.DOWN
var is_moving := false

var _step_offset := Vector2.ZERO # Visual offset at the start of the current step.
var _step_duration := 1.0
var _step_progress := 0.0
var _step_hop := false
var _bumping := false
var _foot := 0
var _map: WorldMap

@onready var visual: Node2D = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var shadow: Sprite2D = get_node_or_null(^"Shadow")


func _enter_tree() -> void:
	_map = _find_map()


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	face(Grid.DIRECTIONS[start_facing])


func _physics_process(delta: float) -> void:
	if is_moving:
		_advance(delta)
	else:
		_idle_update(delta, false)


## Called every physics frame while standing still. `just_stepped` is true when
## called right after a step ends, so subclasses can chain steps without a pause.
func _idle_update(_delta: float, _just_stepped: bool) -> void:
	pass


## Called when the actor arrives on a new cell (not after bumps).
func _on_step_finished(_cell: Vector2i) -> void:
	pass


func get_cell() -> Vector2i:
	return Grid.world_to_cell(global_position)


func get_map() -> WorldMap:
	return _map


## Instantly puts the actor on `cell`, cancelling any step in progress.
func place_at(cell: Vector2i, dir := facing) -> void:
	global_position = Grid.cell_to_world(cell)
	is_moving = false
	_bumping = false
	_step_hop = false
	_step_progress = 0.0
	face(dir)
	_update_visual()


func face(dir: Vector2i) -> void:
	if dir == Vector2i.ZERO:
		return
	facing = dir
	if sprite:
		_update_frame()


## True if a one-tile step in `dir` from `from_cell` is allowed.
func can_step(dir: Vector2i, from_cell := get_cell()) -> bool:
	return is_cell_free(from_cell + dir)


## True if `cell` is inside the map and this body's shape, placed there, would
## touch nothing in its collision_mask (solid tiles, water, actors, obstacles).
## Because every actor's body already sits on the cell it is moving into,
## this also stops two actors from claiming the same tile.
func is_cell_free(cell: Vector2i) -> bool:
	if _map and not _map.is_in_bounds(cell):
		return false
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = _collision.shape
	params.transform = Transform2D(0.0, Grid.cell_to_world(cell))
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(params, 1).is_empty()


## Moves `tiles` cells in `dir` at `speed` tiles per second. Check collision
## first with can_step(). `hop` draws a jump arc (ledges, surf mount/dismount).
func start_step(dir: Vector2i, tiles := 1, speed := walk_speed, hop := false) -> void:
	face(dir)
	var start := global_position
	global_position += Vector2(dir * Grid.TILE_SIZE * tiles)
	_begin_motion(start - global_position, tiles / speed, hop)


## Walks in place against something solid for one step's duration.
func bump(dir: Vector2i, speed := walk_speed) -> void:
	face(dir)
	_begin_motion(Vector2.ZERO, 1.0 / speed, false)
	_bumping = true


## Physics objects whose shapes cover the center of `cell`: bodies, or areas
## when `areas` is true. The actor itself is excluded.
func query_cell(cell: Vector2i, mask: int, areas := false) -> Array[Object]:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = Grid.cell_to_world(cell)
	params.collision_mask = mask
	params.collide_with_areas = areas
	params.collide_with_bodies = not areas
	params.exclude = [get_rid()]
	var found: Array[Object] = []
	for hit in get_world_2d().direct_space_state.intersect_point(params, 8):
		if hit.collider:
			found.append(hit.collider)
	return found


func _begin_motion(offset: Vector2, duration: float, hop: bool) -> void:
	_step_offset = offset
	_step_duration = duration
	_step_progress = 0.0
	_step_hop = hop
	_bumping = false
	_foot = 1 - _foot
	is_moving = true
	_update_visual()


func _advance(delta: float) -> void:
	_step_progress += delta / _step_duration
	if _step_progress < 1.0:
		_update_visual()
		return
	var overflow := (_step_progress - 1.0) * _step_duration
	var was_bump := _bumping
	is_moving = false
	_bumping = false
	_step_progress = 0.0
	_update_visual()
	if not was_bump:
		var cell := get_cell()
		_on_step_finished(cell)
		step_finished.emit(cell)
	# Let input/AI start the next step this same frame so held movement never stutters.
	_idle_update(0.0, true)
	if is_moving and overflow > 0.0:
		_advance(overflow)


func _update_visual() -> void:
	var t := _step_progress if is_moving else 1.0
	var ground := _step_offset * (1.0 - t)
	var lift := sin(t * PI) * HOP_HEIGHT if is_moving and _step_hop else 0.0
	visual.position = ground - Vector2(0.0, lift)
	if shadow:
		shadow.visible = is_moving and _step_hop
		shadow.position = ground
	_update_frame()


func _update_frame() -> void:
	var column := 0
	if is_moving and not _step_hop and _step_progress < 0.5:
		column = 1 + _foot
	sprite.frame = Grid.direction_index(facing) * 3 + column


func _find_map() -> WorldMap:
	var node := get_parent()
	while node:
		if node is WorldMap:
			return node
		node = node.get_parent()
	return null
