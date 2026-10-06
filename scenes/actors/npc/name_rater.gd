class_name NameRater
extends NPC
## Renames the player's monsters, like Emerald's NAME RATER: pick a party
## member, then type its new nickname on the naming screen.

const GOODBYE := "I see. Do come visit\nagain."


func _talk() -> void:
	if await Dialogue.ask("Hello, hello! I am the\nofficial NAME RATER!\nShall I rate a nickname?") != 0:
		await Dialogue.say([GOODBYE])
		return
	var names := PackedStringArray()
	var pictures: Array[Texture2D] = []
	for monster in GameState.party:
		names.append(monster.get_display_name())
		pictures.append(monster.species.front_texture)
	names.append("CANCEL")
	var index: int = await Dialogue.choose("Which MONSTER's\nnickname should I rate?", names, pictures)
	if index < 0 or index >= GameState.party.size():
		await Dialogue.say([GOODBYE])
		return
	var monster := GameState.party[index]
	var old_name := monster.get_display_name()
	if await Dialogue.ask("%s, is it? A decent\nname. Shall I give it\na nicer one?" % old_name) != 0:
		await Dialogue.say([GOODBYE])
		return
	await NameEntry.rename(monster)
	if monster.get_display_name() == old_name:
		await Dialogue.say(["Done! It's the same as\nbefore, but that's a\nfine name too!"])
	else:
		await Dialogue.say(["Done! From now on, this\nMONSTER shall be known\nas %s!" % monster.get_display_name()])
