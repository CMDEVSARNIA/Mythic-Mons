class_name BattleScene
extends Control
## Plays out one wild battle on screen. The rules live in Battle; this scene
## asks the player for actions and animates the events Battle returns.
##
##     var outcome: Battle.Outcome = await battle_scene.run(GameState.party, wild)

## How long routine battle text stays up before advancing on its own.
const MESSAGE_SECONDS := 1.0
const ENEMY_HOME := Vector2(176, 36)
const PLAYER_HOME := Vector2(64, 86)
## Where a thrown orb lands: on the wild monster's platform.
const BALL_REST := Vector2(176, 58)
## On-screen height of a monster: 32x32 sprites are doubled, 64x64 sprites
## (the size most monster packs use) are drawn as they are.
const SPRITE_HEIGHT := 64.0
## _choose_move() result when the player backs out of the move list.
const CANCELLED := -2

var battle: Battle
## Monsters that leveled up this battle; Main checks them for evolutions.
var leveled_up: Array[Monster] = []
var _last_action := 0
var _last_move := 0

@onready var _enemy_sprite: Sprite2D = $EnemySprite
@onready var _player_sprite: Sprite2D = $PlayerSprite
@onready var _ball: Sprite2D = $Ball
@onready var _enemy_panel: BattlerPanel = $EnemyPanel
@onready var _player_panel: BattlerPanel = $PlayerPanel
@onready var _prompt: Label = $MessageFrame/Prompt
@onready var _action_menu: ChoiceBox = $Menus/ActionArea/ActionMenu
@onready var _move_menu: ChoiceBox = $Menus/MoveArea/MoveMenu
@onready var _move_info: Control = $Menus/MoveInfo
@onready var _move_info_label: Label = $Menus/MoveInfo/Label
@onready var _list_menu: ChoiceBox = $Menus/ListArea/ListMenu


func _ready() -> void:
	_move_menu.cursor_moved.connect(_on_move_cursor_moved)
	_enemy_panel.hide()
	_player_panel.hide()
	_player_sprite.hide()


func run(party: Array[Monster], wild: Monster, rng: RandomNumberGenerator = null) -> Battle.Outcome:
	battle = Battle.new(party, wild, rng)
	battle.trainer_name = GameState.player_name
	await _intro()
	await _play(battle.start())
	while battle.outcome == Battle.Outcome.ONGOING:
		if battle.player_must_switch():
			var index: int = await _choose_party_member(true)
			await _play(battle.switch_after_faint(index))
		else:
			var action: Dictionary = await _choose_action()
			await _play(battle.take_turn(action))
	match battle.outcome:
		Battle.Outcome.WON:
			await _victory()
		Battle.Outcome.CAUGHT:
			await _add_caught_monster()
		Battle.Outcome.LOST:
			var trainer := GameState.player_name
			await _say(["%s is out of\nusable MONSTERS!" % trainer, "%s whited out!" % trainer])
	return battle.outcome


# --- Menus -------------------------------------------------------------------

func _choose_action() -> Dictionary:
	var action := {}
	var monster_name := battle.player.monster.get_display_name()
	while action.is_empty():
		_prompt.text = "What will\n%s do?" % monster_name
		var choice: int = await _action_menu.choose(["FIGHT", "BAG", "MON", "RUN"], _last_action)
		_prompt.text = ""
		if choice >= 0:
			_last_action = choice
		match choice:
			0:
				var move: int = await _choose_move()
				if move != CANCELLED:
					action = Battle.fight(move)
			1:
				var item_id: StringName = await _choose_item()
				if not item_id.is_empty():
					GameState.remove_item(item_id)
					action = Battle.use_item(GameData.item(item_id))
			2:
				var index: int = await _choose_party_member(false)
				if index >= 0:
					action = Battle.switch_to(index)
			3:
				action = Battle.run_away()
	return action


