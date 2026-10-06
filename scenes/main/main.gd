extends Node
## Root of the running game.
##
## Owns the active map (instanced under World), the persistent Player (moved
## into each map's Entities node), battles, the title screen, the start menu
## (MONDEX, party, BAG, Fly, save) and the screen fade. Maps never load each other:
## anything that wants a map change emits Events.warp_requested and this
## script does the rest.

const FADE_SECONDS := 0.25
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const EVOLUTION_SCENE := preload("res://scenes/battle/evolution_scene.tscn")
## Overworld poison hurts every this many steps.
const POISON_STEPS := 4

@export_file("*.tscn") var start_map := "res://scenes/maps/town_emberfall.tscn"
@export var start_spawn: StringName = &"default"

var current_map: WorldMap
var _steps := 0

@onready var world: Node2D = $World
@onready var player: Player = $Player
@onready var fade: ColorRect = $Transition/Fade
@onready var start_menu: ChoiceBox = $UI/StartMenuArea/StartMenu
@onready var map_banner: MapBanner = $UI/MapBanner
@onready var party_menu: PartyMenu = $UI/PartyMenu
@onready var dex_menu: DexMenu = $UI/DexMenu
@onready var hint_box: Control = $UI/HintBox
@onready var hint_label: Label = $UI/HintBox/Label
@onready var hint_icon: TextureRect = $UI/HintBox/Icon
@onready var title_screen: Control = $UI/TitleScreen
@onready var title_menu: ChoiceBox = $UI/TitleScreen/MenuArea/Menu
@onready var battle_layer: CanvasLayer = $BattleLayer


func _ready() -> void:
	Events.warp_requested.connect(change_map)
	Events.wild_encounter.connect(_on_wild_encounter)
	Events.trainer_spotted.connect(_on_trainer_spotted)
	Events.trainer_battle.connect(_on_trainer_battle)
	player.step_finished.connect(_on_player_step)
	player.lock()
	var location := {}
	if GameState.has_save():
		fade.color = Color(0.0, 0.0, 0.0, 0.0) # The title screen has its own backdrop.
		location = await _title_screen()
	fade.color = Color(0.0, 0.0, 0.0, 1.0)
	if location.is_empty() or not _load_map_at(location):
		_load_map(start_map, start_spawn)
	await _fade_to(0.0)
	player.unlock()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu") and player.is_idle():
		get_viewport().set_input_as_handled()
		_open_start_menu()


## Fades out, swaps to `map_path`, places the player at `spawn_id`, fades in.
func change_map(map_path: String, spawn_id: StringName) -> void:
	player.lock()
	await _fade_to(1.0)
	_load_map(map_path, spawn_id)
	await _fade_to(0.0)
	player.unlock()


func _load_map(map_path: String, spawn_id: StringName) -> void:
	if not _swap_map(map_path):
		return
	var spawn := current_map.get_spawn(spawn_id)
	if spawn:
		player.arrive(spawn.get_cell(), spawn.get_direction())
	_on_arrived()


## Loads a map and puts the player on an exact cell (used by saved games).
## `location` is what GameState.load_game() returns.
func _load_map_at(location: Dictionary) -> bool:
	if not ResourceLoader.exists(location.map) or not _swap_map(location.map):
		return false
	player.arrive(location.cell, location.facing)
	if location.get("surfing", false):
		player.set_surfing(true)
	_on_arrived()
	return true


func _swap_map(map_path: String) -> bool:
	var scene := load(map_path) as PackedScene
	if scene == null:
		push_error("Map not found: %s" % map_path)
		return false
	player.get_parent().remove_child(player)
	if current_map:
		world.remove_child(current_map)
		current_map.queue_free()
	current_map = scene.instantiate() as WorldMap
	world.add_child(current_map)
	current_map.entities.add_child(player)
	return true


