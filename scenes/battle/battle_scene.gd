class_name BattleScene
extends Control
## Plays out one battle on screen, wild or against a trainer. The rules live
## in Battle; this scene asks the player for actions and animates the events
## Battle returns.
##
##     var outcome: Battle.Outcome = await battle_scene.run(GameState.party, wild)
##     var outcome: Battle.Outcome = await battle_scene.run_trainer(GameState.party, trainer, foes)

## How long routine battle text stays up before advancing on its own.
const ENEMY_HOME := Vector2(176, 36)
const PLAYER_HOME := Vector2(64, 86)
## Orb positions are its base (the Ball sprite pivots there to wobble).
## A thrown orb pops open in front of the wild monster, then drops onto its
## platform.
const BALL_OPEN := Vector2(176, 42)
const BALL_REST := Vector2(176, 64)
## Orbs thrown mid-battle come in from off-screen, bottom left; a trainer's
## from the top right.
const THROW_FROM := Vector2(16, 112)
const FOE_THROW_FROM := Vector2(252, 4)
## Where each side's row of team markers starts (trainer battle intros).
const FOE_MARKS_AT := Vector2(14, 16)
const PLAYER_MARKS_AT := Vector2(150, 84)
const MARK_DIR := "res://assets/placeholder/effects/"
## Characters of "<name> do?" that fit left of the FIGHT/BAG/MON/RUN box.
const PROMPT_WIDTH := 13
## Where the trainer's hand lets go of the first orb, from the trainer's spot.
const HAND_OFFSET := Vector2(26, -26)
## The white-hot, then red, glow of a monster turning into light.
const LIGHT := Color(3, 3, 3)
const RED_LIGHT := Color(3, 1.3, 1.3)
## On-screen height of a monster: 32x32 sprites are doubled, 64x64 sprites
## (the size most monster packs use) are drawn as they are.
const SPRITE_HEIGHT := 64.0
const STATUS_SOUNDS := {&"poison": &"poison", &"burn": &"burn", &"paralysis": &"zap", &"sleep": &"sleep",
	&"freeze": &"glint", &"confusion": &"glint"}
## _choose_move() result when the player backs out of the move list.
const CANCELLED := -2

var battle: Battle
## Set before run(): the wild monster was met in the water (DIVE ORB).
var in_water := false
## Monsters that leveled up this battle; Main checks them for evolutions.
var leveled_up: Array[Monster] = []
var _last_action := 0
var _last_move := 0
## The orb in flight, for break_free.
var _thrown: ItemData
var _marks: Array[Sprite2D] = []

@onready var _enemy_sprite: Sprite2D = $EnemySprite
@onready var _player_sprite: Sprite2D = $PlayerSprite
@onready var _ball: Sprite2D = $Ball
@onready var _trainer: Sprite2D = $Trainer
@onready var _foe_trainer: Sprite2D = $FoeTrainer
@onready var _effects: MoveAnimator = $Effects
@onready var _enemy_panel: BattlerPanel = $EnemyPanel
@onready var _player_panel: BattlerPanel = $PlayerPanel
@onready var _prompt: Label = $MessageFrame/Prompt
@onready var _item_icon: TextureRect = $MessageFrame/ItemIcon
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
	battle.in_water = in_water
	battle.already_caught = GameState.caught.has(GameData.id_of(wild.species))
	return await _fight()


## A battle against `trainer`, whose team `foes` comes from
## TrainerData.build_party(). Winning pays its prize money; losing costs half
## the player's money.
func run_trainer(party: Array[Monster], trainer: TrainerData, foes: Array[Monster], rng: RandomNumberGenerator = null) -> Battle.Outcome:
	battle = Battle.against_trainer(party, trainer, foes, rng)
	return await _fight()


func _fight() -> Battle.Outcome:
	battle.trainer_name = GameState.player_name
	if battle.is_trainer_battle():
		await _trainer_intro()
	else:
		await _intro()
	await _play(battle.start())
	while battle.outcome == Battle.Outcome.ONGOING:
		if battle.foe_must_switch():
			await _gain_exp()
			await _offer_shift()
			await _play(battle.send_next_foe())
		elif battle.player_must_switch():
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
			await _lose()
	return battle.outcome


