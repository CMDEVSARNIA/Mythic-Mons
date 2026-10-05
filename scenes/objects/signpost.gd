class_name Signpost
extends StaticBody2D
## A readable sign. Each entry in `lines` is one page of the text box.

@export var lines: PackedStringArray = ["A sign."]


func interact(_player: GridActor) -> void:
	await Dialogue.say(lines)
