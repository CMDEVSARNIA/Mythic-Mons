extends Node
## Root of the running game.
##
## Owns the active map (instanced under World), the persistent Player (moved
## into each map's Entities node), battles, the title screen, the start menu
## (MONDEX, party, BAG, TRAINER CARD, Fly, save, OPTION, and DEBUG in debug
## builds) and the screen fade. Maps never load each other:
## anything that wants a map change emits Events.warp_requested and this
## script does the rest. It also plays a new game's intro and keeps the
## play-time clock running.

const FADE_SECONDS := 0.25
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const EVOLUTION_SCENE := preload("res://scenes/battle/evolution_scene.tscn")
## Overworld poison hurts every this many steps.
const POISON_STEPS := 4
const MAPS_DIR := "res://scenes/maps/"

@export_file("*.tscn") var start_map := "res://scenes/maps/town_emberfall.tscn"
@export var start_spawn: StringName = &"default"

var current_map: WorldMap
var _steps := 0
var _playing := false # Play time counts from the moment the map shows.
## Off makes tall grass and water safe (the DEBUG menu's ENCOUNTERS toggle).
var wild_encounters := true

@onready var world: Node2D = $World
@onready var player: Player = $Player
@onready var fade: ColorRect = $Transition/Fade
@onready var start_menu: ChoiceBox = $UI/StartMenuArea/StartMenu
@onready var map_banner: MapBanner = $UI/MapBanner
@onready var party_menu: PartyMenu = $UI/PartyMenu
@onready var dex_menu: DexMenu = $UI/DexMenu
@onready var trainer_card: TrainerCard = $UI/TrainerCard
@onready var options_menu: OptionsMenu = $UI/OptionsMenu
@onready var hint_box: Control = $UI/HintBox
@onready var hint_label: Label = $UI/HintBox/Label
@onready var hint_icon: TextureRect = $UI/HintBox/Icon
@onready var title_screen: TitleScreen = $UI/TitleScreen
@onready var battle_layer: CanvasLayer = $BattleLayer


func _ready() -> void:
	Events.warp_requested.connect(change_map)
	Events.wild_encounter.connect(_on_wild_encounter)
	Events.trainer_spotted.connect(_on_trainer_spotted)
	Events.trainer_battle.connect(_on_trainer_battle)
	player.step_finished.connect(_on_player_step)
	player.lock()
	var location := {}
	if not GameState.skip_title:
		fade.color = Color(0.0, 0.0, 0.0, 0.0) # The title screen has its own backdrop.
		location = await _title_screen()
	fade.color = Color(0.0, 0.0, 0.0, 1.0)
	if location.is_empty() or not _load_map_at(location):
		if not GameState.has_flag(GameState.INTRO_FLAG):
			await _intro()
		_load_map(start_map, start_spawn)
	_playing = true
	await _fade_to(0.0)
	player.unlock()


func _process(delta: float) -> void:
	if _playing:
		GameState.play_seconds += delta


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


## A new game: PROF. ASTER welcomes the player and asks their name, over
## the title screen's dawn sky. Leaves the screen black.
func _intro() -> void:
	title_screen.show_backdrop()
	Audio.play_music(&"title")
	await _fade_to(0.0)
	Dialogue.show_picture(GameData.species(&"flamlet").front_texture)
	await Dialogue.say([
		"PROF. ASTER: Hello there!\nWelcome to the world\nof MONSTERS!",
		"My name is ASTER. People\ncall me the MONSTER\nPROF.",
		"This world is home to\ncreatures called\nMONSTERS.",
		"People and MONSTERS live\ntogether, battling and\nhelping each other.",
	])
	Dialogue.hide_picture()
	await Dialogue.say(["But enough about me.\nTell me about yourself.", "What's your name?"])
	var typed: String = await NameEntry.ask("YOUR NAME?", GameState.MAX_NAME_LENGTH, TrainerCard.portrait())
	GameState.player_name = typed if not typed.is_empty() else GameState.DEFAULT_NAME
	GameState.set_flag(GameState.INTRO_FLAG)
	await Dialogue.say([
		"%s! Your very own\nMONSTER adventure is\nabout to unfold!" % GameState.player_name,
		"Come see me in my LAB in\nEMBERFALL TOWN. Let's go!",
	])
	await _fade_to(1.0)
	title_screen.hide()


