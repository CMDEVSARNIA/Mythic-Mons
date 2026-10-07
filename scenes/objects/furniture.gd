@tool
class_name Furniture
extends StaticBody2D
## A piece of furniture from FurniturePieces. A SOLID piece blocks its
## footprint of cells; a WALL piece hangs on a wall tile. Pressing A on either
## reads `lines`, like a sign. The node sits on the footprint's bottom-left
## cell, so it y-sorts with whoever stands in front of it.

# Loaded with the script: a texture first loaded inside _draw() shows up white.
const ATLAS := preload("res://assets/interiors/furniture.png")

@export var piece: StringName = &"bed_red":
	set(value):
		piece = value
		queue_redraw()
## What A shows. Empty = the piece's usual description.
@export var lines := PackedStringArray()
## Moves the picture, e.g. to hang a painting between two wall tiles.
@export var shift := Vector2i.ZERO:
	set(value):
		shift = value
		queue_redraw()

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint() or not FurniturePieces.PIECES.has(piece):
		return
	var tile := Grid.TILE_SIZE
	var footprint := _footprint()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(footprint * tile - Vector2i(2, 2))
	_shape.shape = shape
	_shape.position = Vector2((footprint.x - 1) * tile / 2.0, -(footprint.y - 1) * tile / 2.0)


func interact(_player: GridActor) -> void:
	await Dialogue.say(lines if not lines.is_empty() else FurniturePieces.lines_of(piece))


func _draw() -> void:
	if not FurniturePieces.PIECES.has(piece):
		return
	var region := FurniturePieces.region(piece)
	var tile := Grid.TILE_SIZE
	# Centered on the footprint, with its bottom edge on the footprint's.
	var corner := Vector2i(-tile / 2 + floori((_footprint().x * tile - region.size.x) / 2.0), tile / 2 - region.size.y)
	corner += FurniturePieces.nudge_of(piece) + shift
	draw_texture_rect_region(ATLAS, Rect2(corner, region.size), Rect2(region))


func _footprint() -> Vector2i:
	if FurniturePieces.kind_of(piece) == FurniturePieces.Kind.WALL:
		return Vector2i.ONE
	return FurniturePieces.footprint_of(piece)
