# Architecture

How the Mythic Mons foundation is put together: where files live, how the
scenes are built, and how the systems talk to each other.

Target engine: **Godot 4.7** (GDScript, GL Compatibility renderer).

## Directory structure

```
Mythic-Mons/
├── project.godot              Display, input map, autoloads, physics layer names
├── icon.png                   Generated (a monster at 4x)
├── autoload/                  Global singletons (Project Settings > Globals)
│   ├── events.gd              Events: signal bus (warp_requested, wild_encounter, map_entered)
│   ├── game_state.gd          GameState: unlocked field moves, visited towns, flags
│   └── audio.gd               Audio: music + SFX, real files first, chiptune fallback
├── scenes/
│   ├── main/                  Main scene: owns the current map, player, UI, fades
│   ├── actors/
│   │   ├── grid_actor.gd      Shared tile-locked movement (player and NPCs)
│   │   ├── player/            Player scene + input, interaction, surfing, ledges
│   │   └── npc/               Wandering, talking NPC
│   ├── maps/
│   │   ├── world_map.gd       Root script of every map (terrain lookups, spawns, encounters)
│   │   └── *.tscn             Emberfall, its house, Route 1, Tidewater
│   ├── objects/               Warp, SpawnPoint, Signpost, CUT tree, ROCK SMASH boulder
│   └── ui/                    Dialogue box (autoload), choice box, map-name banner
├── scripts/                   Non-scene code (class_name utilities)
│   ├── core/                  Grid, PhysicsLayers, Terrain constants
│   ├── art/pixel_art.gd       Procedural 8-bit art generator
│   └── audio/                 ChipSynth (SFX), Chiptune (sequencer), Songs (music data)
├── assets/
│   ├── placeholder/           Generated PNGs: tiles, characters, objects, monsters
│   ├── tilesets/              overworld_tileset.tres (physics + terrain custom data)
│   ├── ui/theme.tres          Pixel font, text-box style
│   ├── fonts/                 Press Start 2P (SIL OFL)
│   └── audio/music, sfx/      Drop real audio here to replace the generated sounds
├── tools/                     Headless generators (art, TileSet, starter maps)
├── tests/smoke_test.gd        Plays the game by injecting input and checks the results
└── docs/                      This file, ASSETS.md
```

Scenes keep their script next to them (`scenes/...`). Code that has no scene
lives in `scripts/`. Anything generated can be rebuilt with
`tools/rebuild_placeholders.sh`.

## Rendering setup

| Setting | Value | Why |
|---|---|---|
| Viewport | 240 × 160 | The Game Boy Advance resolution: 15 × 10 tiles on screen |
| Window | 960 × 640 | 4× scale |
| Stretch | `viewport`, scale mode `integer` | Renders at 240 × 160, then scales by whole pixels only |
| Texture filter | Nearest | Crisp pixels |
| Snap 2D transforms to pixel | On | No half-pixel shimmer while scrolling |
| Default clear color | `#1a1c2c` | Black border around interiors smaller than the screen |

## Node setups

### Main (`scenes/main/main.tscn`)

```
Main (Node)                              main.gd
├── World (Node2D)                       the current WorldMap is instanced here
├── Player (player.tscn)                 persistent; moved into each map's Entities
├── UI (CanvasLayer, layer 5)
│   ├── MapBanner (PanelContainer)       location name that slides in
│   ├── EncounterPreview (PanelContainer)
│   │   └── Art (TextureRect)
│   └── StartMenuArea (MarginContainer)
│       └── StartMenu (choice_box.tscn)
└── Transition (CanvasLayer, layer 20)
    └── Fade (ColorRect)                 fades and encounter flashes
```

Main never uses `change_scene_to_file()`. It swaps maps under `World` and keeps
the same Player node, so the player's state (facing, surfing) survives every
map change. The text box lives in its own autoload (`Dialogue`, CanvasLayer
layer 10) so any script can `await Dialogue.say([...])`.

### Player (`scenes/actors/player/player.tscn`)

```
Player (CharacterBody2D)                 player.gd → GridActor
│   collision_layer = actors, collision_mask = world | water | actors | obstacles
├── CollisionShape2D                     12 × 12 rectangle, centered on the tile
├── Shadow (Sprite2D)                    shown under the player during hops
└── Visual (Node2D)                      receives the smooth slide offset
    ├── SurfMount (Sprite2D)             visible while surfing
    ├── Sprite2D                         3 × 4 frame sheet (stand, step A, step B × down/up/left/right)
    └── Camera2D                         follows the smooth position; limits set per map
```

NPCs (`npc.tscn`) use the same layout without the camera and surf mount.

### Map (`scenes/maps/*.tscn`)

```
TownEmberfall (Node2D)                   world_map.gd: display_name, is_town, allow_fly,
│                                        music, encounter_rate, wild_monsters
├── Ground (TileMapLayer)                overworld_tileset.tres
├── Entities (Node2D, Y Sort enabled)    NPCs, signs, field obstacles (+ the player at runtime)
├── Warps (Node2D)                       warp.tscn areas on doors and map edges
└── Spawns (Node2D)                      SpawnPoint markers: "default", "fly", "from_route", …
```

