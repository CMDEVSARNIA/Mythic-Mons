class_name Terrain
extends RefCounted
## Values stored in the TileSet's "terrain" custom data layer.
## Tiles without special behavior leave it empty (&"").

const NONE := &""
const TALL_GRASS := &"tall_grass"   ## Rolls wild encounters when stepped on.
const WATER := &"water"             ## Surfable.
const LEDGE_DOWN := &"ledge_down"   ## One-way hop when approached from above.
const LEDGE_LEFT := &"ledge_left"
const LEDGE_RIGHT := &"ledge_right"

const _LEDGE_DIRECTIONS := {
	LEDGE_DOWN: Vector2i.DOWN,
	LEDGE_LEFT: Vector2i.LEFT,
	LEDGE_RIGHT: Vector2i.RIGHT,
}


## The direction a ledge can be jumped in, or Vector2i.ZERO if it isn't a ledge.
static func ledge_direction(terrain: StringName) -> Vector2i:
	return _LEDGE_DIRECTIONS.get(terrain, Vector2i.ZERO)