func _on_arrived() -> void:
	player.set_camera_limits(current_map.get_camera_limits(get_viewport().get_visible_rect().size))

	GameState.current_map_path = current_map.scene_file_path
	if current_map.is_town:
		GameState.mark_town_visited(current_map.scene_file_path, current_map.display_name)
	Audio.play_music(current_map.music)
	map_banner.show_name(current_map.display_name)
	Events.map_entered.emit(current_map)


## Shows CONTINUE / NEW GAME. Returns the saved location to resume, or {}.
func _title_screen() -> Dictionary:
	title_screen.show()
	var choice := -1
	while choice < 0:
		choice = await title_menu.choose(["CONTINUE", "NEW GAME"])
	title_screen.hide()
	if choice != 0:
		return {}
	var location := GameState.load_game()
	if location.is_empty():
		await Dialogue.say(["The save file couldn't\nbe read. Starting a\nnew game."])
	return location


func _open_start_menu() -> void:
	player.lock()
	Audio.play_sfx(&"menu")
	var last := 0
	while true:
		var actions: Array[StringName] = []
		if GameState.has_flag(GameState.STARTER_FLAG): # PROF. ASTER hands it over with the starter.
			actions.append(&"MONDEX")
		if not GameState.party.is_empty():
			actions.append(&"MONSTERS")
		actions.append_array([&"BAG", &"FLY", &"SAVE", &"EXIT"])
		var choice: int = await start_menu.choose(PackedStringArray(actions), mini(last, actions.size() - 1))
		if choice < 0 or actions[choice] == &"EXIT":
			break
		last = choice
		match actions[choice]:
			&"MONDEX":
				await dex_menu.browse()
			&"MONSTERS":
				await party_menu.browse()
			&"BAG":
				await _open_bag()
			&"SAVE":
				await _save()
			&"FLY":
				var destination: String = await _choose_fly_destination()
				if not destination.is_empty():
					player.unlock()
					Audio.play_sfx(&"fly")
					change_map(destination, &"fly")
					return
	player.unlock()


## The BAG outside battle: POTIONs can be used on any party member.
func _open_bag() -> void:
	var first := true
	while true:
		var ids: Array[StringName] = []
		var items: Array[ItemData] = []
		var options := PackedStringArray()
		for id: StringName in GameState.bag:
			var item := GameData.item(id)
			if item:
				ids.append(id)
				items.append(item)
				options.append("%-10s x%2d" % [item.display_name, GameState.bag[id]])
		if ids.is_empty():
			if first: # After using the last item, just go back to the menu.
				await Dialogue.say(["Your BAG is empty."])
			return
		first = false
		options.append("CANCEL")
		var describe := func(index: int) -> void:
			hint_label.text = items[index].description if index < items.size() else "Close the BAG."
			hint_icon.texture = items[index].icon if index < items.size() else null
		start_menu.cursor_moved.connect(describe)
		hint_box.show()
		var index: int = await start_menu.choose(options)
		hint_box.hide()
		start_menu.cursor_moved.disconnect(describe)
		if index < 0 or index >= ids.size():
			return
		await _use_item(ids[index], items[index])


func _use_item(id: StringName, item: ItemData) -> void:
	if item.kind == ItemData.Kind.EVOLUTION:
		await _use_evolution_item(id)
		return
	if item.kind != ItemData.Kind.HEAL and item.kind != ItemData.Kind.CURE:
		await Dialogue.say(["There's a time and place\nfor that... This isn't it."])
		return
	if GameState.party.is_empty():
		await Dialogue.say(["You don't have any\nMONSTERS yet."])
		return
	var target: int = await party_menu.pick("Use on which MONSTER?")
	if target < 0:
		return
	var monster := GameState.party[target]
	if item.kind == ItemData.Kind.CURE:
		if not item.cures_status(monster.status):
			await Dialogue.say(["It won't have any effect."])
			return
		var was: StringName = monster.status
		monster.cure()
		GameState.remove_item(id)
		Audio.play_sfx(&"heal")
		await Dialogue.say([Battle.CURED_TEXT[was] % monster.get_display_name()])
		return
	if monster.is_fainted() or monster.hp >= monster.max_hp():
		await Dialogue.say(["It won't have any effect."])
		return
	var healed := mini(item.heal_amount, monster.max_hp() - monster.hp)
	monster.hp += healed
	GameState.remove_item(id)
	Audio.play_sfx(&"heal")
	await Dialogue.say(["%s's HP was\nrestored by %d points." % [monster.get_display_name(), healed]])


