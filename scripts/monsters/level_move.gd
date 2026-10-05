class_name LevelMove
extends Resource
## One learnset entry: the move a species learns on reaching `level`.

@export_range(1, 100) var level := 1
@export var move: MoveData
