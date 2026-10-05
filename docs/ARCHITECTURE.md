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
│   ├── game_state.gd          GameState: party, respawn point, field moves, visited towns, flags
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
│   ├── battle/                BattleScene (menus + animation), BattlerPanel, StatBar
│   └── ui/                    Dialogue box (autoload), choice box, map-name banner
├── scripts/                   Non-scene code (class_name utilities)
│   ├── core/                  Grid, PhysicsLayers, Terrain, GameData (id → resource lookups)
│   ├── monsters/              MonsterSpecies, MoveData, LevelMove, Monster, TypeChart,
│   │                          Ability + abilities/ (one script per behavior)
│   ├── items/                 ItemData (orbs, potions)
│   ├── battle/                Battle (the rules) and Battler (a monster on the field)
│   ├── art/pixel_art.gd       Procedural 8-bit art generator
│   └── audio/                 ChipSynth (SFX), Chiptune (sequencer), Songs (music data)
├── data/                      Game data as .tres, file name = id
│   ├── species/               flamlet, aquapup, sproutle, pebblet, zapkit, shadeling
│   ├── moves/                 tackle, ember, water_gun, ...
│   ├── abilities/             kindle, soak_up, sunsoak, sturdy_shell, jolt, dread
│   └── items/                 mon_orb, super_orb, master_orb, potion
├── assets/
│   ├── placeholder/           Generated PNGs: tiles, characters, objects, monsters
│   ├── tilesets/              overworld_tileset.tres (physics + terrain custom data)
│   ├── ui/theme.tres          Pixel font, text-box style
│   ├── fonts/                 Press Start 2P (SIL OFL)
│   └── audio/music, sfx/      Drop real audio here to replace the generated sounds
├── tools/                     Headless generators (art, TileSet, starter maps, monster data)
├── tests/                     battle_test.gd (rules) and smoke_test.gd (plays the game)
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
│   └── StartMenuArea (MarginContainer)
│       └── StartMenu (choice_box.tscn)
├── BattleLayer (CanvasLayer, layer 8)   a BattleScene is added here during battles
└── Transition (CanvasLayer, layer 20)
    └── Fade (ColorRect)                 fades and encounter flashes
