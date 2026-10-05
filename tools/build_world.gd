extends SceneTree
## Builds the overworld TileSet and the starter maps from the ASCII layouts below.
##
## Usually run through tools/rebuild_placeholders.sh. To run it alone (after the
## placeholder PNGs have been imported):
##   godot --headless --path . --script res://tools/build_world.gd
##
## An existing TileSet or map scene is left alone, so edits made in the Godot
## editor are safe. Pass `-- --force` to regenerate everything from the data
## below (needed after changing WorldTiles or TILE_RULES).

const TILESET_PATH := "res://assets/tilesets/overworld_tileset.tres"
## The TileSet's only source: WorldTiles.ATLAS.
const SOURCE := 0
const CHARACTER_DIR := "res://assets/placeholder/characters/"
## Converted pack sprites (tools/import_townsfolk.gd), used before the cast.
const TOWNSFOLK_DIR := "res://assets/characters/townsfolk/"
const MAP_DIR := "res://scenes/maps/"

const WORLD_MAP_SCRIPT := "res://scenes/maps/world_map.gd"
const SPAWN_POINT_SCRIPT := "res://scenes/objects/spawn_point.gd"
const SCENES := {
	"npc": "res://scenes/actors/npc/npc.tscn",
	"professor": "res://scenes/actors/npc/professor.tscn",
	"clerk": "res://scenes/actors/npc/clerk.tscn",
	"trainer": "res://scenes/actors/npc/trainer.tscn",
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
	&"shore_north": [1, &"water"],
	&"shore_south": [1, &"water"],
	&"fence": [0, &""],
	&"floor": [-1, &""],
	&"indoor_wall": [0, &""],
	&"mat": [-1, &""],
	&"table": [0, &""],
	&"bed": [0, &""],
	&"shelf": [0, &""],
	&"counter": [0, &"counter"],
	&"mart_shelf": [0, &""],
	&"plant": [0, &""],
	&"crate": [0, &""],
	&"void": [0, &""],
}

## What the player reads on pressing A at a tile, like Emerald's furniture.
const EXAMINE := {
	&"shelf": "It's crammed full of\nbooks about MONSTERS.",
	&"mart_shelf": "Rows of ORBs and POTIONs,\nall lined up.",
	&"bed": "A soft, comfy bed.\nNo time for a nap now!",
	&"plant": "A leafy potted plant.\nSomeone waters it daily.",
	&"crate": "A sturdy wooden crate.\nIt won't budge.",
}

## Layout character -> tile name.
const LEGEND := {
	".": &"grass", ",": &"tall_grass", ":": &"path", "*": &"flowers", "_": &"sand",
	"v": &"ledge_down", "#": &"tree", "^": &"cliff", "~": &"water", "f": &"fence",
	"b": &"floor", "w": &"indoor_wall", "m": &"mat", "t": &"table", "B": &"bed", "k": &"shelf", "x": &"void",
	"c": &"counter", "s": &"mart_shelf", "p": &"plant", "r": &"crate",
}

## Turns the player back at Emberfall's north exit until they have a starter.
const STARTER_GATE := {
	"required_flag": "got_starter",
	"blocked_lines": ["PROF. ASTER: Wait! Wild\nMONSTERS live in the\ntall grass up there!", "Come see me in my LAB\nfirst. It's just east!"],
}

# Facing values for spawns and NPCs (match Grid.DIRECTIONS).
const DOWN := 0
const UP := 1

## Shared by the small houses' interiors.
const HOUSE_LAYOUT := [
	"wwkkwwwwww",
	"pbbbbbbbBb",
	"bbbbbbbbbb",
	"bbtbbbbbbb",
	"bbtbbbbbbr",
	"bbbbbbbbbb",
	"bbbbmbbbbb",
]