## The title screen: PRESS START, then CONTINUE (with a save), NEW GAME or
## OPTION. Fades out and returns the saved location to resume, or {} for a
## new game.
func _title_screen() -> Dictionary:
	Audio.play_music(&"title")
	await title_screen.open()
	var options := PackedStringArray(["NEW GAME", "OPTION"])
	if GameState.has_save():
		options.insert(0, "CONTINUE")
	var picked := ""
	while picked.is_empty() or picked == "OPTION":
		var index: int = await title_screen.choose(options)
		picked = options[index] if index >= 0 else ""
		if picked == "OPTION":
			await options_menu.open()
	await _fade_to(1.0)
	title_screen.hide()
	if picked != "CONTINUE":
		return {}
	var location := GameState.load_game()
	if location.is_empty():
		await _fade_to(0.0)
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
		actions.append_array([&"BAG", &"CARD", &"FLY", &"SAVE", &"OPTION"])
		if OS.is_debug_build():
			actions.append(&"DEBUG")
		actions.append(&"EXIT")
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
			&"CARD":
				await trainer_card.show_card()
			&"SAVE":
				await _save()
			&"OPTION":
				await options_menu.open()
			&"DEBUG":
				if await _debug_menu():
					return # It warped; change_map() handles the lock.
			&"FLY":
				var destination: String = await _choose_fly_destination()
				if not destination.is_empty():
					player.unlock()
					Audio.play_sfx(&"fly")
					change_map(destination, &"fly")
					return
	player.unlock()


## Testing shortcuts, only in debug builds (running from the editor, or a
## debug export). Returns true if it started a warp.
func _debug_menu() -> bool:
	var last := 0
	while true:
		var options := PackedStringArray(["WARP", "HEAL", "ITEMS x99", "MONEY", "BADGES", "LEVEL +5", "MONSTER",
			"MONDEX", "WILD: %s" % ("ON" if wild_encounters else "OFF"), "BACK"])
		var choice: int = await start_menu.choose(options, last)
		if choice < 0 or choice == options.size() - 1:
			return false
		last = choice
		match choice:
			0:
				var maps := Array(ResourceLoader.list_directory(MAPS_DIR)).filter(func(f: String) -> bool: return f.ends_with(".tscn"))
				var names := PackedStringArray(maps.map(func(f: String) -> String: return f.get_basename().to_upper()))
				names.append("CANCEL")
				var pick: int = await start_menu.choose(names)
				if pick >= 0 and pick < maps.size():
					player.unlock()
					change_map(MAPS_DIR + maps[pick], &"default")
					return true
			1:
				GameState.heal_party()
				Audio.play_sfx(&"heal")
				await Dialogue.say(["DEBUG: Party healed."])
			2:
				for file in ResourceLoader.list_directory(GameData.ITEMS_DIR):
					if file.ends_with(".tres"):
						GameState.add_item(StringName(file.get_basename()), GameState.MAX_ITEM_COUNT)
				await Dialogue.say(["DEBUG: 99 of every item."])
			3:
				GameState.add_money(100000)
				await Dialogue.say(["DEBUG: +$100000."])
			4:
				for badge: StringName in GameState.BADGES:
					GameState.set_flag(badge)
				await Dialogue.say(["DEBUG: Every badge."])
			5:
				await _debug_level_up()
			6:
				await _debug_give_monster()
			7:
				for species in GameData.all_species():
					GameState.mark_seen(GameData.id_of(species))
					GameState.caught[GameData.id_of(species)] = true
				await Dialogue.say(["DEBUG: MONDEX filled."])
			8:
				wild_encounters = not wild_encounters
	return false


## Five level-ups for the lead, teaching moves and evolving as a battle would.
func _debug_level_up() -> void:
	if GameState.party.is_empty():
		return
	var monster := GameState.party[0]
	for i in 5:
		if monster.level >= Monster.MAX_LEVEL:
			break
		monster.experience = monster.exp_for_level(monster.level + 1)
		for move in monster.level_up():
			await MoveTutor.teach(monster, move)
	Audio.play_sfx(&"level_up")
	await Dialogue.say(["%s grew to\nLv. %d!" % [monster.get_display_name(), monster.level]])
	var into := monster.evolution_by_level()
	if into:
		await _fade_to(1.0)
		await _evolve(monster, into, true)
		await _fade_to(0.0)


