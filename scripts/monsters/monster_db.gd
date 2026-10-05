class_name MonsterDB
extends RefCounted
## Looks up data resources by id. Maps and scripts refer to species and moves
## by id (e.g. &"sproutle"), and the file name is the id.

const SPECIES_DIR := "res://data/species/"
const MOVES_DIR := "res://data/moves/"


static func species(id: StringName) -> MonsterSpecies:
	var path := "%s%s.tres" % [SPECIES_DIR, id]
	if not ResourceLoader.exists(path):
		push_error("Unknown species: %s" % id)
		return null
	return load(path)


static func move(id: StringName) -> MoveData:
	var path := "%s%s.tres" % [MOVES_DIR, id]
	if not ResourceLoader.exists(path):
		push_error("Unknown move: %s" % id)
		return null
	return load(path)
