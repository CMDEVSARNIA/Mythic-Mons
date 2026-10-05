class_name SpawnPoint
extends Marker2D
## Where the player appears when arriving through a Warp or Fly.
## The node's name is the id that warps refer to ("default", "fly", ...).

@export_enum("Down", "Up", "Left", "Right") var facing := 0


func get_cell() -> Vector2i:
	return Grid.world_to_cell(global_position)


func get_direction() -> Vector2i:
	return Grid.DIRECTIONS[facing]