## Returns a move index, -1 for STRUGGLE, or CANCELLED.
func _choose_move() -> int:
	var monster := battle.player.monster
	if not monster.has_usable_move():
		await _say(["%s has no\nmoves left!" % monster.get_display_name()])
		return -1
	var names := PackedStringArray()
	for move in monster.moves:
		names.append(move.display_name)
	var picked := CANCELLED
	_move_info.show()
	while true:
		var index: int = await _move_menu.choose(names, mini(_last_move, names.size() - 1))
		if index >= 0 and monster.pp[index] == 0:
			_move_info.hide()
			await _say(["There's no PP left\nfor this move!"])
			_move_info.show()
			continue
		if index >= 0:
			_last_move = index
			picked = index
		break
	_move_info.hide()
	return picked


func _on_move_cursor_moved(index: int) -> void:
	var monster := battle.player.monster
	if index < monster.moves.size():
		var move := monster.moves[index]
		_move_info_label.text = "PP %2d/%2d\n%s" % [monster.pp[index], move.max_pp, move.element.to_upper()]


## Lists the BAG with each item's description. Returns the chosen item id,
## or &"" if the player backs out.
func _choose_item() -> StringName:
	var ids: Array[StringName] = []
	var items: Array[ItemData] = []
	var options := PackedStringArray()
	for id: StringName in GameState.bag:
		var item := GameData.item(id)
		# Evolution stones are for the field, not battle.
		if item and GameState.bag[id] > 0 and item.kind != ItemData.Kind.EVOLUTION:
			ids.append(id)
			items.append(item)
			options.append("%-10s x%2d" % [item.display_name, GameState.bag[id]])
	if ids.is_empty():
		await _say(["Your BAG is empty!"])
		return &""
	options.append("CANCEL")
	var describe := func(index: int) -> void:
		_prompt.text = items[index].description if index < items.size() else ""
	_list_menu.cursor_moved.connect(describe)
	var picked: StringName = &""
	while true:
		var index: int = await _list_menu.choose(options)
		if index < 0 or index >= ids.size():
			break
		var monster := battle.player.monster
		if items[index].kind == ItemData.Kind.HEAL and monster.hp >= monster.max_hp():
			await _say(["It won't have any effect."])
			continue
		picked = ids[index]
		break
	_list_menu.cursor_moved.disconnect(describe)
	_prompt.text = ""
	return picked


## Returns a party index, or -1 if the player cancels (only when not `forced`).
func _choose_party_member(forced: bool) -> int:
	var options := PackedStringArray()
	for monster in battle.party:
		options.append("%-9s Lv%-3d%3d/%3d" % [monster.get_display_name(), monster.level, monster.hp, monster.max_hp()])
	if not forced:
		options.append("CANCEL")
	while true:
		_prompt.text = "Choose a MONSTER."
		var index: int = await _list_menu.choose(options)
		_prompt.text = ""
		if index < 0 or index >= battle.party.size():
			if forced:
				continue
			return -1
		var monster := battle.party[index]
		if monster.is_fainted():
			await _say(["%s has no energy\nleft to battle!" % monster.get_display_name()])
		elif monster == battle.player.monster:
			await _say(["%s is already\nin battle!" % monster.get_display_name()])
		else:
			return index
	return -1


# --- Playback ----------------------------------------------------------------

func _play(events: Array[Dictionary]) -> void:
	for event in events:
		var side: StringName = event.get("side", &"")
		match event.type:
			&"message":
				await _say([event.text], 0.0 if event.wait else MESSAGE_SECONDS)
			&"attack":
				await _lunge(side)
			&"hit":
				await _hit(side, event.effectiveness)
			&"hp":
				await _panel(side).animate_hp(event.hp)
			&"stat":
				await _stat_change(side, event.stages)
			&"faint":
				await _faint(side)
			&"withdraw":
				await _withdraw()
			&"send_out":
				await _send_out()
			&"flee":
				Audio.play_sfx(&"flee")
			&"restore":
				await _restore(side)
			&"throw":
				await _throw(event.item)
			&"shake":
				await _shake()
			&"caught":
				await _seal()
			&"break_free":
				await _break_free()


func _intro() -> void:
	var wild := battle.enemy.monster
	_enemy_sprite.texture = wild.species.front_texture
	_enemy_sprite.scale = _full_scale(_enemy_sprite)
	_enemy_sprite.position = ENEMY_HOME - Vector2(240.0, 0.0)
	_enemy_panel.show_monster(wild)
	var tween := create_tween()
	tween.tween_property(_enemy_sprite, "position", ENEMY_HOME, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	_enemy_panel.show()
	await _say(["Wild %s appeared!" % wild.get_display_name()])
	await _say(["Go! %s!" % battle.player.monster.get_display_name()], MESSAGE_SECONDS * 0.5)
	await _send_out()


func _victory() -> void:
	Audio.play_music(&"victory")
	var monster := battle.player.monster
	var amount := battle.exp_reward()
	await _say(["%s gained\n%d EXP. Points!" % [monster.get_display_name(), amount]])
	var remaining := amount
	while remaining > 0 and monster.level < Monster.MAX_LEVEL:
		var step := mini(remaining, monster.exp_to_next_level())
		monster.experience += step
		remaining -= step
		await _player_panel.animate_exp()
		if monster.exp_to_next_level() == 0:
			var new_moves := monster.level_up()
			Audio.play_sfx(&"level_up")
			_player_panel.show_monster(monster)
			await _say(["%s grew to\nLv. %d!" % [monster.get_display_name(), monster.level]])
			for move in new_moves:
				await MoveTutor.teach(monster, move)
			if not monster in leveled_up:
				leveled_up.append(monster)
	monster.experience += remaining


func _add_caught_monster() -> void:
	Audio.play_music(&"victory")
	var monster := battle.enemy.monster
	if not GameState.caught.has(GameData.id_of(monster.species)):
		await _say(["%s's data was\nadded to the MONDEX." % monster.species.display_name])
	if GameState.add_monster(monster):
		await _say(["%s joined\nyour party!" % monster.get_display_name()])
	else:
		await _say(["Your party is full.\n%s was sent\nto the BOX." % monster.get_display_name()])


# --- Animation ---------------------------------------------------------------

func _lunge(side: StringName) -> void:
	var sprite := _sprite(side)
	var home := sprite.position
	var reach := Vector2(10, -6) if side == Battle.PLAYER else Vector2(-10, 6)
	var tween := create_tween()
	tween.tween_property(sprite, "position", home + reach, 0.08)
	tween.tween_property(sprite, "position", home, 0.12)
	await tween.finished


func _hit(side: StringName, effectiveness: float) -> void:
	if effectiveness > 1.0:
		Audio.play_sfx(&"hit_super")
	elif effectiveness < 1.0:
		Audio.play_sfx(&"hit_weak")
	else:
		Audio.play_sfx(&"hit")
	var sprite := _sprite(side)
	for i in 3:
		sprite.hide()
		await _wait(0.06)
		sprite.show()
		await _wait(0.06)


func _stat_change(side: StringName, stages: int) -> void:
	Audio.play_sfx(&"stat_up" if stages > 0 else &"stat_down")
	var sprite := _sprite(side)
	var tint := Color(1.6, 1.6, 1.6) if stages > 0 else Color(0.5, 0.5, 0.9)
	var tween := create_tween()
	for i in 2:
		tween.tween_property(sprite, "modulate", tint, 0.12)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	await tween.finished


func _faint(side: StringName) -> void:
	Audio.play_sfx(&"faint")
	var sprite := _sprite(side)
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "position:y", sprite.position.y + 24.0, 0.35)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.35)
	await tween.finished
	sprite.hide()
	sprite.modulate.a = 1.0
	sprite.position = PLAYER_HOME if side == Battle.PLAYER else ENEMY_HOME
	if side == Battle.PLAYER:
		_player_panel.hide()


func _restore(side: StringName) -> void:
	Audio.play_sfx(&"heal")
	var tween := create_tween()
	for i in 2:
		tween.tween_property(_sprite(side), "modulate", Color(0.7, 1.6, 0.9), 0.12)
		tween.tween_property(_sprite(side), "modulate", Color.WHITE, 0.12)
	await tween.finished


func _throw(item: ItemData) -> void:
	_ball.texture = item.icon
	_ball.modulate = Color.WHITE
	_ball.show()
	Audio.play_sfx(&"throw")
	var tween := create_tween()
	tween.tween_method(_ball_arc.bind(Vector2(40, 104), ENEMY_HOME + Vector2(0, 4)), 0.0, 1.0, 0.5)
	await tween.finished
	# The wild monster is drawn into the orb in a flash of light.
	tween = create_tween().set_parallel()
	tween.tween_property(_enemy_sprite, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(_enemy_sprite, "modulate", Color(3, 3, 3), 0.25)
	await tween.finished
	_enemy_sprite.hide()
	_enemy_sprite.modulate = Color.WHITE
	tween = create_tween()
	tween.tween_property(_ball, "position", BALL_REST, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	await tween.finished
	await _wait(0.3)


func _ball_arc(t: float, from: Vector2, to: Vector2) -> void:
	_ball.position = from.lerp(to, t) + Vector2(0.0, -40.0 * sin(t * PI))
	_ball.rotation = t * TAU * 2.0


func _shake() -> void:
	Audio.play_sfx(&"ball_shake")
	var tween := create_tween()
	tween.tween_property(_ball, "rotation", -0.45, 0.1)
	tween.tween_property(_ball, "rotation", 0.45, 0.16)
	tween.tween_property(_ball, "rotation", 0.0, 0.1)
	tween.tween_interval(0.35)
	await tween.finished


## The orb clicks shut: the monster is caught.
func _seal() -> void:
	Audio.play_sfx(&"catch")
	var tween := create_tween()
	tween.tween_property(_ball, "modulate", Color(0.55, 0.55, 0.65), 0.3)
	await tween.finished
	await _wait(0.6)


func _break_free() -> void:
	Audio.play_sfx(&"break_free")
	_ball.hide()
	_enemy_sprite.scale = Vector2.ZERO
	_enemy_sprite.show()
	var tween := create_tween()
	tween.tween_property(_enemy_sprite, "scale", _full_scale(_enemy_sprite), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished


func _withdraw() -> void:
	var tween := create_tween()
	tween.tween_property(_player_sprite, "scale", Vector2.ZERO, 0.2)
	await tween.finished
	_player_sprite.hide()
	_player_panel.hide()


func _send_out() -> void:
	var monster := battle.player.monster
	_player_sprite.texture = monster.species.back_texture
	_player_sprite.position = PLAYER_HOME
	_player_sprite.scale = Vector2.ZERO
	_player_sprite.show()
	_player_panel.show_monster(monster)
	_player_panel.show()
	Audio.play_sfx(&"menu")
	var tween := create_tween()
	tween.tween_property(_player_sprite, "scale", _full_scale(_player_sprite), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished


# --- Helpers -----------------------------------------------------------------

func _say(pages: PackedStringArray, auto_advance := 0.0) -> void:
	await Dialogue.say(pages, auto_advance)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _full_scale(sprite: Sprite2D) -> Vector2:
	return Vector2.ONE * SPRITE_HEIGHT / sprite.texture.get_height()


func _sprite(side: StringName) -> Sprite2D:
	return _player_sprite if side == Battle.PLAYER else _enemy_sprite


func _panel(side: StringName) -> BattlerPanel:
	return _player_panel if side == Battle.PLAYER else _enemy_panel
