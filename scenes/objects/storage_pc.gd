class_name StoragePC
extends StaticBody2D
## The PC in a MONSTER CENTER: it opens the MONSTER Storage System
## (StorageMenu) to withdraw, deposit or release monsters in the BOX.

const STORAGE_MENU := preload("res://scenes/ui/storage_menu.tscn")


func interact(_player: GridActor) -> void:
	Audio.play_sfx(&"pc_on")
	await Dialogue.say(["%s booted up\nthe PC." % GameState.player_name, "Accessed the MONSTER\nStorage System."])
	var menu: StorageMenu = STORAGE_MENU.instantiate()
	add_child(menu)
	await menu.run()
	menu.queue_free()
	Audio.play_sfx(&"pc_off")