## Evolution stones: pick a party member; the stone is used up if it works.
func _use_evolution_item(id: StringName) -> void:
	if GameState.party.is_empty():
		await Dialogue.say(["You don't have any\nMONSTERS yet."])
		return
	var target: int = await party_menu.pick("Use on which MONSTER?")
	if target < 0:
		return
	var monster := GameState.party[target]
	var into := monster.evolution_by_item(id)
	if into == null:
		await Dialogue.say(["It won't have any effect."])
		return
	GameState.remove_item(id)
	await _fade_to(1.0)
	await _evolve(monster, into, false)
	await _fade_to(0.0)


## Shows the evolution screen over everything. Expects (and leaves) the screen
## faded to black. Returns false if the player stopped the evolution.
func _evolve(monster: Monster, into: MonsterSpecies, can_cancel: bool) -> bool:
	var scene: EvolutionScene = EVOLUTION_SCENE.instantiate()
	battle_layer.add_child(scene)
	await _fade_to(0.0)
	var evolved: bool = await scene.run(monster, into, can_cancel)
	await _fade_to(1.0)
	scene.queue_free()
	return evolved


func _save() -> void:
	if await Dialogue.ask("Would you like to\nsave the game?") != 0:
		return
	var error := GameState.save_game({
		"map": current_map.scene_file_path,
		"cell": player.get_cell(),
		"facing": player.facing,
		"surfing": player.is_surfing,
	})
	if error == OK:
		Audio.play_sfx(&"level_up")
		await Dialogue.say(["%s saved the game." % GameState.player_name])
	else:
		await Dialogue.say(["The game couldn't be\nsaved. (%s)" % error_string(error)])


## Lists visited towns. Returns the chosen map path, or "" if Fly can't be
## used here or the player backs out.
func _choose_fly_destination() -> String:
	if not GameState.can_use_field_move(&"fly"):
		await Dialogue.say(["No MONSTER in your party\nknows FLY."])
		return ""
	if not current_map.allow_fly:
		await Dialogue.say(["You can't FLY from here!"])
		return ""
	var paths := GameState.visited_towns.keys()
	var names := PackedStringArray(GameState.visited_towns.values())
	names.append("CANCEL")
	var pick: int = await start_menu.choose(names)
	return paths[pick] if pick >= 0 and pick < paths.size() else ""


func _on_wild_encounter(species_id: StringName) -> void:
	var species := GameData.species(species_id)
	if species == null or not GameState.has_healthy_monster():
		return
	GameState.mark_seen(species_id)
	player.lock()
	Audio.play_music(&"battle")
	await _encounter_flash()
	var levels := current_map.wild_levels
	var wild := Monster.create(species, randi_range(levels.x, mini(levels.y, Monster.MAX_LEVEL)))
	var outcome: Battle.Outcome = await _run_battle(wild, player.is_surfing)
	if outcome == Battle.Outcome.LOST:
		await _white_out()
	player.unlock()


## A trainer saw the player: "!", the eyes-meet music, then they walk over
## and talk, which starts the battle.
func _on_trainer_spotted(trainer: Trainer) -> void: # Events passes it untyped.
	player.lock()
	Audio.play_music(&"spotted")
	await trainer.notice(player)
	player.face(-trainer.facing)
	await trainer.interact(player)
	player.unlock()


