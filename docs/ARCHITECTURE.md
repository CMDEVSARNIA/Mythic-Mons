# Architecture

How the Mythic Mons foundation is put together: where files live, how the
scenes are built, and how the systems talk to each other.

Target engine: **Godot 4.7** (GDScript, GL Compatibility renderer).

## Directory structure

```
Mythic-Mons/
├── project.godot              Display, input map, autoloads, physics layer names
├── export_presets.cfg         Release presets: Windows, Linux, macOS, Web (tools/export.sh)
├── icon.png                   Generated (a monster at 4x)
├── autoload/                  Global singletons (Project Settings > Globals)
│   ├── events.gd              Events: signal bus (warp_requested, wild_encounter, map_entered)
│   ├── game_state.gd          GameState: party, BOX, BAG, flags, badges, play time, Fly towns,
│   │                          respawn, save/load
│   ├── audio.gd               Audio: music + SFX, real files first, chiptune fallback
│   └── settings.gd            Settings: the OPTION screen's choices, saved to user://settings.cfg
├── scenes/
│   ├── main/                  Main scene: current map, player, title, start menu, battles, fades
│   ├── actors/
│   │   ├── grid_actor.gd      Shared tile-locked movement (player and NPCs)
│   │   ├── player/            Player scene + input, interaction, surfing, ledges
│   │   └── npc/               Wandering NPC (can heal), StarterGiver + professor.tscn,
│   │                          ShopClerk + clerk.tscn, Trainer + trainer.tscn,
│   │                          NameRater + name_rater.tscn, GiftGiver + gift_giver.tscn
│   ├── maps/
│   │   ├── world_map.gd       Root script of every map (terrain lookups, spawns, encounters)
│   │   └── *.tscn             Emberfall (home, lab, REN's house), Route 1, Tidewater
│   │                          (MART, MONSTER CENTER, GYM, seaside house), Route 2,
│   │                          Copperdale (MONSTER CENTER, MART, GYM, house)
│   ├── objects/               Warp, SpawnPoint, Signpost, CUT tree, ROCK SMASH boulder,
│   │                          StoragePC (the MONSTER CENTER's PC), ItemBall
│   ├── battle/                BattleScene (menus + animation), MoveAnimator (move and
│   │                          orb effects), BattlerPanel, StatBar, EvolutionScene
│   └── ui/                    Dialogue box and NameEntry (autoloads), choice box, map banner, party menu,
│                              monster summary, shop menu, quantity box, MONDEX,
│                              StorageMenu (the PC's BOX screens), TrainerCard, OptionsMenu,
│                              MoveTutor (learning a move, forgetting one if needed)
├── scripts/                   Non-scene code (class_name utilities)
│   ├── core/                  Grid, PhysicsLayers, Terrain, GameData (id → resource lookups)
│   ├── monsters/              MonsterSpecies, MoveData, LevelMove, Evolution, Monster,
│   │                          TypeChart, Ability + abilities/ (one script per behavior)
│   ├── items/                 ItemData (orbs, potions, evolution stones)
│   ├── battle/                Battle (the rules), Battler (a monster on the field),
│   │                          TrainerData + TrainerMonster (who you battle)
│   ├── art/                   pixel_art.gd (palettes; draws characters, monsters, items,
│   │                          effects), hand-drawn designs: character_designs.gd,
│   │                          monster_designs.gd, item_designs.gd (icons and orbs),
│   │                          effect_designs.gd (battle effects), trainer_designs.gd
│   │                          (trainer battle sprites and the player's back sprite), and
│   │                          world_tiles.gd (WorldTiles: the map atlas layout)
│   └── audio/                 ChipSynth (SFX), Chiptune (sequencer), Songs (music data)
├── data/                      Game data as .tres, file name = id
│   ├── species/               flamlet, blazard, aquapup, tidehound, ... (14, in dex order)
│   ├── moves/                 tackle, ember, water_gun, ...
│   ├── abilities/             kindle, soak_up, sunsoak, sturdy_shell, jolt, dread, gale_force
│   ├── items/                 ten orbs (mon_orb ... gala_orb), potion, big_potion, stones
│   └── trainers/              lass_mia, youngster_tim, rival_ren, swimmer_luca,
│                              swimmer_nia, leader_marina, hiker_dale, youngster_joey,
│                              swimmer_rio, rival_ren_2, engineer_roy, engineer_ida,
│                              leader_cora
├── assets/
│   ├── placeholder/           Generated PNGs: characters, objects, monsters, items,
│   │                          effects, trainers (battle sprites)
│   ├── characters/townsfolk/  NPC sheets converted from a downloaded pack (source/)
│   ├── world/                 world_tiles.png, signs, CUT tree, boulder, battle backdrop,
│   │                          source/ (ArMM1998's CC0 overworld sheet)
│   ├── tilesets/              overworld_tileset.tres (physics, terrain + examine data)
│   ├── ui/theme.tres          Pixel font, text-box style
│   ├── fonts/                 Press Start 2P (SIL OFL)
│   └── audio/music, sfx/      Drop real audio here to replace the generated sounds
├── tools/                     Headless generators (art, TileSet, starter maps, game data)
│                              and the town-tile and townsfolk importers
├── tests/                     battle_test, monster_test, game_state_test (rules),
│                              smoke_test (plays the game), npc_test (every NPC and sign)
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
│   ├── StartMenuArea (MarginContainer)
│   │   └── StartMenu (choice_box.tscn)  MONDEX / MONSTERS / BAG / CARD / FLY / SAVE / OPTION /
│   │                                    DEBUG (debug builds) / EXIT
│   ├── HintBox (PanelContainer)         item descriptions while browsing the BAG
│   ├── PartyMenu (party_menu.tscn)      party list + MonsterSummary
│   ├── DexMenu (dex_menu.tscn)          the MONDEX
│   ├── TrainerCard (trainer_card.tscn)  name, money, MONDEX, play time, badges
│   ├── TitleScreen (Control)            CONTINUE / NEW GAME / OPTION when a save exists
│   └── OptionsMenu (options_menu.tscn)  the OPTION screen (drawn over the title screen)
├── BattleLayer (CanvasLayer, layer 8)   a BattleScene (or EvolutionScene) is added here
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
├── Buildings (TileMapLayer)             5 × 5 houses from WorldTiles (towns only)
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
`ledge_left`, `ledge_right` and `counter` (the player talks across it). Normal
ground leaves it empty. Add a tag there,
assign it in the TileSet editor (or `TILE_RULES` in `tools/build_world.gd`),
and react to it in `Player._try_step()` / `_on_step_finished()`.

A second layer, `examine` (String), holds what pressing A on a tile says
(`EXAMINE` in `tools/build_world.gd`: bookshelves, beds, plants, crates, MART
shelves). `Player._interact()` shows it when nothing else answers.

NPCs wander within `wander_radius` of home, but pause while the player stands
next to them, so they don't walk off just as you press A.

## Field moves

| Move | How it works |
|---|---|
| CUT / ROCK SMASH | `FieldObstacle` (StaticBody2D on `obstacles`). Pressing A asks to use the move, then plays an effect and frees the node. It returns when the map reloads, like Emerald. |
| SURF | Press A facing water. The player gets the surf mount, loses the `water` collision bit and hops in. Moving onto land hops back out. |
| FLY | Start menu (Enter) → FLY lists `GameState.visited_towns`. A map with `is_town = true` registers itself when entered. A map with `allow_fly = false` (interiors) refuses. Lands on the target town's `fly` spawn. |

`GameState.can_use_field_move()` decides availability through badges, as in
Emerald: `GameState.BADGES` maps each badge id to its name and the field moves
it unlocks, and a badge is owned when its flag is set. CUT and ROCK SMASH are
in no badge's list, so they work from the start; SURF needs the TIDE BADGE
and FLY the SPARK BADGE. Without them, SURF only shows "The water is dyed a
deep blue..." and FLY names the missing badge (`badge_for()`). The river on
Route 2 makes SURF the way on to Copperdale.

## Items on the map

An `ItemBall` (`scenes/objects/item_ball.tscn`, a StaticBody2D on
`obstacles`) holds `count` of an `item`. Pressing A adds it to the BAG, sets
its `flag` and frees it; a ball whose flag is already set frees itself when
the map loads, so it never comes back. A `GiftGiver` NPC works the same way
for an item handed over in conversation. `tools/build_world.gd` names both
flags after the map and cell (`item_route_02_1_10`), so place them with
`["item_ball", {"item": &"potion"}]` in a map's `obstacles` or
`{"scene": "gift", "gift": ..., "count": ..., "offer": [...]}` on an NPC.

## Monsters & battles

### Data

| Resource | Holds |
|---|---|
| `MonsterSpecies` (`data/species/*.tres`) | Name, element, ability, front/back sprites, 5 base stats, catch rate, EXP yield, EXP curve (`growth`), learnset (`LevelMove` entries), `evolutions`, MONDEX number and entry |
| `Evolution` (inside a species) | What it evolves `into`, and how: `LEVEL` (at `level` or above) or `ITEM` (an evolution stone's id) |
| `MoveData` (`data/moves/*.tres`) | Name, element, PHYSICAL/SPECIAL/STATUS, power, accuracy, PP, priority, optional stat changes, an optional `status_effect` (with `status_chance` for damaging moves), the `animation` recipe |
| `ItemData` (`data/items/*.tres`) | Name, kind (BALL/HEAL/EVOLUTION/CURE), price, description, a 16 × 16 `icon`; orbs add a catch multiplier, a special-orb `bonus`, and an `open_icon`; cures list the statuses they fix (`cures`, empty = all) |
| `Ability` subclasses (`data/abilities/*.tres`) | A configured behavior, e.g. `ElementBoostAbility` with element = fire is KINDLE |
| `Monster` (runtime, a Resource so it can be saved) | Species, level, EXP, current HP, IVs, nature, the orb it was caught in, its status condition (and sleep turns left), moves and remaining PP |

Stats follow Generation 3 with two simplifications: five stats (HP, ATTACK,
DEFENSE, SPECIAL, SPEED, where one SPECIAL serves for both attack and defense
as in the 8-bit games) and no EVs.

- **IVs** are 0-31 per stat, rolled when a monster is created.
- **Natures** (`Monster.NATURES`, 16 of them) raise one non-HP stat by 10%
  and lower another. The five where both are the same stat are neutral.
- **Formulas:** HP = (2·base + IV)·L/100 + L + 10, and every other stat is
  ((2·base + IV)·L/100 + 5) × nature, with integer math as in Gen 3.
- **EXP curves** (`MonsterSpecies.Growth`) are Gen 3's: FAST (4n³/5),
  MEDIUM_FAST (n³), MEDIUM_SLOW (6n³/5 − 15n² + 100n − 140) and SLOW
  (5n³/4). `species.exp_for_level(n)` is the total EXP at level n.

Maps and code refer to species, moves and items by id
(`GameData.species(&"zapkit")`), and the id is the file name.

### Rules vs. presentation

`Battle` (scripts/battle/battle.gd) holds every rule and nothing visual. Each
call (`start()`, `take_turn(action)`, `switch_after_faint(i)`) returns an
ordered list of events: `message`, `attack` (with the move), `hit`, `hp`,
`stat`, `faint`, `withdraw`, `send_out`, `flee`, `restore`, `throw`, `shake`,
`caught`, `break_free`. `BattleScene` only asks for the player's action and
plays those events back as text, sounds and animation. This keeps the rules
fast to unit-test and reusable for trainer battles.

### Battle animation

`BattleScene` animates the events with tweens:

- **Opening.** The wild monster slides in from the left as the trainer's
  back sprite (`characters/player_back.png`: stand, wind up, throw) slides in
  from the right. While "Go! X!" is on screen, the trainer throws the lead
  monster's orb and steps away.
- **Send-outs and recalls.** Each `Monster` remembers its `orb`. A send-out
  arcs that orb in, pops it open (its `open_icon`) in a flash, and the
  monster grows out of a white glow. A recall shrinks it into red light.
- **Catches.** A `throw` arcs the orb to the wild monster, opens it, pulls
  the monster in as red light, then drops and bounces the orb onto the
  platform. Each `shake` tips the orb on its base. `caught` dims it with a
  burst of stars, and `break_free` pops it open and lets the monster out.
- **Faints.** The monster sinks out of sight: its sprite's region shrinks as
  it moves down, so it looks cut off by the platform.

`MoveAnimator` (the `Effects` node, above the monsters and below the HP
panels) plays each move's animation for an `attack` event:
`play_move(move, user_sprite, target_sprite)`. `MoveData.animation` names a
recipe in `MoveAnimator.RECIPES`. A move without a recipe falls back to one
for its category and element (for example, a special fire move uses EMBER's).
Recipes combine a few building blocks: effect sprites from `EffectDesigns`
(drawn at 2×, like the monsters) that fly, pop, or burst outward; a lunge
toward the target; Line2D vines and lightning; a tint over the backdrop
(`BackdropTint`); and a full-screen `Flash`. MoveAnimator also draws orb
light, catch stars, stat arrows and healing sparkles for BattleScene. To add
a recipe, write a method in MoveAnimator, add it to `RECIPES`, and set the
move's `animation`.

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
  `rate = (3·maxHP − 2·HP) · catch_rate · ball / (3·maxHP)`, where `ball` is
  `Battle.ball_multiplier(orb)`. That's the orb's `catch_multiplier`, unless
  its `bonus` applies:

  | `ItemData.Bonus` | Orb | Multiplier |
  |---|---|---|
  | `ELEMENT` | NET ORB | `bonus_multiplier` (3×) if the wild monster's element is in `bonus_elements` (WATER) |
  | `IN_WATER` | DIVE ORB | 3.5× when `Battle.in_water` (Main sets it when you meet the monster while surfing) |
  | `LOW_LEVEL` | NEST ORB | (40 − level) / 10, at least 1× |
  | `REPEAT` | REPEAT ORB | 3× when `Battle.already_caught` (its species is in the MONDEX as caught) |
  | `TIMER` | TIMER ORB | (turns + 10) / 10, at most 4×; `Battle.turns` counts finished turns |

  At 255 or more the catch is certain. Otherwise four checks each pass with
  probability `1048560 / ⁴√(16711680 / rate) / 65536`. The orb wobbles once
  per passed check, up to three times, and all four passing is a catch. A
  SPROUTLE (catch rate 190) is about a 25% catch at full HP and 74% at 1 HP.
- **Healing items** (`Kind.HEAL`) restore HP to the active monster.

On a catch the battle ends with `Outcome.CAUGHT`, the monster's `orb` is set
to the orb's id, and `GameState.add_monster()` puts the monster in the
party, or in
`GameState.storage` (the BOX) when the party has six. A caught monster keeps
its current HP and earns you no EXP, as in Gen 3.

### Status conditions

`Monster.status` is one of `Monster.STATUSES` (poison, burn, paralysis,
sleep, freeze) or empty. It's saved with the monster and lasts outside
battle until cured. `heal_full()` (MOM, the MONSTER CENTER) and fainting
clear it. In `Battle`:

- `inflict(battler, status)` checks that the monster has no status yet and
  isn't immune (`STATUS_IMMUNITIES`: fire can't burn). It then sets the
  status (sleep rolls 2–5 turns) and emits a `status` event. A STATUS move with a
  `status_effect` always tries when it hits. A damaging move tries with
  `status_chance`.
- `_can_act()` runs before each move: sleep counts down, freeze thaws 1 in 5
  (fire hits thaw it too), paralysis stops 1 turn in 4. A lost turn emits an
  `afflicted` event and uses no PP.
- At the end of each turn, poison and burn cost 1/8 of max HP. A burn
  halves physical damage in `calculate_damage()`, and paralysis quarters
  SPEED in `Battler.stat()`. `catch_shakes()` adds Gen 3's status bonus (2×
  for sleep or freeze, 1.5× for the rest).
- `ItemData.Kind.CURE` items call `cure()` in battle. Main uses them from the
  BAG too.
- Items used on a monster (`ItemData.targets_monster()`: HEAL, CURE, REVIVE,
  PP) share `can_use_on()` and `use_on()`, which apply the effect and
  return the text to show, in battle and on the map. In battle,
  `Battle.use_item(item, target, move)` takes a party index (any member,
  not only the active one; -1 means the active one) and, for an ETHER, the
  move. REVIVE sets HP to `revive_fraction` of max (MAX REVIVE 1.0), and
  ETHER adds `pp_amount`. A REPEL (`Kind.REPEL`, field only) sets
  `GameState.repel_steps`; Main counts it down each step, skips wild
  encounters whose level is below `GameState.lead_monster()`'s, and says
  when it wears off.

BattleScene shows a `status` event as the tag in the HP box
(`BattlerPanel.show_status()`). It plays `MoveAnimator.status_effect()`
(bubbles, flames, sparks, Zs, frost) for both `status` and `afflicted`. On
the map, Main counts the player's steps: every 4, poisoned party members
lose 1 HP, and the poison fades at 1 HP.

Trainer AI: `Battle._enemy_move()` stays random for wild monsters. For
trainers it scores each move with `move_score()`: power × effectiveness ×
STAB × accuracy for attacks (a little less with recoil, more for draining
when hurt), a flat score for status and stat moves, a healing score that
grows as HP drops, and 0 when a move would fail (confusing a confused foe,
healing at full HP). It then takes the best 75% of the time and a random
useful move otherwise.

### Volatile conditions and extra move effects

Confusion and flinching live on the `Battler` (`confused_turns`,
`flinched`), so they end when a monster leaves the field, as in Gen 3.
`MoveData` has an "Extra Effects" group:

| Field | Effect | Moves |
|---|---|---|
| `confuse_chance` | `confuse()`: 2–5 turns; `_confusion_check()` counts down each turn and, half the time, the monster hits itself with a 40-power typeless attack instead of moving (no PP used) | DIZZY RAY, SUPERSONIC |
| `flinch_chance` | Sets `flinched` on the target; `_can_act()` stops it if it hasn't moved yet, and `_end_of_turn()` clears it | HEADBUTT, ROCK SLIDE |
| `drain` | The user heals that % of the damage dealt | ABSORB, GIGA DRAIN |
| `recoil` | The user loses that % of the damage dealt, and can faint from it | TAKE DOWN |
| `heal` | A STATUS move (with `stat_target` SELF, so it never misses) restores that % of max HP | SYNTHESIS, ROOST |

`_can_act()` checks sleep and freeze, then flinching, then confusion, then
paralysis. Confusion plays as an `afflicted` event with status
`&"confusion"`: stars circling the head. In `tools/build_game_data.gd`, a
move row takes these as a trailing `{property: value}` dictionary.

**Switching between a trainer's monsters.** When the foe's monster faints and
the trainer has another, BattleScene's `_offer_shift()` asks "Will KAI change
MONSTERS?" (Settings `shift_style`, Emerald's SHIFT), if `Battle.can_shift()`.
`Battle.shift_to()` swaps the player's monster without giving the foe a turn,
and `next_foe()` names the monster about to come out.

### Trainers

A `TrainerData` (`data/trainers/*.tres`, built from `TRAINERS` in
`tools/build_game_data.gd`) holds a trainer's class and name, 32 × 32 battle
sprite, team (`TrainerMonster`: species + level), `payout`, and three sets
of lines: `intro` (on the map), `defeat` (in battle) and `after` (on the map
once beaten). `build_party()` makes fresh monsters with a fixed seed, so a
rematch after a loss is the same fight. With `counters_starter` (the rival),
the first monster becomes the starter that beats the player's, which
StarterGiver records as a `starter_<id>` flag, evolved if its level is past
the evolution level (REN's second team leads with TIDEHOUND, GROVETLE or
BLAZARD).

On the map, a `Trainer` (an NPC subclass, `trainer.tscn`) points at its data
and watches `sight` tiles straight ahead. After every step, the player asks
each node in the `trainers` group `can_see()`: unbeaten, in a straight line,
nothing in between. A trainer that `swims` drops the water bit from its
collision mask, so SWIMMERs in a river swim over to you. Trainers are
checked before the wild-encounter roll. A
hit emits `Events.trainer_spotted`, and Main plays the `spotted` music. The
trainer's `notice()` shows the "!" bubble and walks up, then `interact()`
says the intro and emits `Events.trainer_battle(data)`. Talking to an
unbeaten trainer emits the same signal. Main then plays `trainer_battle`,
runs `BattleScene.run_trainer()`, and on a win sets `data.defeat_flag()`
(`beat_<id>`), after which the trainer only says its `after` lines.

A trainer's `music` picks the battle theme (`trainer_battle` by default,
`gym_battle` for a GYM LEADER). A trainer with a `badge` hands it over after
the first win: Main sets the badge's flag, plays the `badge` fanfare, says
"KAI received the TIDE BADGE from MARINA!" and then the trainer's
`badge_lines`. The TIDEWATER GYM (`gym_tidewater.tscn`) is a pool crossed by
one walkway; each SWIMMER watches a crossing with `sight` 5, so the player
can't sneak past, and LEADER MARINA has `sight` 1 at the far end. The
COPPERDALE GYM has the same plan with stacks of generators (crates) for the
pool, ENGINEERs for the SWIMMERs and LEADER CORA, who gives the SPARK BADGE.

In battle, `Battle.against_trainer()` adds the rules: the enemy is "Foe X";
`foe_must_switch()` / `send_next_foe()` bring out the next monster (award EXP
first); RUN is refused without costing the turn; orbs raise `throw_blocked`;
EXP is 1.5×; `prize_money()` is payout × the last monster's level. The scene
slides both trainers in, shows each team as a row of orbs, and has the foe
step away and throw. On a win, the foe walks back in, says its `defeat`
lines and pays out. On a loss, the player pays half their money before
whiting out.

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

Each step into tall grass rolls `WorldMap.encounter_rate` against
`wild_monsters`, and each step while surfing rolls `water_encounter_rate`
against `water_monsters`. A hit emits `Events.wild_encounter(species_id)`.
Main marks the species as seen, plays the battle music and flash, rolls a
level from `WorldMap.wild_levels`, builds the wild `Monster`, fades to the
BattleScene, and awaits `run()`. A win awards EXP. Level-ups may teach moves
through `MoveTutor.teach()`, which asks which move to forget once four are
known. A loss heals the party and respawns the player at
`GameState.respawn_map`.

### Evolution

BattleScene lists the monsters that leveled up in `leveled_up`. Once the
battle is over, Main checks each one with `monster.evolution_by_level()` and
plays `EvolutionScene.run(monster, into, can_cancel)` for each match, on
`BattleLayer`. The scene flashes white silhouettes of the old and new forms,
faster and faster. Holding B (`cancel`) stops a level evolution, and it's
offered again at the next level-up, as in Emerald.

Evolution stones (`ItemData.Kind.EVOLUTION`) are used from the start menu's
BAG: Main asks for a party member, checks `monster.evolution_by_item(id)`,
and on a match uses up the stone and plays the same scene with
`can_cancel = false`. A stone that doesn't apply says "It won't have any
effect." and is kept. BattleScene's BAG doesn't list stones.

`Monster.evolve(into)` swaps the species and keeps everything else: level,
EXP, IVs, nature, moves, PP and nickname. Current HP rises by however much max
HP did, so damage taken carries over. It returns the new species' moves for
the current level, which the scene teaches with `MoveTutor`. The scene also
marks the new species as caught in the MONDEX.

### Adding a monster or move

1. Add a row to `tools/build_game_data.gd` and run it, or duplicate a
   `.tres` in `data/` and edit it in the inspector.
2. Give it art: draw it in `MonsterDesigns` and add its colors to
   `PixelArt.MONSTERS` (or add a seed to `PixelArt.GENERATED_MONSTERS` for a
   quick stand-in), then rerun the art tool. Or point
   `front_texture`/`back_texture` at real 32 × 32 or 64 × 64 sprites.
3. Add its id to a map's `wild_monsters`.
4. To make it evolve, add a row to `EVOLUTIONS` in `tools/build_game_data.gd`
   (the tool checks that both forms use the same EXP curve), or add an
   `Evolution` to the species' `evolutions` in the inspector. A new stone is
   an `ItemData` with `kind = EVOLUTION`; add its id to a clerk's `stock`.

## Story, party & saving

- **Story flags.** `GameState.flags` holds progress switches (`has_flag()`,
  `set_flag()`). A Warp with `required_flag` set turns the player back with
  `blocked_lines` until the flag is on. That's how Emberfall's north exit
  waits for `got_starter`. Use the same pattern for gyms, roadblocks, and
  so on.
- **New game.** With no save (or NEW GAME on the title screen), Main plays
  `_intro()` over the title backdrop: PROF. ASTER's welcome, then the naming
  screen for `GameState.player_name` (up to 7 letters; empty means
  `DEFAULT_NAME`). It sets `GameState.INTRO_FLAG`, so tests that start a
  game directly set that flag to skip it.
- **Naming.** `NameEntry` (autoload, `scenes/ui/name_entry.tscn`, CanvasLayer
  12) is Emerald's naming screen: letters, digits and `. , - '` above SPACE /
  BACK / OK. `await NameEntry.ask(prompt, max_length, picture, start_text)`
  returns the trimmed text, or "" if empty. `offer_nickname(monster)` asks
  "Give a nickname to X?" first; `rename(monster)` goes straight to the
  screen, and an empty name (or the species name) clears the nickname
  (`Monster.MAX_NICKNAME_LENGTH` is 10). BattleScene offers a nickname after
  a catch, StarterGiver after the starter, and `NameRater` (an NPC subclass,
  `name_rater.tscn`, in Tidewater's seaside house) renames party members.
- **Starter.** `StarterGiver` (an NPC subclass, `professor.tscn`, in the lab) offers
  each species in `starters` through `Dialogue.choose()` with a picture of
  the highlighted one. It then gives the monster plus a gift item and sets
  the flag. New games start with an empty party.
- **Healing.** Any NPC with `heals_party` restores the party after talking
  (MOM, and the nurse in the MONSTER CENTER, across the counter) and makes
  that map the respawn point (`GameState.respawn_map`, its `entrance`
  spawn). Whiting out heals the party and wakes the player there: with MOM
  at home (`GameState.HOME_MAP`, where a new game starts) or in front of the
  last nurse.
- **Start menu.** MONSTERS opens `PartyMenu.browse()`: a list with HP bars, a
  big picture of the highlighted monster, and SUMMARY (two pages: info and
  ability, then stats and moves) or SWITCH to reorder; the first healthy one
  leads in battle. BAG uses `PartyMenu.pick()` to choose who gets a POTION.
- **The PC and the BOX.** `GameState.storage` is the BOX. `withdraw()`,
  `deposit()` and `release()` move monsters in and out. `deposit()` refuses
  to leave the party without a monster that can battle (`can_deposit()`). A
  `StoragePC` (`scenes/objects/storage_pc.tscn`, placed as a `"pc"` obstacle
  in `tools/build_world.gd`) opens a `StorageMenu`. It offers WITHDRAW,
  DEPOSIT, RELEASE (after a YES/NO) and SEE YA!. Each option lists monsters
  with a picture, level, element, HP and status of the highlighted one.
- **Shops.** A `ShopClerk` (an NPC subclass, `clerk.tscn`) stands behind a
  counter tile; `Player._interact()` looks past counters, so the player talks
  across them. Talking adds a `ShopMenu` and awaits `run(stock)`: BUY / SELL
  / QUIT, an item list with the highlighted item's description, a
  `QuantityBox` (up/down ±1, left/right ±10) and a YES/NO confirmation.
  Prices are `ItemData.price` (0 = not for sale), and the MART buys items
  back for `sell_price()`, half of that. Buying 10 MON ORBs at once adds a
  free GALA ORB (`ShopMenu.BONUS_*`), like Emerald's Premier Ball.
  `GameState.money` starts at $3000 and is capped at $999,999. The BAG holds
  up to 99 of each item. Each clerk sells its own `stock`. The Tidewater MART
  has two counters (everyday goods, and specialty orbs and stones), set by a
  `"stock"` list of item ids in `tools/build_world.gd`, or in the inspector.
- **Menus.** `ChoiceBox` is every option list. With `max_rows` set (the
  start menu, BAG and shop lists show 8, battle lists 7), longer lists
  scroll to follow the cursor, with ▲ and ▼ marking more options. Item lists
  show the highlighted item's `icon` next to its description.
- **MONDEX.** `GameState.seen` and `GameState.caught` hold species ids.
  Wild encounters mark a species as seen, and `GameState.add_monster()`
  (starter or catch) marks it as caught. A new catch also gets "data was
  added to the MONDEX" in battle. `DexMenu` (the start menu's first entry
  once you have a starter) lists `GameData.all_species()` by
  `MonsterSpecies.dex_number`. A caught species' page shows its `category`,
  `element`, `height`, `weight` and `dex_entry`.
- **OPTION.** `Settings` (autoload) holds TEXT SPEED (Dialogue's characters
  per second, and how long battle text stays up), BATTLE SCENE (BattleScene
  skips move, stat and status animations when off), BATTLE STYLE (SHIFT
  or SET) and MUSIC and SOUND volume (0–10, applied to the Music and SFX
  buses). `OptionsMenu`, from the start menu or the title screen, edits
  them and `save_settings()` writes `user://settings.cfg`, separate from
  the save so it applies to every game. Tests call `Settings.reset()` and
  point `save_path` at their own file.
- **DEBUG.** In debug builds (`OS.is_debug_build()`: the editor, debug
  exports), the start menu adds DEBUG (`Main._debug_menu()`): WARP to any
  map in `scenes/maps/`, heal, 99 of every item, money, every badge, five
  level-ups for the lead (moves through MoveTutor, then evolution), any
  species at level 5 to 50, a full MONDEX, and `Main.wild_encounters` on
  or off. Release exports don't show it.
- **TRAINER CARD.** CARD in the start menu opens `TrainerCard`: the
  player's name, money, MONDEX (caught) count, play time as H:MM, and the
  badge case, with badges not yet won shown dark. `GameState.play_seconds`
  counts up in `Main._process()` once a game is running (not on the title
  screen) and is saved.
- **Saving.** SAVE writes `user://save.json`: the player's map, cell,
  facing and surf state, plus the party, BOX, BAG, money, MONDEX, flags
  (badges included), play time, Fly towns and respawn. Saves from before the MONDEX count everything you
  own as caught, monsters without a nature get HARDY (neutral) and a MON
  ORB, and EXP is clamped to each species' curve. Monsters store species,
  move and orb *ids*, not resource paths. A
  save survives refactors as long as ids stay the same, and unknown species
  or moves are skipped rather than crashing. It's JSON because loading a
  `.tres` can run scripts embedded in it, and players edit and share save
  files. When a save exists, the game opens on a title screen with
  CONTINUE / NEW GAME. A save with a different `version` is ignored, so
  bump `SAVE_VERSION` and convert old data when the format changes.

## Communication

- **Events (signal bus):** `warp_requested(map_path, spawn_id)` is the only way
  maps change, used by warps and Fly. `wild_encounter(species_id)` is handled
  by Main, which runs the battle; so are `trainer_spotted(trainer)` and
  `trainer_battle(data)` (see Trainers). `map_entered(map)` is there for
  quests and achievements.
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
2. Paint `Ground` with `overworld_tileset.tres` (one atlas, `WorldTiles`).
   For buildings, add a `Buildings` layer with houses from the same atlas (in
   `MAPS`: `houses`, as `[top-left cell, roof]`), and put a warp on each
   door, 2 tiles right of and 4 below the house's top-left corner.
3. Add `SpawnPoint` markers under `Spawns`, named by id.
4. Add `warp.tscn` instances under `Warps`. Set `target_map` and `target_spawn`.
5. Set `display_name`, `music`, `is_town`, and the encounter table in the inspector.

## Tests

- `tests/battle_test.gd` covers the battle rules with no scene: stat and
  damage formulas, type chart, stages, turn order and priority, all six
  abilities, winning, losing, forced switches, running, PP, STRUGGLE,
  level-ups, catch odds, every special orb's bonus, trainer battles (teams,
  the rival's counter-pick, no running, blocked orbs, sending out the next
  monster, 1.5× EXP and prize money), every status condition and cure, the
  trainer AI, orbs and POTIONs, and the rival's evolved counter-pick (98
  checks).
- `tests/monster_test.gd` covers the four EXP curves, IV ranges, every
  nature turning up, nature effects on stats, level and stone evolution
  (what's kept and what changes), and that evolutions share their
  pre-evolution's curve (20 checks).
- `tests/game_state_test.gd` covers the party, BOX (withdraw, deposit,
  release and their limits), BAG limits, money, the
  MONDEX (all 14 species), badges and the field moves they unlock, the card's time format, flags, monster serialization (natures, orbs and statuses included,
  and older saves without them), a full save/load round trip, and corrupt or
  newer-version saves (55 checks). It uses its own save file.
- `tests/smoke_test.gd` plays the real game by injecting input: typing the
  player's name in the intro, movement, signs, NPCs, CUT, doors, the starter
  gate and PROF. ASTER's starter (declining a nickname),
  ledges, ROCK SMASH, a won battle whose level-up evolution is stopped with
  B, a catch (which remembers its orb and gets a nickname), a whiteout, MOM's healing (statuses
  too), poison on the map, an ANTIDOTE from the BAG, three
  trainers (spotted and walked up to, talked to from behind with RUN
  refused, and the rival's counter-pick), prize money and a beaten trainer
  who just chats, the
  MONDEX list and page, party screen, summary and SWITCH, a scrolling BAG
  and POTIONs from it, SAVE, CONTINUE from the title screen,
  SURF and FLY refused without the TIDE BADGE, the TRAINER CARD, the GYM
  (both SWIMMERs, then MARINA with her own music, the $1400 prize, the badge
  and the card showing it), SURF and a
  battle at sea (SPROUTLE evolves into GROVETLE afterwards), buying 10 MON
  ORBs (and the free GALA ORB), selling, a DIVE ORB from the specialty
  counter, a BOLT STONE from the BAG (on the wrong monster, then on ZAPKIT),
  healing at the MONSTER CENTER, depositing a monster at the PC and
  withdrawing it again, the NAME RATER clearing a nickname, entering and
  leaving every building, then Route 2 (an item ball behind a CUT tree,
  SURF across the river where a SWIMMER swims over, REN's evolved
  counter-pick), Copperdale (a one-time gift, the second GYM, the $2100
  prize and the SPARK BADGE), and FLY (145 checks).
  It uses its own save file.
- `tests/npc_test.gd` visits every map and talks to every NPC and sign,
  standing where a player could (a reachable neighboring cell, counting CUT,
  ROCK SMASH and SURF, or across a counter), then examines a bookshelf.
  Trainers count as beaten, so they chat (63 checks).

```sh
godot --headless --path . --script res://tests/battle_test.gd
godot --headless --path . --script res://tests/monster_test.gd
godot --headless --path . --script res://tests/game_state_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/smoke_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/npc_test.gd
```
