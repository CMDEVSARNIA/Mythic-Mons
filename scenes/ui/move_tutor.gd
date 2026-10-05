class_name MoveTutor
extends RefCounted
## Teaches a monster a new move through the text box, like Emerald: it learns
## the move outright if it knows fewer than four, otherwise the player may
## forget one to make room. Used by level-ups in battle and by evolutions.
##
##     await MoveTutor.teach(monster, move)


static func teach(monster: Monster, move: MoveData) -> void:
	var monster_name := monster.get_display_name()
	if move in monster.moves:
		return
	if monster.learn(move):
		await Dialogue.say(["%s learned\n%s!" % [monster_name, move.display_name]])
		return
	await Dialogue.say(["%s is trying to\nlearn %s." % [monster_name, move.display_name],
		"But %s can't learn\nmore than four moves." % monster_name])
	while true:
		if await Dialogue.ask("Forget a move to make\nroom for %s?" % move.display_name) != 0:
			await Dialogue.say(["%s did not learn\n%s." % [monster_name, move.display_name]])
			return
		var names := PackedStringArray()
		for known in monster.moves:
			names.append(known.display_name)
		names.append("CANCEL")
		var index: int = await Dialogue.choose("Which move should\nbe forgotten?", names)
		if index >= 0 and index < monster.moves.size():
			var forgotten := monster.moves[index].display_name
			monster.replace_move(index, move)
			await Dialogue.say(["1, 2, and... Poof!", "%s forgot %s.\nAnd..." % [monster_name, forgotten],
				"%s learned\n%s!" % [monster_name, move.display_name]])
			return
