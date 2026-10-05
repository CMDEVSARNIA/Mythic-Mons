class_name ShopMenu
extends CanvasLayer
## A MART counter: BUY, SELL or QUIT. A ShopClerk adds one, awaits run(), then
## frees it. Items cost ItemData.price, and the MART buys them back for
## ItemData.sell_price(). Money and items go through GameState.

@onready var _money: Label = $MoneyBox/Label
@onready var _list: ChoiceBox = $ListArea/List
@onready var _info_box: Control = $InfoBox
@onready var _info: Label = $InfoBox/Label
@onready var _quantity: QuantityBox = $QuantityArea/Quantity


func _ready() -> void:
	_info_box.hide()
	_refresh_money()


func run(stock: Array[ItemData]) -> void:
	var prompt := "Welcome! How may I\nserve you?"
	while true:
		var choice: int = await Dialogue.choose(prompt, ["BUY", "SELL", "QUIT"])
		if choice == 0:
			await _buy(stock)
		elif choice == 1:
			await _sell()
		else:
			break
		_list.hide()
		_info_box.hide()
		prompt = "Is there anything else\nI can do for you?"
	await Dialogue.say(["Please come again!"])


func _buy(stock: Array[ItemData]) -> void:
	var options := PackedStringArray()
	for item in stock:
		options.append("%-10s %6s" % [item.display_name, "$%d" % item.price])
	options.append("CANCEL")
	var last := 0
	while true:
		var index := await _pick(options, stock, last)
		if index < 0 or index >= stock.size():
			return
		last = index
		var item := stock[index]
		var id := GameData.id_of(item)
		var room := GameState.MAX_ITEM_COUNT - GameState.item_count(id)
		if room <= 0:
			await Dialogue.say(["You can't carry any\nmore of those."])
			continue
		if GameState.money < item.price:
			await Dialogue.say(["You don't have enough\nmoney."])
			continue
		var count := await _quantity.pick(mini(floori(GameState.money / float(item.price)), room), item.price)
		if count <= 0:
			continue
		var total := count * item.price
		if await Dialogue.ask("%s, and\nyou want %d?\nThat will be $%d. OK?" % [item.display_name, count, total]) != 0:
			continue
		GameState.spend_money(total)
		GameState.add_item(id, count)
		_refresh_money()
		Audio.play_sfx(&"purchase")
		await Dialogue.say(["Here you are!\nThank you very much!"])


func _sell() -> void:
	var last := 0
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
		if items.is_empty():
			await Dialogue.say(["You don't have anything\nto sell."])
			return
		options.append("CANCEL")
		var index := await _pick(options, items, mini(last, items.size()))
		if index < 0 or index >= items.size():
			return
		last = index
		var item := items[index]
		if item.sell_price() <= 0:
			await Dialogue.say(["%s? Oh, I'm sorry,\nbut I can't buy that." % item.display_name])
			continue
		var count := await _quantity.pick(GameState.item_count(ids[index]), item.sell_price())
		if count <= 0:
			continue
		var total := count * item.sell_price()
		if await Dialogue.ask("I can pay $%d.\nWould that be OK?" % total) != 0:
			continue
		GameState.remove_item(ids[index], count)
		GameState.add_money(total)
		_refresh_money()
		Audio.play_sfx(&"purchase")
		await Dialogue.say(["Turned over the\n%s and received\n$%d." % [item.display_name, total]])


## Shows the item list with the highlighted item's description. Returns the
## picked index, or -1 if the player backs out. The list stays on screen while
## the player picks a quantity and confirms.
func _pick(options: PackedStringArray, items: Array[ItemData], start: int) -> int:
	var describe := func(index: int) -> void:
		_info.text = items[index].description if index < items.size() else "Go back."
	_list.cursor_moved.connect(describe)
	_info_box.show()
	var index: int = await _list.choose(options, start)
	_list.cursor_moved.disconnect(describe)
	_list.visible = index >= 0
	return index


func _refresh_money() -> void:
	_money.text = "MONEY\n$%d" % GameState.money