func _on_trainer_battle(trainer: TrainerData) -> void:
	if not GameState.has_healthy_monster():
		return
	player.lock()
	Audio.play_music(&"trainer_battle")
	await _encounter_flash()
	var outcome: Battle.Outcome = await _run_battle(null, false, trainer)
	if outcome == Battle.Outcome.WON:
		GameState.set_flag(trainer.defeat_flag())
	elif outcome == Battle.Outcome.LOST:
		await _white_out()
	player.unlock()


## Every 4 steps, poisoned party members lose 1 HP, as in Gen 3, but the
## poison wears off at 1 HP instead of fainting them (as in later games).
func _on_player_step(_cell: Vector2i) -> void:
	if player.is_locked():
		return # A warp, encounter or trainer is taking over.
	_steps += 1
	if _steps % POISON_STEPS != 0:
		return
	var recovered: Array[String] = []
	var hurt := false
	for monster in GameState.party:
		if monster.status != &"poison" or monster.is_fainted():
			continue
		monster.hp = maxi(monster.hp - 1, 1)
		hurt = true
		if monster.hp == 1:
			monster.cure()
			recovered.append(monster.get_display_name())
	if not hurt:
		return
	Audio.play_sfx(&"poison")
	fade.color = Color(PixelArt.PLUM, 0.35) # A purple flash, as in Emerald.
	await get_tree().create_timer(0.1).timeout
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	if recovered.is_empty():
		return
	player.lock()
	for monster_name in recovered:
		await Dialogue.say(["%s survived the\npoisoning! The poison\nfaded away!" % monster_name])
	player.unlock()


func _encounter_flash() -> void:
	Audio.play_sfx(&"encounter")
	for i in 3:
		fade.color = Color(1.0, 1.0, 1.0, 0.8)
		await get_tree().create_timer(0.07).timeout
		fade.color = Color(1.0, 1.0, 1.0, 0.0)
		await get_tree().create_timer(0.07).timeout


## The species id of the player's starter, which the rival's team counters.
func _player_starter() -> StringName:
	for id: StringName in TrainerData.STARTER_COUNTERS:
		if GameState.has_flag(StringName("starter_" + id)):
			return id
	for id: StringName in TrainerData.STARTER_COUNTERS: # Saves from before the flag.
		if GameState.caught.has(id):
			return id
	return &""


## Covers the overworld with a battle, pausing the map underneath. Pass
## `trainer` for a trainer battle (`wild` is then ignored). `in_water`: the
## wild monster was met while surfing (DIVE ORBs work best).
func _run_battle(wild: Monster, in_water := false, trainer: TrainerData = null) -> Battle.Outcome:
	await _fade_to(1.0)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.in_water = in_water
	battle_layer.add_child(battle)
	await _fade_to(0.0)
	var outcome: Battle.Outcome
	if trainer:
		outcome = await battle.run_trainer(GameState.party, trainer, trainer.build_party(_player_starter()))
	else:
		outcome = await battle.run(GameState.party, wild)
	var leveled_up: Array[Monster] = battle.leveled_up
	await _fade_to(1.0)
	battle.queue_free()
	# Like Emerald, monsters that leveled up evolve once the battle is over.
	for monster in leveled_up:
		var into := monster.evolution_by_level()
		if into and not monster.is_fainted():
			await _evolve(monster, into, true)
	world.process_mode = Node.PROCESS_MODE_INHERIT
	if outcome != Battle.Outcome.LOST:
		Audio.play_music(current_map.music)
		await _fade_to(0.0)
	return outcome


## After losing: heal the party and wake up at the last respawn point.
## Expects the screen to already be black.
func _white_out() -> void:
	GameState.heal_party()
	_load_map(GameState.respawn_map, GameState.respawn_spawn)
	await _fade_to(0.0)
	await Dialogue.say(["MOM: You're back! Your\nMONSTERS were exhausted.", "Let them rest... There,\nall better! Be careful!"])


func _fade_to(alpha: float) -> void:
	fade.color = Color(0.0, 0.0, 0.0, fade.color.a)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished
