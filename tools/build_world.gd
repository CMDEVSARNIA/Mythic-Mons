extends SceneTree
## Builds the overworld TileSet and the starter maps from the ASCII layouts below.
##
## Usually run through tools/rebuild_placeholders.sh. To run it alone (after the
## placeholder PNGs have been imported):
##   godot --headless --path . --script res://tools/build_world.gd
##
## An existing TileSet or map scene is left alone, so edits made in the Godot
## editor are safe. Pass `-- --force` to regenerate everything from the data
## below (needed after changing PixelArt.TILES or TILE_RULES).

const TILESET_PATH := "res://assets/tilesets/overworld_tileset.tres"
const TILE_TEXTURE := "res://assets/placeholder/tiles/overworld_tiles.png"
const CHARACTER_DIR := "res://assets/placeholder/characters/"
const MAP_DIR := "res://scenes/maps/"

const WORLD_MAP_SCRIPT := "res://scenes/maps/world_map.gd"
const SPAWN_POINT_SCRIPT := "res://scenes/objects/spawn_point.gd"
const SCENES := {
	"npc": "res://scenes/actors/npc/npc.tscn",
	"sign": "res://scenes/objects/signpost.tscn",
	"warp": "res://scenes/objects/warp.tscn",
	"cut_tree": "res://scenes/objects/cut_tree.tscn",
	"smash_rock": "res://scenes/objects/smash_rock.tscn",
}

## Tile name -> [physics layer index (-1 none, 0 world, 1 water), terrain tag].
const TILE_RULES := {
	&"grass": [-1, &""],
	&"tall_grass": [-1, &"tall_grass"],
	&"path": [-1, &""],
	&"flowers": [-1, &""],
	&"sand": [-1, &""],
	&"ledge_down": [0, &"ledge_down"],
	&"tree": [0, &""],
	&"cliff": [0, &""],
	&"water": [1, &"water"],
	&"roof_red_l": [0, &""],
	&"roof_red_m": [0, &""],
	&"roof_red_r": [0, &""],
	&"roof_blue_l": [0, &""],
	&"roof_blue_m": [0, &""],
	&"roof_blue_r": [0, &""],
	&"wall": [0, &""],
	&"window": [0, &""],
	&"door": [-1, &""],
	&"fence": [0, &""],
	&"floor": [-1, &""],
	&"indoor_wall": [0, &""],
	&"mat": [-1, &""],
	&"table": [0, &""],
	&"bed": [0, &""],
	&"shelf": [0, &""],
	&"void": [0, &""],
}

## Layout character -> tile name.
const LEGEND := {
	".": &"grass", ",": &"tall_grass", ":": &"path", "*": &"flowers", "_": &"sand",
	"v": &"ledge_down", "#": &"tree", "^": &"cliff", "~": &"water",
	"[": &"roof_red_l", "=": &"roof_red_m", "]": &"roof_red_r",
	"{": &"roof_blue_l", "-": &"roof_blue_m", "}": &"roof_blue_r",
	"|": &"wall", "o": &"window", "D": &"door", "f": &"fence",
	"b": &"floor", "w": &"indoor_wall", "m": &"mat", "t": &"table", "B": &"bed", "k": &"shelf", "x": &"void",
}

# Facing values for spawns and NPCs (match Grid.DIRECTIONS).
const DOWN := 0
const UP := 1

# Map definitions. Entities are placed by cell; warps are [cell, map file, spawn, sfx].
const MAPS := [
	{
		"file": "town_emberfall.tscn",
		"node": "TownEmberfall",
		"props": {"display_name": "EMBERFALL TOWN", "is_town": true, "music": &"town"},
		"layout": [
			"#########::#########",
			"#*.......::.......*#",
			"#..[===]..::.[===].#",
			"#..[===]..::.[===].#",
			"#..|oDo|..::.|ooo|.#",
			"#....:....::.......#",
			"#....::::::::......#",
			"#.........::.......#",
			"#..***....::.......#",
			"#.........::.......#",
			"####.###..::.......#",
			"#**.**.#..::....**.#",
			"#*....*#...........#",
			"#**..**#...........#",
			"####################",
		],
		"spawns": {
			"default": [Vector2i(5, 5), DOWN],
			"from_house": [Vector2i(5, 5), DOWN],
			"from_route": [Vector2i(9, 1), DOWN],
			"fly": [Vector2i(10, 7), DOWN],
		},
		"warps": [
			[Vector2i(5, 4), "house_emberfall.tscn", "entrance", &"door"],
			[Vector2i(9, 0), "route_01.tscn", "south", &""],
			[Vector2i(10, 0), "route_01.tscn", "south", &""],
		],
		"signs": [
			[Vector2i(8, 7), ["EMBERFALL TOWN\nWhere every journey\nstarts with a spark."]],
		],
		"npcs": [
			[Vector2i(14, 8), "lass", 2, ["Hold SHIFT or X to run!", "Press ENTER for the menu.\nYou can FLY from there\nto towns you've visited."]],
			[Vector2i(3, 12), "elder", 1, ["Oh! You CUT your way into\nmy secret garden?", "Flowers grow best where\nfew people can reach."]],
		],
		"obstacles": [
			[Vector2i(4, 10), "cut_tree"],
		],
	},
	{
		"file": "house_emberfall.tscn",
		"node": "HouseEmberfall",
		"props": {"display_name": "YOUR HOUSE", "allow_fly": false, "music": &"town"},
		"layout": [
			"wwkkwwwwww",
			"bbbbbbbbBb",
			"bbbbbbbbbb",
			"bbtbbbbbbb",
			"bbtbbbbbbb",
			"bbbbbbbbbb",
			"bbbbmbbbbb",
		],
		"spawns": {
			"default": [Vector2i(4, 5), UP],
			"entrance": [Vector2i(4, 5), UP],
		},
		"warps": [
			[Vector2i(4, 6), "town_emberfall.tscn", "from_house", &"door"],
		],
		"npcs": [
			[Vector2i(6, 3), "mom", 1, ["MOM: Off exploring again?\nBe careful out there!", "Step on the mat by the\ndoor to head outside."]],
		],
	},
	{
		"file": "route_01.tscn",
		"node": "Route01",
		"props": {
			"display_name": "ROUTE 1", "music": &"route", "encounter_rate": 0.12,
			"wild_monsters": [&"sproutle", &"pebblet", &"zapkit", &"flamlet"],
		},
		"layout": [
			"#########::#########",
			"#........::........#",
			"#..,,,,..::..,,,,..#",
			"#..,,,,..::..,,,,..#",
			"#........::........#",
			"#..***...::...***..#",
			"#........::...,,,,.#",
			"#........::...,,,,.#",
			"#vvvvvvvvvvvvv,,,,.#",
			"#........::...,,,,.#",
			"#........::........#",
			"#^^^^....::........#",
			"#...^....::...,,,,.#",
			"#...^....::...,,,,.#",
			"#...^....::...,,,,.#",
			"#^.^^....::........#",
			"#........::........#",
			"#.,,,,,..::..,,,,,.#",
			"#.,,,,,..::..,,,,,.#",
			"#........::........#",
			"#........::........#",
			"#..***...::...***..#",
			"#........::........#",
			"#########::#########",
		],
		"spawns": {
			"default": [Vector2i(9, 22), UP],
			"south": [Vector2i(9, 22), UP],
			"north": [Vector2i(10, 1), DOWN],
		},
		"warps": [
			[Vector2i(9, 0), "town_tidewater.tscn", "from_route", &""],
			[Vector2i(10, 0), "town_tidewater.tscn", "from_route", &""],
			[Vector2i(9, 23), "town_emberfall.tscn", "from_route", &""],
			[Vector2i(10, 23), "town_emberfall.tscn", "from_route", &""],
		],
		"signs": [
			[Vector2i(8, 21), ["ROUTE 1\nNorth: TIDEWATER CITY\nSouth: EMBERFALL TOWN"]],
		],
		"npcs": [
			[Vector2i(12, 19), "hiker", 2, ["Ledges only go one way.", "Hop down them for a\nshortcut back south!"]],
			[Vector2i(2, 13), "elder", 0, ["Phew! I was stuck behind\nthat boulder for days!", "ROCK SMASH breaks cracked\nrocks like that one."]],
		],
		"obstacles": [
			[Vector2i(2, 15), "smash_rock"],
		],
	},
	{
		"file": "town_tidewater.tscn",
		"node": "TownTidewater",
		"props": {"display_name": "TIDEWATER CITY", "is_town": true, "music": &"town"},
		"layout": [
			"####################",
			"#~~~~~~~~~~~~~~~~~~#",
			"#~~____~~~~~~~~~~~~#",
			"#~~____~~~~~~~~~~~~#",
			"#~~~~~~~~~~~~~~~~~~#",
			"#~~~~~~~~~~~~~~~~~~#",
			"#__________________#",
			"#..................#",
			"#..{---}....{---}..#",
			"#..{---}....{---}..#",
			"#..|ooo|....|ooo|..#",
			"#..................#",
			"#....::::::::::....#",
			"#..**....::....**..#",
			"#........::........#",
			"#........::........#",
			"#........::........#",
			"#########::#########",
		],
		"spawns": {
			"default": [Vector2i(9, 14), DOWN],
			"fly": [Vector2i(9, 14), DOWN],
			"from_route": [Vector2i(9, 16), UP],
		},
		"warps": [
			[Vector2i(9, 17), "route_01.tscn", "north", &""],
			[Vector2i(10, 17), "route_01.tscn", "north", &""],
		],
		"signs": [
			[Vector2i(11, 14), ["TIDEWATER CITY\nWhere the sea meets\nthe sky."]],
			[Vector2i(4, 2), ["TREASURE ISLE", "...There's nothing here\nyet. Maybe in a future\nupdate!"]],
		],
		"npcs": [
			[Vector2i(14, 7), "swimmer", 2, ["See that island? Face the\nwater and press Z to SURF!"]],
		],
	},
]


func _initialize() -> void:
	var force := "--force" in OS.get_cmdline_user_args()
	if force or not FileAccess.file_exists(TILESET_PATH):
		_report(ResourceSaver.save(_build_tile_set(), TILESET_PATH), TILESET_PATH)
	else:
		_kept(TILESET_PATH)
	var tile_set := ResourceLoader.load(TILESET_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as TileSet
	for map: Dictionary in MAPS:
		var path: String = MAP_DIR + map.file
		if FileAccess.file_exists(path) and not force:
			_kept(path)
			continue
		var root := _build_map(map, tile_set)
		var scene := PackedScene.new()
		scene.pack(root)
		_report(ResourceSaver.save(scene, path), path)
		root.free()
	quit()


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(Grid.TILE_SIZE, Grid.TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, PhysicsLayers.WORLD)
	tile_set.set_physics_layer_collision_mask(0, 0)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(1, PhysicsLayers.WATER)
	tile_set.set_physics_layer_collision_mask(1, 0)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "terrain")
	tile_set.set_custom_data_layer_type(0, TYPE_STRING_NAME)

	var source := TileSetAtlasSource.new()
	source.texture = load(TILE_TEXTURE)
	source.texture_region_size = tile_set.tile_size
	tile_set.add_source(source, 0)

	var h := Grid.TILE_SIZE / 2.0
	var square := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	for tile_name: StringName in PixelArt.TILES:
		var coords: Vector2i = PixelArt.TILES[tile_name]
		var rule: Array = TILE_RULES[tile_name]
		source.create_tile(coords)
		if tile_name == &"water":
			source.set_tile_animation_frames_count(coords, 2)
			source.set_tile_animation_frame_duration(coords, 0, 0.6)
			source.set_tile_animation_frame_duration(coords, 1, 0.6)
		var data := source.get_tile_data(coords, 0)
		data.set_custom_data("terrain", rule[1])
		if rule[0] >= 0:
			data.add_collision_polygon(rule[0])
			data.set_collision_polygon_points(rule[0], 0, square)
	return tile_set


func _build_map(map: Dictionary, tile_set: TileSet) -> Node2D:
	var root := Node2D.new()
	root.name = map.node
	root.set_script(load(WORLD_MAP_SCRIPT))
	for property: String in map.props:
		var value: Variant = map.props[property]
		if property == "wild_monsters": # The export is typed, so convert the plain array.
			value = Array(value, TYPE_STRING_NAME, &"", null)
		root.set(property, value)

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tile_set
	_add(root, root, ground)
	var layout: Array = map.layout
	for y in layout.size():
		var row: String = layout[y]
		assert(row.length() == layout[0].length(), "%s row %d has the wrong width" % [map.file, y])
		for x in row.length():
			ground.set_cell(Vector2i(x, y), 0, PixelArt.TILES[LEGEND[row[x]]])

	var entities := Node2D.new()
	entities.y_sort_enabled = true
	_add(root, root, entities, "Entities")
	for i in map.get("signs", []).size():
		var def: Array = map.signs[i]
		var sign := _instance("sign", def[0], entities, root, "Sign%d" % (i + 1))
		sign.set(&"lines", PackedStringArray(def[1]))
	for i in map.get("npcs", []).size():
		var def: Array = map.npcs[i]
		var npc := _instance("npc", def[0], entities, root, "NPC_%s%d" % [def[1].capitalize(), i + 1])
		npc.set(&"sprite_sheet", load(CHARACTER_DIR + "npc_%s.png" % def[1]))
		npc.set(&"wander_radius", def[2])
		npc.set(&"lines", PackedStringArray(def[3]))
	for i in map.get("obstacles", []).size():
		var def: Array = map.obstacles[i]
		_instance(def[1], def[0], entities, root, "%s%d" % [def[1].to_pascal_case(), i + 1])

	var warps := _add(root, root, Node2D.new(), "Warps")
	for i in map.get("warps", []).size():
		var def: Array = map.warps[i]
		var warp := _instance("warp", def[0], warps, root, "Warp%d" % (i + 1))
		warp.set(&"target_map", MAP_DIR + def[1])
		warp.set(&"target_spawn", StringName(def[2]))
		warp.set(&"sfx", def[3])

	var spawns := _add(root, root, Node2D.new(), "Spawns")
	for id: String in map.spawns:
		var marker := Marker2D.new()
		marker.set_script(load(SPAWN_POINT_SCRIPT))
		marker.position = Grid.cell_to_world(map.spawns[id][0])
		marker.set(&"facing", map.spawns[id][1])
		_add(root, spawns, marker, id)
	return root


func _instance(kind: String, cell: Vector2i, parent: Node, root: Node, node_name: String) -> Node:
	# Edit-state instancing lets pack() store only the properties that differ.
	var node: Node2D = load(SCENES[kind]).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	node.position = Grid.cell_to_world(cell)
	return _add(root, parent, node, node_name)


func _add(root: Node, parent: Node, child: Node, node_name := "") -> Node:
	if not node_name.is_empty():
		child.name = node_name
	parent.add_child(child)
	child.owner = root
	return child


func _report(error: Error, path: String) -> void:
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), path])


func _kept(path: String) -> void:
	print("kept  %s (pass -- --force to rebuild)" % path)
