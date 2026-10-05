class_name Trainer
extends NPC
## An NPC who battles. `data` (a TrainerData) says who they are, their team
## and what they say. Until beaten they watch `sight` tiles straight ahead:
## the player stepping into view is spotted (Player checks after every step),
## and Main has the trainer walk over with notice(), then talk. Talking to
## them starts the battle too. Once beaten (data.defeat_flag() is set) they
## just say their `after` lines.

const EXCLAIM := preload("res://assets/placeholder/effects/exclaim.png")

@export var data: TrainerData
@export_range(1, 8) var sight := 4


func _ready() -> void:
	super()
	add_to_group(&"trainers")


func is_defeated() -> bool:
	return data == null or GameState.has_flag(data.defeat_flag())


## True if this trainer, still unbeaten, has `player` straight ahead within
## `sight` tiles with nothing in between.
func can_see(player: GridActor) -> bool:
	if is_defeated() or _talking or is_moving:
		return false
	var offset := player.get_cell() - get_cell()
	var distance := absi(offset.x) + absi(offset.y)
	if distance == 0 or distance > sight or offset != facing * distance:
		return false
	for i in range(1, distance):
		if not is_cell_free(get_cell() + facing * i):
			return false
	return true


## A "!" pops up over the trainer, who then walks up to `player`.
func notice(player: GridActor) -> void:
	_talking = true
	Audio.play_sfx(&"exclaim")
	var mark := Sprite2D.new()
	mark.texture = EXCLAIM
	mark.position = Vector2(0, -16)
	visual.add_child(mark)
	await get_tree().create_timer(0.8).timeout
	mark.queue_free()
	while get_cell() + facing != player.get_cell() and can_step(facing):
		start_step(facing)
		await step_finished
	_talking = false


func _talk() -> void:
	if is_defeated():
		await Dialogue.say(_fill(data.after if data else lines))
		return
	await Dialogue.say(_fill(data.intro))
	Events.trainer_battle.emit(data)


func _fill(pages: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for page in pages:
		out.append(page.replace("{PLAYER}", GameState.player_name))
	return out
