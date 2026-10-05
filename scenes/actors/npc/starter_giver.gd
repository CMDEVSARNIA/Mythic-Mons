class_name StarterGiver
extends NPC
## The professor who hands out the first monster. Until the player has one,
## talking offers each starter with its picture; afterwards `lines` are used.

@export var starters: Array[StringName] = [&"flamlet", &"aquapup", &"sproutle"]
@export_range(1, 100) var starter_level := 5
@export var intro: PackedStringArray = [
	"PROF. ASTER: Ah, there\nyou are!",
	"Heading out to ROUTE 1?\nNot without a partner!",
	"Pick one of these three\nMONSTERS to take along.",
]
## Handed over with the starter.
@export var gift_item: StringName = &"mon_orb"
@export var gift_count := 5


func _talk() -> void:
	if GameState.has_flag(GameState.STARTER_FLAG):
		await Dialogue.say(lines)
		return
	await Dialogue.say(intro)
	var choices: Array[MonsterSpecies] = []
	var names := PackedStringArray()
	var pictures: Array[Texture2D] = []
	for id in starters:
		var species := GameData.species(id)
		choices.append(species)
		names.append(species.display_name)
		pictures.append(species.front_texture)
	while true:
		var choice: int = await Dialogue.choose("Which MONSTER will\nyou choose?", names, pictures)
		if choice < 0:
			await Dialogue.say(["Take your time. Come\nback when you've decided."])
			return
		var picked := choices[choice]
		Dialogue.show_picture(picked.front_texture)
		var answer: int = await Dialogue.ask("%s, the %s\nMONSTER. Will you take it?" % [picked.display_name, picked.element.to_upper()])
		Dialogue.hide_picture()
		if answer == 0:
			await _give(picked)
			return


func _give(species: MonsterSpecies) -> void:
	GameState.add_monster(Monster.create(species, starter_level))
	GameState.set_flag(GameState.STARTER_FLAG)
	GameState.add_item(gift_item, gift_count)
	Audio.play_sfx(&"level_up")
	var player_name := GameState.player_name
	await Dialogue.say([
		"%s received\n%s!" % [player_name, species.display_name],
		"Take these as well.",
		"%s received\n%d %ss!" % [player_name, gift_count, GameData.item(gift_item).display_name],
		"%s received\nthe MONDEX!" % player_name,
		"It records every MONSTER\nyou see and catch. Open\nit from the menu (ENTER).",
	])
	await Dialogue.say(lines)