# --- Menus -------------------------------------------------------------------

func _choose_action() -> Dictionary:
	var action := {}
	var monster_name := battle.player.monster.get_display_name()
	while action.is_empty():
		var question := "%s do?" % monster_name
		# Ten-letter names like DUSKWRAITH would run under the menu.
		if question.length() > PROMPT_WIDTH:
			question = "%s\ndo?" % monster_name
		_prompt.text = "What will\n" + question
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
				var use: Dictionary = await _choose_item()
				if not use.is_empty():
					GameState.remove_item(use.id)
					action = Battle.use_item(GameData.item(use.id), use.target, use.move)
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


## Lists the BAG with each item's description, then asks which monster (and
## for an ETHER, which move) it's for. Returns {id, target, move}, or {} if
## the player backs out.
func _choose_item() -> Dictionary:
	var ids: Array[StringName] = []
	var items: Array[ItemData] = []
	var options := PackedStringArray()
	for id: StringName in GameState.bag:
		var item := GameData.item(id)
		# Evolution stones and REPELs are for the field, not battle.
		if item and GameState.bag[id] > 0 and not item.kind in [ItemData.Kind.EVOLUTION, ItemData.Kind.REPEL]:
			ids.append(id)
			items.append(item)
			options.append("%-10s x%2d" % [item.display_name, GameState.bag[id]])
	if ids.is_empty():
		await _say(["Your BAG is empty!"])
		return {}
	options.append("CANCEL")
	var describe := func(index: int) -> void:
		_prompt.text = items[index].description if index < items.size() else ""
		_item_icon.texture = items[index].icon if index < items.size() else null
	var last := 0
	while true:
		_list_menu.cursor_moved.connect(describe)
		_item_icon.show()
		var index: int = await _list_menu.choose(options, last)
		_list_menu.cursor_moved.disconnect(describe)
		_item_icon.hide()
		_prompt.text = ""
		if index < 0 or index >= ids.size():
			return {}
		last = index
		var item := items[index]
		if not item.targets_monster():
			return {"id": ids[index], "target": -1, "move": -1}
		var target: int = await _choose_item_target()
		if target < 0:
			continue
		var monster := battle.party[target]
		var move := -1
		if item.kind == ItemData.Kind.PP:
			move = await _choose_pp_move(monster)
			if move < 0:
				continue
		if not item.can_use_on(monster, move):
			await _say(["It won't have any effect."])
			continue
		return {"id": ids[index], "target": target, "move": move}
	return {}


## Which party member an item is for. Returns its index, or -1.
func _choose_item_target() -> int:
	var options := _party_options()
	options.append("CANCEL")
	_prompt.text = "Use on which\nMONSTER?"
	var index: int = await _list_menu.choose(options)
	_prompt.text = ""
	return index if index >= 0 and index < battle.party.size() else -1


## Which of `monster`'s moves an ETHER restores. Returns its index, or -1.
func _choose_pp_move(monster: Monster) -> int:
	var options := PackedStringArray()
	for i in monster.moves.size():
		options.append("%-10s %2d/%2d" % [monster.moves[i].display_name, monster.pp[i], monster.moves[i].max_pp])
	options.append("CANCEL")
	_prompt.text = "Restore which\nmove?"
	var index: int = await _list_menu.choose(options)
	_prompt.text = ""
	return index if index >= 0 and index < monster.moves.size() else -1


## One line per party member: name, level (or status) and HP.
func _party_options() -> PackedStringArray:
	var options := PackedStringArray()
	for monster in battle.party:
		var tag := monster.status_tag()
		options.append("%-9s %-5s%3d/%3d" % [monster.get_display_name(), tag if not tag.is_empty() else "Lv%d" % monster.level, monster.hp, monster.max_hp()])
	return options


## Gen 3's SHIFT style (Settings.shift_style): before a trainer sends out its
## next monster, the player may switch for free.
func _offer_shift() -> void:
	var next := battle.next_foe()
	if next == null or not Settings.shift_style or not battle.can_shift():
		return
	await _say(["%s is\nabout to use %s." % [battle.trainer.title(), next.get_display_name()]])
	if await Dialogue.ask("Will %s change\nMONSTERS?" % GameState.player_name) != 0:
		return
	var index: int = await _choose_party_member(false)
	if index >= 0:
		await _play(battle.shift_to(index))


## Returns a party index, or -1 if the player cancels (only when not `forced`).
func _choose_party_member(forced: bool) -> int:
	var options := _party_options()
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
				await _say([event.text], 0.0 if event.wait else Settings.message_seconds())
			&"attack":
				await _attack(side, event.get("move"))
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
				if side == Battle.ENEMY:
					await _foe_send_out()
				else:
					await _send_out()
			&"flee":
				Audio.play_sfx(&"flee")
			&"restore":
				await _restore(side)
			&"status":
				await _status(side, event.status)
			&"afflicted":
				await _afflicted(side, event.status)
			&"throw":
				await _throw(event.item)
			&"throw_blocked":
				await _throw_blocked(event.item)
			&"shake":
				await _shake()
			&"caught":
				await _seal()
			&"break_free":
				await _break_free()


## The trainers slide in, each side's team shows as a row of orbs, then the
## foe sends out its first monster and the player throws out the lead.
func _trainer_intro() -> void:
	var trainer := battle.trainer
	_foe_trainer.texture = trainer.battle_sprite
	_foe_trainer.position = ENEMY_HOME - Vector2(240.0, 0.0)
	_foe_trainer.show()
	_trainer.frame = 0
	_trainer.position = PLAYER_HOME + Vector2(240.0, 0.0)
	_trainer.show()
	var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_foe_trainer, "position", ENEMY_HOME, 0.8)
	tween.tween_property(_trainer, "position", PLAYER_HOME, 0.8)
	await tween.finished
	_show_marks(battle.foe_party, FOE_MARKS_AT)
	_show_marks(battle.party, PLAYER_MARKS_AT)
	await _say(["%s\nwould like to battle!" % trainer.title()])
	_clear_marks()
	_say(["%s sent\nout %s!" % [trainer.title(), battle.enemy.monster.get_display_name()]], Settings.message_seconds())
	await _foe_send_out(true)
	while Dialogue.is_open:
		await get_tree().process_frame
	_say(["Go! %s!" % battle.player.monster.get_display_name()], Settings.message_seconds())
	await _send_out(true)
	while Dialogue.is_open:
		await get_tree().process_frame


## A row of six orbs: one per team member (grey once fainted), then empty
## slots.
func _show_marks(team: Array[Monster], at: Vector2) -> void:
	for i in GameState.MAX_PARTY:
		var mark := Sprite2D.new()
		var state := "party_empty"
		if i < team.size():
			state = "party_fainted" if team[i].is_fainted() else "party_ok"
		mark.texture = load(MARK_DIR + state + ".png")
		mark.position = at + Vector2(10.0 * i, 0.0)
		add_child(mark)
		_marks.append(mark)


func _clear_marks() -> void:
	for mark in _marks:
		mark.queue_free()
	_marks.clear()


## The wild monster slides in from the left as the trainer slides in from
## the right; then the trainer throws out the lead monster.
func _intro() -> void:
	var wild := battle.enemy.monster
	_enemy_sprite.texture = wild.species.front_texture
	_enemy_sprite.scale = _full_scale(_enemy_sprite)
	_enemy_sprite.position = ENEMY_HOME - Vector2(240.0, 0.0)
	_enemy_panel.show_monster(wild)
	_trainer.frame = 0
	_trainer.position = PLAYER_HOME + Vector2(240.0, 0.0)
	_trainer.show()
	var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_enemy_sprite, "position", ENEMY_HOME, 0.8)
	tween.tween_property(_trainer, "position", PLAYER_HOME, 0.8)
	await tween.finished
	_enemy_panel.show()
	await _say(["Wild %s appeared!" % wild.get_display_name()])
	# The throw plays while "Go!" is on screen.
	_say(["Go! %s!" % battle.player.monster.get_display_name()], Settings.message_seconds())
	await _send_out(true)
	while Dialogue.is_open:
		await get_tree().process_frame


func _victory() -> void:
	Audio.play_music(&"victory")
	await _gain_exp()
	if battle.is_trainer_battle():
		await _beat_trainer()


## The trainer walks back in, concedes, and pays up.
func _beat_trainer() -> void:
	var trainer := battle.trainer
	_foe_trainer.texture = trainer.battle_sprite
	_foe_trainer.position = ENEMY_HOME + Vector2(120.0, 0.0)
	_foe_trainer.show()
	var tween := create_tween()
	tween.tween_property(_foe_trainer, "position", ENEMY_HOME, 0.5).set_ease(Tween.EASE_OUT)
	await tween.finished
	await _say(["%s defeated\n%s!" % [GameState.player_name, trainer.title()]])
	if not trainer.defeat.is_empty():
		await _say(trainer.defeat)
	var prize := battle.prize_money()
	GameState.add_money(prize)
	Audio.play_sfx(&"purchase")
	await _say(["%s got $%d\nfor winning!" % [GameState.player_name, prize]])


func _lose() -> void:
	var player_name := GameState.player_name
	var pages := PackedStringArray(["%s is out of\nusable MONSTERS!" % player_name])
	if battle.is_trainer_battle():
		# Losing to a trainer costs half your money.
		var paid := floori(GameState.money / 2.0)
		GameState.spend_money(paid)
		pages.append("%s paid $%d\nto the winner." % [player_name, paid])
	pages.append("%s whited out!" % player_name)
	await _say(pages)


## The active monster's EXP for the enemy that just fainted, with level-ups.
func _gain_exp() -> void:
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
	await NameEntry.offer_nickname(monster)
	if GameState.add_monster(monster):
		await _say(["%s joined\nyour party!" % monster.get_display_name()])
	else:
		await _say(["Your party is full.\n%s was sent\nto the BOX." % monster.get_display_name()])


# --- Animation ---------------------------------------------------------------

## With BATTLE SCENE off (Settings), moves, stat changes and statuses skip
## their animations; hits, HP bars and sounds still play.
func _attack(side: StringName, move: MoveData) -> void:
	var foe := Battle.ENEMY if side == Battle.PLAYER else Battle.PLAYER
	if move and Settings.battle_scene:
		await _effects.play_move(move, _sprite(side), _sprite(foe))


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
	if not Settings.battle_scene:
		return
	var sprite := _sprite(side)
	_effects.stat_arrows(sprite, stages > 0)
	var tint := Color(1.6, 1.6, 1.6) if stages > 0 else Color(0.5, 0.5, 0.9)
	var tween := create_tween()
	for i in 2:
		tween.tween_property(sprite, "modulate", tint, 0.15)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	await tween.finished


