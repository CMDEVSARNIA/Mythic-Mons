@tool
class_name Rug
extends Node2D
## A rug from FurniturePieces, flat on the floor: nothing blocks, and since
## the node is the rug's top-left corner, anyone standing on it is drawn on top.

# Loaded with the script: a texture first loaded inside _draw() shows up white.
const ATLAS := preload("res://assets/interiors/furniture.png")

@export var piece: StringName = &"rug_round":
	set(value):
		piece = value
		queue_redraw()


func _draw() -> void:
	if not FurniturePieces.PIECES.has(piece):
		return
	var region := FurniturePieces.region(piece)
	draw_texture_rect_region(ATLAS, Rect2(Vector2.ZERO, region.size), Rect2(region))
