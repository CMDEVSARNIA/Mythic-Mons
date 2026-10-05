extends Node
## Root of the running game.
##
## Owns the active map (instanced under World), the persistent Player (moved
## into each map's Entities node), the start menu and the screen fade. Maps
## never load each other: anything that wants a map change emits
## Events.warp_requested and this script does the rest.

const FADE_SECONDS := 0.25
const MONSTER_ART_DIR := "res://assets/placeholder/monsters/"

@export_file("*.tscn") var start_map := "res://scenes/maps/town_emberfall.tscn"
@export var start_spawn: StringName = &"default"

var current_map: WorldMap

@onready var world: Node2D = $World
@onready var player: Player = $Player
@onready var fade: ColorRect = $Transition/Fade
@onready var start_menu: ChoiceBox = $UI/StartMenuArea/StartMenu
@onready var map_banner: MapBanner = $UI/MapBanner
@onready var encounter_preview: Control = $UI/EncounterPreview
@onready var encounter_art: TextureRect = $UI/EncounterPreview/Art


func _ready() -> void:
	Events.warp_requested.connect(change_map)
	Events.wild_encounter.connect(_on_wild_encounter)
	player.lock()
	fade.color = Color(0.0, 0.0, 0.0, 1.0)
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
	var scene := load(map_path) as PackedScene
	if scene == null:
		push_error("Map not found: %s" % map_path)
		return
	player.get_parent().remove_child(player)
	if current_map:
		world.remove_child(current_map)
		current_map.queue_free()
	current_map = scene.instantiate() as WorldMap
	world.add_child(current_map)
	current_map.entities.add_child(player)
	var spawn := current_map.get_spawn(spawn_id)
	if spawn:
		player.arrive(spawn.get_cell(), spawn.get_direction())
	player.set_camera_limits(current_map.get_camera_limits(get_viewport().get_visible_rect().size))

	GameState.current_map_path = current_map.scene_file_path
	if current_map.is_town:
		GameState.mark_town_visited(current_map.scene_file_path, current_map.display_name)
	Audio.play_music(current_map.music)
	map_banner.show_name(current_map.display_name)
	Events.map_entered.emit(current_map)


func _open_start_menu() -> void:
	player.lock()
	Audio.play_sfx(&"menu")
	while true:
		var choice: int = await start_menu.choose(["FLY", "EXIT"])
		if choice != 0:
			break
		var destination: String = await _choose_fly_destination()
		if not destination.is_empty():
			player.unlock()
			Audio.play_sfx(&"fly")
			change_map(destination, &"fly")
			return
	player.unlock()


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


## Placeholder until the battle system exists: flash, show the monster, talk.
func _on_wild_encounter(species_id: StringName) -> void:
	player.lock()
	Audio.play_sfx(&"encounter")
	for i in 3:
		fade.color = Color(1.0, 1.0, 1.0, 0.8)
		await get_tree().create_timer(0.07).timeout
		fade.color = Color(1.0, 1.0, 1.0, 0.0)
		await get_tree().create_timer(0.07).timeout
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	var art_path := "%s%s.png" % [MONSTER_ART_DIR, species_id]
	encounter_art.texture = load(art_path) if ResourceLoader.exists(art_path) else null
	encounter_preview.show()
	await Dialogue.say([
		"A wild %s appeared!" % String(species_id).to_upper(),
		"Battles are the next\nmilestone... It ran away!",
	])
	encounter_preview.hide()
	player.unlock()


func _fade_to(alpha: float) -> void:
	fade.color = Color(0.0, 0.0, 0.0, fade.color.a)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished
