class_name ShopClerk
extends NPC
## A MART clerk: talking opens a ShopMenu selling `stock`. Put clerks behind a
## counter tile; the player talks to them across it.

const SHOP_MENU := preload("res://scenes/ui/shop_menu.tscn")

@export var stock: Array[ItemData] = []


func _talk() -> void:
	var shop: ShopMenu = SHOP_MENU.instantiate()
	add_child(shop)
	await shop.run(stock)
	shop.queue_free()