# Map definitions. Entities are placed by cell.
#   signs:     [cell, pages]
#   npcs:      [cell, sprite id, wander radius, lines, {scene, property overrides}]
#   warps:     [cell, map file, spawn, sfx, {property overrides}]
#   obstacles: [cell, scene]
#   houses:    [top-left cell, roof in WorldTiles.HOUSES]; the door is at
#              WorldTiles.HOUSE_DOOR from the top-left, so put a warp there
const MAPS := [
	{
		"file": "town_emberfall.tscn",
		"node": "TownEmberfall",
		"props": {
			"display_name": "EMBERFALL TOWN", "is_town": true, "music": &"town",
			# Only the secret garden has tall grass.
			"encounter_rate": 0.15, "wild_monsters": [&"shadeling"], "wild_levels": Vector2i(3, 5),
		},
		"layout": [
			"###########::###########",
			"#*.........::.........*#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#....:.....::.....:....#",
			"#....::::::::::::::::..#",
			"#..........::..........#",
			"#..***.....::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"####.####..::..........#",
			"#**.**,,#..::....:.....#",
			"#*...,,,#..::::::::....#",
			"#**..,,,#..............#",
			"########################",
		],
		"houses": [
			[Vector2i(3, 2), &"wood"],
			[Vector2i(16, 2), &"slate"],
			[Vector2i(15, 9), &"wood"],
		],
		"spawns": {
			"default": [Vector2i(5, 7), DOWN],
			"from_house": [Vector2i(5, 7), DOWN],
			"from_lab": [Vector2i(18, 7), DOWN],
			"from_rival_house": [Vector2i(17, 14), DOWN],
			"from_route": [Vector2i(11, 1), DOWN],
			"fly": [Vector2i(11, 9), DOWN],
		},
		"warps": [
			[Vector2i(5, 6), "house_emberfall.tscn", "entrance", &"door"],
			[Vector2i(18, 6), "lab_emberfall.tscn", "entrance", &"door"],
			[Vector2i(17, 13), "house_rival.tscn", "entrance", &"door"],
			[Vector2i(11, 0), "route_01.tscn", "south", &"", STARTER_GATE],
			[Vector2i(12, 0), "route_01.tscn", "south", &"", STARTER_GATE],
		],
		"signs": [
			[Vector2i(9, 7), ["EMBERFALL TOWN\nWhere every journey\nstarts with a spark."]],
			[Vector2i(20, 7), ["PROF. ASTER's\nMONSTER LAB"]],
			[Vector2i(14, 14), ["REN's HOUSE"]],
		],
		"npcs": [
			[Vector2i(14, 16), "lass", 2, ["Hold SHIFT or X to run!", "Press ENTER for the menu.\nYou can FLY from there\nto towns you've visited."]],
			[Vector2i(3, 15), "elder", 1, ["Oh! You CUT your way into\nmy secret garden?", "Flowers grow best where\nfew people can reach.", "But something giggles in\nmy tall grass at night..."]],
			[Vector2i(6, 11), "gardener", 1, ["SPROUTLE's SUNSOAK\nheals it a little at\nthe end of each turn.", "Sunshine and patience.\nThat's all a garden\nneeds!"]],
		],
		"obstacles": [
			[Vector2i(4, 13), "cut_tree"],
		],
	},
	{
		"file": "house_emberfall.tscn",
		"node": "HouseEmberfall",
		"props": {"display_name": "YOUR HOUSE", "allow_fly": false, "music": &"town"},
		"layout": HOUSE_LAYOUT,
		"spawns": {
			"default": [Vector2i(4, 5), UP],
			"entrance": [Vector2i(4, 5), UP],
		},
		"warps": [
			[Vector2i(4, 6), "town_emberfall.tscn", "from_house", &"door"],
		],
		"npcs": [
			[Vector2i(6, 3), "mom", 1, ["MOM: Welcome home! Rest\nhere whenever you need."], {"heals_party": true}],
		],
	},
	{
		"file": "lab_emberfall.tscn",
		"node": "LabEmberfall",
		"props": {"display_name": "MONSTER LAB", "allow_fly": false, "music": &"town"},
		"layout": [
			"wwkkwwwwkkww",
			"pbbbbbbbbbbp",
			"bbbbbbbbbbbb",
			"bttbbbbbbttb",
			"bbbbbbbbbbbb",
			"kbbbbbbbbbbk",
			"kbbbbbbbbbbk",
			"bbbbbmbbbbbb",
		],
		"spawns": {
			"default": [Vector2i(5, 6), UP],
			"entrance": [Vector2i(5, 6), UP],
		},
		"warps": [
			[Vector2i(5, 7), "town_emberfall.tscn", "from_lab", &"door"],
		],
		"npcs": [
			[Vector2i(5, 2), "professor", 0, [], {"scene": "professor"}],
		],
	},
	{
		"file": "house_rival.tscn",
		"node": "HouseRival",
		"props": {"display_name": "REN's HOUSE", "allow_fly": false, "music": &"town"},
		"layout": HOUSE_LAYOUT,
		"spawns": {
			"default": [Vector2i(4, 5), UP],
			"entrance": [Vector2i(4, 5), UP],
		},
		"warps": [
			[Vector2i(4, 6), "town_emberfall.tscn", "from_rival_house", &"door"],
		],
		"npcs": [
			[Vector2i(6, 2), "rival", 1, ["REN: Hey, you're the\nnew kid! I'm REN.", "Got a MONSTER from PROF.\nASTER yet? Let's battle\nsomeday!"]],
			[Vector2i(2, 5), "lass", 1, ["My brother REN wants to\ncatch every MONSTER on\nROUTE 1!"]],
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
			[Vector2i(5, 4), "youngster", 1, ["My FLAMLET's KINDLE\nkicks in when its HP\nis low!", "Its fire moves hit way\nharder then. Never\ngive up!"]],
			[Vector2i(16, 11), "fighter", 0, ["Hup! Hah! I train on\nthis route every day!", "LEER lowers a foe's\nDEFENSE. Then hit it\nwith everything!"]],
			# Trainers watch `sight` tiles ahead (start_facing: 0 down, 1 up, 2 left, 3 right).
			[Vector2i(7, 16), "lass", 0, [], {"scene": "trainer", "data": "lass_mia", "sight": 4, "start_facing": 3}],
			[Vector2i(12, 7), "youngster", 0, [], {"scene": "trainer", "data": "youngster_tim", "sight": 5, "start_facing": 3}],
			[Vector2i(12, 1), "rival", 0, [], {"scene": "trainer", "data": "rival_ren", "sight": 4, "start_facing": 2}],
		],
		"obstacles": [
			[Vector2i(2, 15), "smash_rock"],
		],
	},
	{
		"file": "town_tidewater.tscn",
		"node": "TownTidewater",
		"props": {
			"display_name": "TIDEWATER CITY", "is_town": true, "music": &"town",
			"water_monsters": [&"aquapup"], "water_encounter_rate": 0.08, "wild_levels": Vector2i(4, 6),
		},
		"layout": [
			"########################",
			"#~~~~~~~~~~~~~~~~~~~~~~#",
			"#~~___~~~~~~~~~~~~~~~~~#",
			"#~~___~~~~~~~~~~~~~~~~~#",
			"#~~~~~~~~~~~~~~~~~~~~~~#",
			"#______________________#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#...:......::......:...#",
			"#...::::::::::::::::...#",
			"#..**......::......**..#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::..........#",
			"#..........::::::::....#",
			"###########::###########",
		],
		"houses": [
			[Vector2i(2, 7), &"blue"],
			[Vector2i(17, 7), &"red"],
			[Vector2i(16, 15), &"wood"],
		],
		"spawns": {
			"default": [Vector2i(11, 15), DOWN],
			"fly": [Vector2i(19, 12), DOWN],
			"from_route": [Vector2i(11, 20), UP],
			"from_mart": [Vector2i(4, 12), DOWN],
			"from_center": [Vector2i(19, 12), DOWN],
			"from_house": [Vector2i(18, 20), DOWN],
		},
		"warps": [
			[Vector2i(11, 21), "route_01.tscn", "north", &""],
			[Vector2i(12, 21), "route_01.tscn", "north", &""],
			[Vector2i(4, 11), "mart_tidewater.tscn", "entrance", &"door"],
			[Vector2i(19, 11), "center_tidewater.tscn", "entrance", &"door"],
			[Vector2i(18, 19), "house_tidewater.tscn", "entrance", &"door"],
		],
		"signs": [
			[Vector2i(9, 14), ["TIDEWATER CITY\nWhere the sea meets\nthe sky."]],
			[Vector2i(4, 2), ["TREASURE ISLE", "...There's nothing here\nyet. Maybe in a future\nupdate!"]],
			[Vector2i(6, 12), ["TIDEWATER MART\nOrbs and medicine for\nevery trainer!"]],
			[Vector2i(17, 12), ["MONSTER CENTER\nWe heal your MONSTERS\nfor free!"]],
		],
		"npcs": [
			[Vector2i(15, 5), "swimmer", 2, ["See that island? Face the\nwater and press Z to SURF!", "Wild AQUAPUP swim out\nthere. Bring MON ORBs!"]],
			[Vector2i(10, 19), "officer", 0, ["Welcome to TIDEWATER\nCITY! I keep the\npeace around here.", "Off on a trip? Open\nthe menu and SAVE\nbefore you go!"]],
			[Vector2i(21, 13), "mystic", 1, ["I see... FIRE burns\nGRASS, GRASS drinks\nWATER...", "...and WATER douses\nFIRE. The spirits\nnever lie."]],
		],
	},
	{
		"file": "mart_tidewater.tscn",
		"node": "MartTidewater",
		"props": {"display_name": "TIDEWATER MART", "allow_fly": false, "music": &"town"},
		"layout": [
			"wwwwwwwwww",
			"bbcbbbbbbp",
			"bbcbbssbbb",
			"cccbbssbbb",
			"bbbbbbbbbr",
			"bbbbbbbbbb",
			"bbbbmbbbbb",
		],
		"spawns": {
			"default": [Vector2i(4, 5), UP],
			"entrance": [Vector2i(4, 5), UP],
		},
		"warps": [
			[Vector2i(4, 6), "town_tidewater.tscn", "from_mart", &"door"],
		],
		"npcs": [
			# Two counters, like a department store: everyday goods, and
			# specialty orbs plus evolution stones.
			[Vector2i(1, 2), "clerk", 0, [], {"scene": "clerk", "start_facing": 3,
				"stock": ["mon_orb", "super_orb", "hyper_orb", "potion", "big_potion"]}],
			[Vector2i(1, 1), "clerk", 0, [], {"scene": "clerk", "start_facing": 3,
				"stock": ["net_orb", "dive_orb", "nest_orb", "repeat_orb", "timer_orb", "bolt_stone", "dusk_stone"]}],
			[Vector2i(8, 4), "hiker", 1, ["I always stock up on\nPOTIONs before a long\ntrip.", "The upper counter sells\nspecial ORBs. A DIVE ORB\nis great at sea!", "Buy 10 MON ORBs at once\nand they throw in a\nGALA ORB for free!"]],
		],
	},
	{
		"file": "center_tidewater.tscn",
		"node": "CenterTidewater",
		"props": {"display_name": "MONSTER CENTER", "allow_fly": false, "music": &"town"},
		"layout": [
			"wwwwwwwwwwww",
			"bbbbbbbbbbbb",
			"kkcccccccckk",
			"bbbbbbbbbbbb",
			"pbbbbbbbbbbp",
			"btbbbbbbbbtb",
			"bbbbbbbbbbbb",
			"bbbbbmbbbbbb",
		],
		"spawns": {
			"default": [Vector2i(5, 6), UP],
			"entrance": [Vector2i(5, 6), UP],
		},
		"warps": [
			[Vector2i(5, 7), "town_tidewater.tscn", "from_center", &"door"],
		],
		"npcs": [
			[Vector2i(5, 1), "nurse", 0, ["Welcome to the MONSTER\nCENTER!", "We'll restore your\nMONSTERS to full health."], {"heals_party": true}],
			[Vector2i(9, 4), "lass", 1, ["MONSTER CENTERs heal\nyour team for free.", "Come here whenever your\nMONSTERS are tired!"]],
		],
	},
	{
		"file": "house_tidewater.tscn",
		"node": "HouseTidewater",
		"props": {"display_name": "SEASIDE HOUSE", "allow_fly": false, "music": &"town"},
		"layout": HOUSE_LAYOUT,
		"spawns": {
			"default": [Vector2i(4, 5), UP],
			"entrance": [Vector2i(4, 5), UP],
		},
		"warps": [
			[Vector2i(4, 6), "town_tidewater.tscn", "from_house", &"door"],
		],
		"npcs": [
			[Vector2i(6, 2), "elder", 1, ["I've fished these waters\nfor fifty years.", "Someday I'll SURF out\nto that island myself!"]],
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
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(1, "examine")
	tile_set.set_custom_data_layer_type(1, TYPE_STRING)

	var source := TileSetAtlasSource.new()
	source.texture = load(WorldTiles.ATLAS)
	source.texture_region_size = tile_set.tile_size
	tile_set.add_source(source, SOURCE)
	for tile_name: StringName in WorldTiles.TILES:
		var count := 4 if tile_name == &"water" else 1 # Open water is a 2x2 pattern.
		for i in count:
			var coords: Vector2i = WorldTiles.TILES[tile_name] + Vector2i(i, 0)
			source.create_tile(coords)
			_set_rule(source, coords, TILE_RULES[tile_name])
			source.get_tile_data(coords, 0).set_custom_data("examine", EXAMINE.get(tile_name, ""))
	# Houses are solid except for the door.
	for roof: StringName in WorldTiles.HOUSES:
		for y in WorldTiles.HOUSE_SIZE.y:
			for x in WorldTiles.HOUSE_SIZE.x:
				var coords: Vector2i = WorldTiles.HOUSES[roof] + Vector2i(x, y)
				source.create_tile(coords)
				_set_rule(source, coords, [-1 if Vector2i(x, y) == WorldTiles.HOUSE_DOOR else 0, &""])
	return tile_set


## Applies a TILE_RULES entry, [physics layer or -1, terrain], to one tile.
func _set_rule(source: TileSetAtlasSource, coords: Vector2i, rule: Array) -> void:
	var h := Grid.TILE_SIZE / 2.0
	var data := source.get_tile_data(coords, 0)
	data.set_custom_data("terrain", rule[1])
	if rule[0] >= 0:
		data.add_collision_polygon(rule[0])
		data.set_collision_polygon_points(rule[0], 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))


func _build_map(map: Dictionary, tile_set: TileSet) -> Node2D:
	var root := Node2D.new()
	root.name = map.node
	root.set_script(load(WORLD_MAP_SCRIPT))
	for property: String in map.props:
		var value: Variant = map.props[property]
		if property in ["wild_monsters", "water_monsters"]: # Typed exports: convert the plain array.
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
			_paint(ground, layout, Vector2i(x, y))
	if map.has("houses"):
		var buildings := TileMapLayer.new()
		buildings.name = "Buildings"
		buildings.tile_set = tile_set
		_add(root, root, buildings)
		for def: Array in map.houses:
			for y in WorldTiles.HOUSE_SIZE.y:
				for x in WorldTiles.HOUSE_SIZE.x:
					buildings.set_cell(def[0] + Vector2i(x, y), SOURCE, WorldTiles.HOUSES[def[1]] + Vector2i(x, y))

	var entities := Node2D.new()
	entities.y_sort_enabled = true
	_add(root, root, entities, "Entities")
	for i in map.get("signs", []).size():
		var def: Array = map.signs[i]
		var sign := _instance("sign", def[0], entities, root, "Sign%d" % (i + 1))
		sign.set(&"lines", PackedStringArray(def[1]))
	for i in map.get("npcs", []).size():
		var def: Array = map.npcs[i]
		var props: Dictionary = def[4] if def.size() > 4 else {}
		var npc := _instance(props.get("scene", "npc"), def[0], entities, root, "NPC_%s%d" % [def[1].capitalize(), i + 1])
		npc.set(&"sprite_sheet", load(_sprite_path(def[1])))
		npc.set(&"wander_radius", def[2])
		if not def[3].is_empty():
			npc.set(&"lines", PackedStringArray(def[3]))
		_apply(npc, props)
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
		_apply(warp, def[4] if def.size() > 4 else {})

	var spawns := _add(root, root, Node2D.new(), "Spawns")
	for id: String in map.spawns:
		var marker := Marker2D.new()
		marker.set_script(load(SPAWN_POINT_SCRIPT))
		marker.position = Grid.cell_to_world(map.spawns[id][0])
		marker.set(&"facing", map.spawns[id][1])
		_add(root, spawns, marker, id)
	return root


## Paints one layout cell. Water next to land gets a line of foam, and open
## water a ripple pattern.
func _paint(ground: TileMapLayer, layout: Array, cell: Vector2i) -> void:
	var tile_name: StringName = LEGEND[layout[cell.y][cell.x]]
	var coords: Vector2i = WorldTiles.TILES[tile_name]
	if tile_name == &"water":
		if _is_shore(layout, cell + Vector2i.DOWN):
			coords = WorldTiles.TILES[&"shore_south"]
		elif _is_shore(layout, cell + Vector2i.UP):
			coords = WorldTiles.TILES[&"shore_north"]
		else:
			coords = WorldTiles.water_at(cell)
	ground.set_cell(cell, SOURCE, coords)


## True if `cell` is land that water foams against (not water, trees or the edge).
func _is_shore(layout: Array, cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= layout.size():
		return false
	return not LEGEND[layout[cell.y][cell.x]] in [&"water", &"tree"]


func _sprite_path(id: String) -> String:
	var path := TOWNSFOLK_DIR + "%s.png" % id
	return path if ResourceLoader.exists(path) else CHARACTER_DIR + "npc_%s.png" % id


## Sets extra properties from a map table; lists become PackedStringArrays,
## except a clerk's "stock", which lists item ids. A trainer's "data" names
## its file in data/trainers/.
func _apply(node: Node, props: Dictionary) -> void:
	for property: String in props:
		if property == "scene":
			continue
		var value: Variant = props[property]
		if property == "data":
			node.set(property, load("res://data/trainers/%s.tres" % value))
		elif property == "stock":
			var items: Array[ItemData] = []
			for id: String in value:
				items.append(load("res://data/items/%s.tres" % id))
			node.set(property, items)
		else:
			node.set(property, PackedStringArray(value) if value is Array else value)


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