## The monster sinks out of sight below its platform.
func _faint(side: StringName) -> void:
	Audio.play_sfx(&"faint")
	var sprite := _sprite(side)
	var home := sprite.position
	var size := sprite.texture.get_size()
	sprite.region_enabled = true
	var sink := func(t: float) -> void:
		var hidden := size.y * t
		sprite.region_rect = Rect2(0.0, 0.0, size.x, size.y - hidden)
		sprite.position.y = home.y + hidden * sprite.scale.y / 2.0
	var tween := create_tween()
	tween.tween_method(sink, 0.0, 1.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	sprite.hide()
	sprite.region_enabled = false
	sprite.position = PLAYER_HOME if side == Battle.PLAYER else ENEMY_HOME
	_panel(side).hide()


## A status condition was inflicted (or cured, when `status` is empty).
func _status(side: StringName, status: StringName) -> void:
	_panel(side).show_status(status)
	if not status.is_empty():
		await _afflicted(side, status)


## A status shows its effect: bubbles for poison, Zs for sleep...
func _afflicted(side: StringName, status: StringName) -> void:
	Audio.play_sfx(STATUS_SOUNDS.get(status, &"select"))
	if Settings.battle_scene:
		await _effects.status_effect(_sprite(side), status)


func _restore(side: StringName) -> void:
	Audio.play_sfx(&"heal")
	_effects.heal_sparkles(_sprite(side))
	var tween := create_tween()
	for i in 2:
		tween.tween_property(_sprite(side), "modulate", Color(0.7, 1.6, 0.9), 0.12)
		tween.tween_property(_sprite(side), "modulate", Color.WHITE, 0.12)
	await tween.finished


## A catch attempt: the orb arcs over, pops open and draws the wild monster
## in as red light, snaps shut, then drops and bounces onto the platform.
func _throw(item: ItemData) -> void:
	_thrown = item
	Audio.play_sfx(&"throw")
	await _toss(item, THROW_FROM, BALL_OPEN, 0.55, 46.0)
	await _pop_open(item)
	Audio.play_sfx(&"recall")
	await _into_light(_enemy_sprite, BALL_OPEN + Vector2(0, -6))
	_ball.texture = item.icon
	Audio.play_sfx(&"orb_bounce")
	await _wait(0.2)
	var drop := create_tween()
	drop.tween_property(_ball, "position:y", BALL_REST.y, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	drop.tween_callback(Audio.play_sfx.bind(&"orb_bounce"))
	for height: float in [10.0, 4.0]:
		drop.tween_property(_ball, "position:y", BALL_REST.y - height, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		drop.tween_property(_ball, "position:y", BALL_REST.y, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		drop.tween_callback(Audio.play_sfx.bind(&"orb_bounce"))
	await drop.finished
	await _wait(0.35)


## One wobble, tipping on the orb's base.
func _shake() -> void:
	Audio.play_sfx(&"ball_shake")
	var tween := create_tween()
	tween.tween_property(_ball, "rotation", -0.5, 0.1)
	tween.tween_property(_ball, "rotation", 0.5, 0.18)
	tween.tween_property(_ball, "rotation", 0.0, 0.1)
	tween.tween_interval(0.45)
	await tween.finished


## The orb clicks shut, stars pop out, and it dims: the monster is caught.
func _seal() -> void:
	Audio.play_sfx(&"catch")
	_effects.catch_stars(_ball.position + Vector2(0, -8))
	var tween := create_tween()
	tween.tween_property(_ball, "modulate", Color(0.6, 0.6, 0.7), 0.3)
	await tween.finished
	await _wait(0.6)


## The orb bursts open and the monster pours back out.
func _break_free() -> void:
	Audio.play_sfx(&"break_free")
	_ball.rotation = 0.0
	await _pop_open(_thrown)
	var fade := create_tween()
	fade.tween_property(_ball, "modulate:a", 0.0, 0.25)
	await _out_of_light(_enemy_sprite, _ball.position + Vector2(0, -10), ENEMY_HOME)
	_ball.hide()
	_ball.modulate = Color.WHITE


## The trainer's monster comes out of its orb, thrown from the top right.
## With `from_trainer` (the battle's start) the foe trainer steps away first.
func _foe_send_out(from_trainer := false) -> void:
	var monster := battle.enemy.monster
	var orb := _orb_of(monster)
	_enemy_sprite.hide() # Until it comes out of the light.
	_enemy_sprite.texture = monster.species.front_texture
	if from_trainer:
		var leave := create_tween()
		leave.tween_property(_foe_trainer, "position:x", 300.0, 0.4).set_ease(Tween.EASE_IN)
		leave.tween_callback(_foe_trainer.hide)
	Audio.play_sfx(&"throw")
	var open_at := ENEMY_HOME + Vector2(0, 10)
	await _toss(orb, FOE_THROW_FROM, open_at, 0.4, 20.0)
	await _pop_open(orb)
	var fade := create_tween()
	fade.tween_property(_ball, "modulate:a", 0.0, 0.2)
	await _out_of_light(_enemy_sprite, open_at + Vector2(0, -10), ENEMY_HOME)
	_ball.hide()
	_ball.modulate = Color.WHITE
	_enemy_panel.show_monster(monster)
	_enemy_panel.show()


## In a trainer battle the orb gets knocked away before it reaches the foe.
func _throw_blocked(item: ItemData) -> void:
	Audio.play_sfx(&"throw")
	await _toss(item, THROW_FROM, BALL_OPEN, 0.5, 46.0)
	Audio.play_sfx(&"hit_weak")
	_effects.knock(_ball.position + Vector2(0, -6))
	var from := _ball.position
	var knocked := func(t: float) -> void:
		_ball.position = from + Vector2(-110.0 * t, -50.0 * sin(t * PI * 0.8) + 120.0 * t * t)
		_ball.rotation = -t * TAU * 3.0
	var tween := create_tween()
	tween.tween_method(knocked, 0.0, 1.0, 0.6)
	await tween.finished
	_ball.hide()
	_ball.rotation = 0.0


## The player's monster turns to red light and zips back into its orb.
func _withdraw() -> void:
	Audio.play_sfx(&"recall")
	await _into_light(_player_sprite, PLAYER_HOME + Vector2(-48, 16))
	_player_panel.hide()


## Sends the player's active monster out of the orb it was caught in. With
## `from_trainer` (the battle's start) the trainer winds up and throws it,
## then steps away; otherwise it comes from off-screen.
func _send_out(from_trainer := false) -> void:
	var monster := battle.player.monster
	var orb := _orb_of(monster)
	_player_sprite.texture = monster.species.back_texture
	var from := THROW_FROM
	if from_trainer:
		_trainer.frame = 1
		await _wait(0.2)
		_trainer.frame = 2
		from = _trainer.position + HAND_OFFSET
		var leave := create_tween()
		leave.tween_interval(0.1)
		leave.tween_property(_trainer, "position:x", -48.0, 0.45).set_ease(Tween.EASE_IN)
		leave.tween_callback(_trainer.hide)
	Audio.play_sfx(&"throw")
	var open_at := PLAYER_HOME + Vector2(0, 10)
	await _toss(orb, from, open_at, 0.45, 30.0)
	await _pop_open(orb)
	var fade := create_tween()
	fade.tween_property(_ball, "modulate:a", 0.0, 0.2)
	await _out_of_light(_player_sprite, open_at + Vector2(0, -10), PLAYER_HOME)
	_ball.hide()
	_ball.modulate = Color.WHITE
	_player_panel.show_monster(monster)
	_player_panel.show()


## Throws an orb along an arc, spinning, from `from` to `to`.
func _toss(orb: ItemData, from: Vector2, to: Vector2, seconds: float, arc: float) -> void:
	_ball.texture = orb.icon
	_ball.modulate = Color.WHITE
	_ball.rotation = 0.0
	_ball.position = from
	_ball.show()
	var flight := func(t: float) -> void:
		_ball.position = from.lerp(to, t) + Vector2(0.0, -arc * sin(t * PI))
		_ball.rotation = t * TAU * 2.0
	var tween := create_tween()
	tween.tween_method(flight, 0.0, 1.0, seconds)
	await tween.finished
	_ball.rotation = 0.0


func _pop_open(orb: ItemData) -> void:
	Audio.play_sfx(&"orb_open")
	_ball.texture = orb.open_icon if orb.open_icon else orb.icon
	_effects.orb_light(_ball.position + Vector2(0, -6))
	await _wait(0.15)


## `sprite` glows red and shrinks into a point at `to`, then hides.
func _into_light(sprite: Sprite2D, to: Vector2) -> void:
	var home := sprite.position
	var size := sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", RED_LIGHT, 0.15)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "position", to, 0.3).set_ease(Tween.EASE_IN)
	await tween.finished
	sprite.hide()
	sprite.modulate = Color.WHITE
	sprite.scale = size
	sprite.position = home


## `sprite` grows out of a point of light at `from` into its place at `home`.
func _out_of_light(sprite: Sprite2D, from: Vector2, home: Vector2) -> void:
	sprite.position = from
	sprite.scale = Vector2.ZERO
	sprite.modulate = LIGHT
	sprite.show()
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", _full_scale(sprite), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "position", home, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)
	await tween.finished


# --- Helpers -----------------------------------------------------------------

func _say(pages: PackedStringArray, auto_advance := 0.0) -> void:
	await Dialogue.say(pages, auto_advance)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## The orb `monster` was caught in (starters and old saves: a MON ORB).
func _orb_of(monster: Monster) -> ItemData:
	var orb := GameData.item(monster.orb)
	return orb if orb else GameData.item(&"mon_orb")


func _full_scale(sprite: Sprite2D) -> Vector2:
	return Vector2.ONE * SPRITE_HEIGHT / sprite.texture.get_height()


func _sprite(side: StringName) -> Sprite2D:
	return _player_sprite if side == Battle.PLAYER else _enemy_sprite


func _panel(side: StringName) -> BattlerPanel:
	return _player_panel if side == Battle.PLAYER else _enemy_panel
