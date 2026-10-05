class_name GameData
extends RefCounted
## Looks up data resources by id. Maps and scripts refer to species, moves and
## items by id (e.g. &"sproutle"), and the file name is the id.

const SPECIES_DIR := "res://data/species/"
const MOVES_DIR := "res://data/moves/"
const ITEMS_DIR := "res://data/items/"


static func species(id: StringName) -> MonsterSpecies:
	return _load(SPECIES_DIR, id, "species")


static func move(id: StringName) -> MoveData:
	return _load(MOVES_DIR, id, "move")


static func item(id: StringName) -> ItemData:
	return _load(ITEMS_DIR, id, "item")


static func _load(dir: String, id: StringName, kind: String) -> Resource:
	var path := "%s%s.tres" % [dir, id]
	if not ResourceLoader.exists(path):
		push_error("Unknown %s: %s" % [kind, id])
		return null
	return load(path)