```

Main never uses `change_scene_to_file()`. It swaps maps under `World` and keeps
the same Player node, so the player's state (facing, surfing) survives every
map change. Battles work the same way: the BattleScene covers the screen on
`BattleLayer` while `World` is paused underneath. The text box lives in its own autoload (`Dialogue`, CanvasLayer
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

## Monsters & battles

### Data

| Resource | Holds |
|---|---|
| `MonsterSpecies` (`data/species/*.tres`) | Name, element, ability, front/back sprites, 5 base stats, catch rate, EXP yield, learnset (`LevelMove` entries) |
| `MoveData` (`data/moves/*.tres`) | Name, element, PHYSICAL/SPECIAL/STATUS, power, accuracy, PP, priority, optional stat changes |
| `Ability` subclasses (`data/abilities/*.tres`) | A configured behavior, e.g. `ElementBoostAbility` with element = fire is KINDLE |
| `Monster` (runtime, a Resource so it can be saved) | Species, level, EXP, current HP, IVs, moves and remaining PP |

Stats are simplified from Generation 3: five stats (HP, ATTACK, DEFENSE,
SPECIAL, SPEED, where one SPECIAL serves for both attack and defense as in
the 8-bit games), IVs 0-15, no EVs, and the "medium fast" n³ EXP curve. Maps
and code refer to species, moves and items by id (`GameData.species(&"zapkit")`),
and the id is the file name.

### Rules vs. presentation

`Battle` (scripts/battle/battle.gd) holds every rule and nothing visual. Each
call (`start()`, `take_turn(action)`, `switch_after_faint(i)`) returns an
ordered list of events: `message`, `attack`, `hit`, `hp`, `stat`, `faint`,
`withdraw`, `send_out`, `flee`, `restore`, `throw`, `shake`, `caught`,
`break_free`. `BattleScene` only asks for the player's
action and plays those events back as text, sounds and tweens. This keeps the
rules fast to unit-test and reusable for trainer battles.

Turn flow: both sides pick moves. Higher priority goes first, then higher
SPEED. Each move checks accuracy, then type effectiveness (immunities stop
it), crits (1/16, 2×), the Gen 3 damage formula with STAB and an 85-100%
roll, then ability hooks and stat effects. At the end of the turn,
end-of-turn abilities run. RUN uses Gen 3 escape odds. A monster out of PP
uses STRUGGLE.

### Items and catching

Actions are FIGHT, SWITCH, RUN and ITEM. Using an item takes your turn, like
in Emerald. BattleScene removes it from `GameState.bag` (item id → count),
and the engine applies it:

- **Orbs** (`ItemData.Kind.BALL`) run the Gen 3 check in
  `Battle.catch_shakes()`:
  `rate = (3·maxHP − 2·HP) · catch_rate · ball / (3·maxHP)`.
  At 255 or more the catch is certain. Otherwise four checks each pass with
  probability `1048560 / ⁴√(16711680 / rate) / 65536`. The orb wobbles once
  per passed check, up to three times, and all four passing is a catch. A
  SPROUTLE (catch rate 190) is about a 25% catch at full HP and 74% at 1 HP.
- **Healing items** (`Kind.HEAL`) restore HP to the active monster.

On a catch the battle ends with `Outcome.CAUGHT`, and
`GameState.add_monster()` puts the monster in the party, or in
`GameState.storage` (the BOX) when the party has six. A caught monster keeps
its current HP and earns you no EXP, as in Gen 3.

### Abilities

Each species has one ability. The battle calls these hooks on both monsters:

| Hook | When | Example |
|---|---|---|
| `on_enter` | Sent into battle | DREAD lowers the foe's ATTACK |
| `damage_multiplier` | Holder deals damage | KINDLE: 1.5× fire moves at ≤ 1/3 HP |
| `modify_damage_taken` | Holder is about to take damage | SOAK UP heals from water; STURDY SHELL survives at 1 HP |
| `on_hit` | Holder took damage and is still up | JOLT may lower the attacker's SPEED |
| `on_turn_end` | End of every turn | SUNSOAK restores 1/16 HP |

Abilities act through `battle.message()`, `battle.heal()` and
`battle.change_stat()`, so their effects appear on screen automatically. To
add one, reuse a script in `scripts/monsters/abilities/` with new numbers, or
subclass `Ability` and override a hook. Then save it as a `.tres` and assign
it to a species.

### Encounter flow

Tall grass emits `Events.wild_encounter(species_id)`. Main plays the battle
music and flash, rolls a level from `WorldMap.wild_levels`, builds the wild
`Monster`, fades to the BattleScene, and awaits `run()`. A win awards EXP
(level-ups may teach moves, with a forget-a-move prompt once four are known).
A loss heals the party and respawns the player at `GameState.respawn_map`.

### Adding a monster or move

1. Add a row to `tools/build_game_data.gd` and run it, or duplicate a
   `.tres` in `data/` and edit it in the inspector.
2. Give it art: add a seed to `PixelArt.MONSTERS` and rerun the art tool,
   or point `front_texture`/`back_texture` at real sprites.
3. Add its id to a map's `wild_monsters`.

## Communication

- **Events (signal bus):** `warp_requested(map_path, spawn_id)` is the only way
  maps change, used by warps and Fly. `wild_encounter(species_id)` is handled
  by Main, which runs the battle. `map_entered(map)` is there for quests and
  achievements.
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

- `tests/battle_test.gd` covers the battle rules with no scene: stat and
  damage formulas, type chart, stages, turn order and priority, all six
  abilities, winning, losing, forced switches, running, PP, STRUGGLE,
  level-ups, catch odds, orbs, POTIONs, and the party/BOX/BAG helpers
  (51 checks).
- `tests/smoke_test.gd` plays the real game by injecting input: turning,
  walking, bumping, signs, NPCs, CUT, doors, map edges, ledges, ROCK SMASH,
  a won battle, a catch through the BAG menu, a lost battle with whiteout,
  SURF and FLY (29 checks).

```sh
godot --headless --path . --script res://tests/battle_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/smoke_test.gd
```
