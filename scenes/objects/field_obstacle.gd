class_name FieldObstacle
extends StaticBody2D
## Something that blocks the way until a field move clears it: CUT trees,
## ROCK SMASH boulders. Like in Emerald, it comes back when the map reloads.

## Must match an entry in GameState.FIELD_MOVES.
@export var field_move: StringName = &"cut"
@export_multiline var description := "This tree looks like it\ncan be CUT down!"
@export var sfx: StringName = &"cut"

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D


func interact(_player: GridActor) -> void:
	if not GameState.can_use_field_move(field_move):
		await Dialogue.say([description])
		return
	var move_name := String(field_move).to_upper().replace("_", " ")
	if await Dialogue.ask("%s\nUse %s?" % [description, move_name]) == 0:
		await clear()


## Plays the break effect and frees the path.
func clear() -> void:
	_shape.set_deferred(&"disabled", true)
	Audio.play_sfx(sfx)
	var tween := create_tween()
	for i in 3:
		tween.tween_callback(_sprite.hide)
		tween.tween_interval(0.06)
		tween.tween_callback(_sprite.show)
		tween.tween_interval(0.06)
	tween.tween_property(_sprite, "scale", Vector2(1.4, 0.2), 0.12)
	await tween.finished
	queue_free()
