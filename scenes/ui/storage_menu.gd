class_name StorageMenu
extends CanvasLayer
## The MONSTER Storage System on a MONSTER CENTER's PC: WITHDRAW from the
## BOX, DEPOSIT from the party, or RELEASE a monster in the BOX for good.
## A StoragePC adds one, awaits run(), then frees it. The rules live in
## GameState (withdraw(), deposit(), release()).

@onready var _preview: Control = $Preview
@onready var _picture: TextureRect = $Preview/Rows/Picture
@onready var _details: Label = $Preview/Rows/Details
@onready var _list: ChoiceBox = $ListArea/List
@onready var _info_box: Control = $InfoBox
@onready var _info: Label = $InfoBox/Label


func run() -> void:
	var prompt := "What would you like\nto do?"
	while true:
		var choice: int = await Dialogue.choose(prompt, ["WITHDRAW", "DEPOSIT", "RELEASE", "SEE YA!"])
		match choice:
			0:
				await _withdraw()
			1:
				await _deposit()
			2:
				await _release()
			_:
				break
		prompt = "Is there anything\nelse?"


func _withdraw() -> void:
	if GameState.storage.is_empty():
		await Dialogue.say(["There are no MONSTERS\nin the BOX."])
		return
	if GameState.party.size() >= GameState.MAX_PARTY:
		await Dialogue.say(["Your party is full!", "DEPOSIT a MONSTER\nfirst."])
		return
	var index := await _pick(GameState.storage, "Withdraw which MONSTER?\n(%d in the BOX)" % GameState.storage.size())
	if index < 0:
		return
	var monster := GameState.storage[index]
	GameState.withdraw(index)
	Audio.play_sfx(&"select")
	await Dialogue.say(["%s was taken\nout of the BOX." % monster.get_display_name()])


func _deposit() -> void:
	var index := await _pick(GameState.party, "Deposit which MONSTER?")
	if index < 0:
		return
	var monster := GameState.party[index]
	if not GameState.deposit(index):
		await Dialogue.say(["You can't deposit\nyour last MONSTER\nthat can battle!"])
		return
	Audio.play_sfx(&"select")
	await Dialogue.say(["%s was stored\nin the BOX." % monster.get_display_name()])


func _release() -> void:
	if GameState.storage.is_empty():
		await Dialogue.say(["There are no MONSTERS\nin the BOX."])
		return
	var index := await _pick(GameState.storage, "Release which MONSTER?\nIt won't come back.")
	if index < 0:
		return
	var monster := GameState.storage[index]
	if await Dialogue.ask("Release %s?" % monster.get_display_name()) != 0:
		return
	GameState.release(index)
	await Dialogue.say(["%s was released\noutside." % monster.get_display_name(), "Bye-bye, %s!" % monster.get_display_name()])


## Lists `team` with a picture and stats of the highlighted monster. Returns
## the picked index, or -1 if the player backs out.
func _pick(team: Array[Monster], hint: String) -> int:
	var options := PackedStringArray()
	for monster in team:
		options.append(monster.get_display_name()) # Level and status show in the preview.
	options.append("CANCEL")
	var describe := func(index: int) -> void:
		_preview.visible = index < team.size()
		if index < team.size():
			var monster := team[index]
			_picture.texture = monster.species.front_texture
			_details.text = "%s\nLv%d %s\nHP %d/%d %s" % [monster.get_display_name(), monster.level,
				monster.species.element.to_upper(), monster.hp, monster.max_hp(), monster.status_tag()]
	_info.text = hint
	_info_box.show()
	_list.cursor_moved.connect(describe)
	var index: int = await _list.choose(options)
	_list.cursor_moved.disconnect(describe)
	_preview.hide()
	_info_box.hide()
	return index if index < team.size() else -1
