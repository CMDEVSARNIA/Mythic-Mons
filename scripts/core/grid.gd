class_name Grid
extends RefCounted
## Tile-grid constants and conversions shared by every grid-based system.
##
## Convention: a node standing "on" a cell sits at the cell's CENTER, which is
## also what TileMapLayer.map_to_local() returns. Maps live at the origin, so
## local and global coordinates match.

const TILE_SIZE := 16
const HALF_TILE := Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)

## Order matches the rows of every character sprite sheet (down, up, left, right).
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]


static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE) + HALF_TILE


static func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / TILE_SIZE).floor())


## Sprite-sheet row (and DIRECTIONS index) for a facing direction.
static func direction_index(dir: Vector2i) -> int:
	return maxi(DIRECTIONS.find(dir), 0)