Add more `TileMapLayer`s (decor, overhead) as siblings of `Ground` whenever
you like. `WorldMap.get_terrain()` reads the topmost tile that sets a terrain.

## Physics layers

| # | Name | Bit | Used by |
|---|---|---|---|
| 1 | world | 1 | Solid tiles (trees, walls, roofs, ledges), signs |
| 2 | water | 2 | Water tiles |
| 3 | actors | 4 | Player and NPCs |
| 4 | obstacles | 8 | CUT trees, ROCK SMASH boulders |
| 5 | triggers | 16 | Warps (areas; never block movement) |

Surfing works by removing the `water` bit from the player's
`collision_mask`. Land is not solid, so steering back onto it simply works,
and the player dismounts with a hop.

## Grid movement

Everything walks on a 16 × 16 grid. A node standing on a cell sits at the
cell's center (`Grid.cell_to_world()`).

1. **Collision check.** `GridActor.is_cell_free()` places the actor's own shape
   on the target cell with a physics shape query. If it overlaps anything in
   the actor's `collision_mask`, or the cell is outside the map, the step is
   refused. Solid tiles come from the TileSet's physics layers, so you set up
   collision while painting in the editor.
2. **Reserve the tile.** The `CharacterBody2D` jumps to the target cell at once.
   Every other actor's check now sees that tile as taken, so two actors can
   never walk into the same cell.
3. **Animate.** Only the `Visual` child is offset back to the start and slid to
   zero over the step (3.75 tiles/s walking, 7.5 running or surfing, the same
   speeds as Emerald). The camera rides on `Visual`, so scrolling is smooth.
4. **Arrive.** `_on_step_finished()` runs. The player checks for a Warp on the
   cell, then for tall grass (encounter roll). If a direction is still held,
   the next step starts on the same frame, so walking never stutters.

`move_and_slide()` isn't used on purpose. Tile games want exact, discrete
steps, and the body only needs to exist so collision queries can see it.

Player specifics, mirroring Emerald:

- A tap on a new direction turns in place; holding it for 0.1 s starts walking.
- Hold **run** (Shift/X) to move at double speed.
- Walking into something solid plays a bump sound and walks in place.
- Ledge tiles are solid, except when approached in their direction: then the
  player hops two tiles with a shadow underneath.

## Terrain data

The TileSet has a custom data layer named `terrain` (StringName). Current tags
are listed in `scripts/core/terrain.gd`: `tall_grass`, `water`, `ledge_down`,
`ledge_left`, `ledge_right`. Normal ground leaves it empty. Add a tag there,
assign it in the TileSet editor (or `TILE_RULES` in `tools/build_world.gd`),
and react to it in `Player._try_step()` / `_on_step_finished()`.

## Field moves

| Move | How it works |
|---|---|
| CUT / ROCK SMASH | `FieldObstacle` (StaticBody2D on `obstacles`). Pressing A asks to use the move, then plays an effect and frees the node. It returns when the map reloads, like Emerald. |
| SURF | Press A facing water. The player gets the surf mount, loses the `water` collision bit and hops in. Moving onto land hops back out. |
| FLY | Start menu (Enter) → FLY lists `GameState.visited_towns`. A map with `is_town = true` registers itself when entered. A map with `allow_fly = false` (interiors) refuses. Lands on the target town's `fly` spawn. |

`GameState.can_use_field_move()` decides availability. For now everything is
unlocked so the prototype is testable. Later, make it check the party's moves
and badges.

## Communication

- **Events (signal bus):** `warp_requested(map_path, spawn_id)` is the only way
  maps change, used by warps and Fly. `wild_encounter(species_id)` is handled
  by Main, which shows a placeholder until the battle system lands.
  `map_entered(map)` is there for quests and achievements.
- **Interaction protocol:** anything with an `interact(player)` method on the
  `world`, `actors` or `obstacles` layer can be talked to. Anything with
  `on_player_entered(player)` on the `triggers` layer fires when stepped on.
  New interactables need no changes to the player.
- **Locking:** `Player.lock()` / `unlock()` nest. Dialogue, menus, warps and
  encounters lock the player while they run.
- **Input:** confirm, cancel and menu are handled as events (`_input` /
  `_unhandled_input`). The text box marks the press that closes it as handled,
  so it can't immediately re-trigger the sign you just read. Movement is polled.

## Adding a map

1. Duplicate a map scene (or extend `MAPS` in `tools/build_world.gd` and run it).
2. Paint `Ground` with `overworld_tileset.tres`.
3. Add `SpawnPoint` markers under `Spawns`, named by id.
4. Add `warp.tscn` instances under `Warps`. Set `target_map` and `target_spawn`.
5. Set `display_name`, `music`, `is_town`, and the encounter table in the inspector.

## Tests

`tests/smoke_test.gd` plays the real game by injecting input and checks 23
behaviors: turning, walking, bumping, signs, NPCs, CUT, doors, map edges,
ledges, ROCK SMASH, encounters, SURF and FLY.

```sh
godot --headless --path . --fixed-fps 60 --script res://tests/smoke_test.gd
```