func _debug_give_monster() -> void:
	var all := GameData.all_species()
	var names := PackedStringArray(all.map(func(s: MonsterSpecies) -> String: return s.display_name))
	names.append("CANCEL")
	var pick: int = await start_menu.choose(names)
	if pick < 0 or pick >= all.size():
		return
	var levels := [5, 10, 20, 30, 50]
	var level_pick: int = await start_menu.choose(PackedStringArray(levels.map(func(l: int) -> String: return "Lv. %d" % l)))
	if level_pick < 0:
		return
	var monster := Monster.create(all[pick], levels[level_pick])
	var where := "party" if GameState.add_monster(monster) else "BOX"
	await Dialogue.say(["DEBUG: %s Lv. %d\njoined the %s." % [monster.get_display_name(), monster.level, where]])


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
	match item.kind:
		ItemData.Kind.EVOLUTION:
			await _use_evolution_item(id)
			return
		ItemData.Kind.REPEL:
			await _use_repel(id, item)
			return
	if not item.targets_monster():
		await Dialogue.say(["There's a time and place\nfor that... This isn't it."])
		return
	if GameState.party.is_empty():
		await Dialogue.say(["You don't have any\nMONSTERS yet."])
		return
	var target: int = await party_menu.pick("Use on which MONSTER?")
	if target < 0:
		return
	var monster := GameState.party[target]
	var move := -1
	if item.kind == ItemData.Kind.PP:
		var names := PackedStringArray()
		for i in monster.moves.size():
			names.append("%-10s %2d/%2d" % [monster.moves[i].display_name, monster.pp[i], monster.moves[i].max_pp])
		names.append("CANCEL")
		move = await Dialogue.choose("Restore which move?", names)
		if move < 0 or move >= monster.moves.size():
			return
	if not item.can_use_on(monster, move):
		await Dialogue.say(["It won't have any effect."])
		return
	var text := item.use_on(monster, move)
	GameState.remove_item(id)
	Audio.play_sfx(&"heal")
	await Dialogue.say([text])


## A REPEL lasts `repel_steps` steps; a second one can't stack.
func _use_repel(id: StringName, item: ItemData) -> void:
	if GameState.repel_steps > 0:
		await Dialogue.say(["The last REPEL is still\nworking."])
		return
	GameState.remove_item(id)
	GameState.repel_steps = item.repel_steps
	Audio.play_sfx(&"heal")
	await Dialogue.say(["%s used the\n%s." % [GameState.player_name, item.display_name], "Weaker wild MONSTERS\nwill stay away."])


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
		var badge: String = GameState.BADGES[GameState.badge_for(&"fly")][0]
		await Dialogue.say(["You need the %s\nto FLY outside of\nbattle." % badge])
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
	if species == null or not GameState.has_healthy_monster() or not wild_encounters:
		return
	var levels := current_map.wild_levels
	var level := randi_range(levels.x, mini(levels.y, Monster.MAX_LEVEL))
	if GameState.repel_steps > 0 and level < GameState.lead_monster().level:
		return # A REPEL keeps weaker wild monsters away, as in Gen 3.
	GameState.mark_seen(species_id)
	player.lock()
	Audio.play_music(&"battle")
	await _encounter_flash()
	var wild := Monster.create(species, level)
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
	Audio.play_music(trainer.music)
	await _encounter_flash()
	var outcome: Battle.Outcome = await _run_battle(null, false, trainer)
	if outcome == Battle.Outcome.WON:
		GameState.set_flag(trainer.defeat_flag())
		if not trainer.badge.is_empty() and not GameState.has_flag(trainer.badge):
			await _award_badge(trainer)
	elif outcome == Battle.Outcome.LOST:
		await _white_out()
	player.unlock()


## A GYM LEADER hands over their badge, with a fanfare, and says what it does.
func _award_badge(trainer: TrainerData) -> void:
	GameState.set_flag(trainer.badge)
	Audio.play_sfx(&"badge")
	await Dialogue.say(["%s received the\n%s from %s!" % [
		GameState.player_name, GameState.BADGES[trainer.badge][0], trainer.trainer_name]])
	await Dialogue.say(trainer.badge_lines)


## Every 4 steps, poisoned party members lose 1 HP, as in Gen 3, but the
## poison wears off at 1 HP instead of fainting them (as in later games).
func _on_player_step(_cell: Vector2i) -> void:
	if player.is_locked():
		return # A warp, encounter or trainer is taking over.
	if GameState.repel_steps > 0:
		GameState.repel_steps -= 1
		if GameState.repel_steps == 0:
			player.lock()
			await Dialogue.say(["REPEL's effect wore off..."])
			player.unlock()
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


## After losing: heal the party and wake up at the last place that healed
## it (home, or a MONSTER CENTER). Expects the screen to already be black.
func _white_out() -> void:
	GameState.heal_party()
	_load_map(GameState.respawn_map, GameState.respawn_spawn)
	await _fade_to(0.0)
	if GameState.respawn_map == GameState.HOME_MAP:
		await Dialogue.say(["MOM: You're back! Your\nMONSTERS were exhausted.", "Let them rest... There,\nall better! Be careful!"])
	else:
		await Dialogue.say(["%s hurried to the\nMONSTER CENTER with\nthe tired MONSTERS." % GameState.player_name,
			"NURSE: Your MONSTERS are\nfully rested. Please\ntake care out there!"])


func _fade_to(alpha: float) -> void:
	fade.color = Color(0.0, 0.0, 0.0, fade.color.a)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished
