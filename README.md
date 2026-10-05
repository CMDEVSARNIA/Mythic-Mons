# Mythic Mons

An 8-bit, top-down monster-collecting RPG in the spirit of Pokémon Emerald,
built with **Godot 4.7** and GDScript.

![The cast: player, professor, mom, rival, lass, elder, hiker, swimmer and nurse](docs/images/characters.png)

So far: tile-locked movement, a multi-town world, dialogue, field moves,
a starter from the local professor, turn-based wild battles with unique
abilities, EXP and level-ups, catching, a party screen, and saving.
Nearly everything is made in code: the art, the chiptune music and the sound
effects. The exception is five townsfolk converted from a downloaded sprite
sheet. Real assets slot in later without code changes.

## Quick start

1. Install [Godot 4.7](https://godotengine.org/download) (standard build, no .NET needed).
2. Open `project.godot` in Godot and press **F5**.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | Arrows / WASD | D-pad / left stick |
| Run (hold) | Shift or X | B |
| Talk / confirm (A) | Z or Space | A |
| Cancel (B) | X or Backspace | B |
| Start menu | Enter or Esc | Start |

## What's in the prototype

- **Emberfall Town.** PROF. ASTER outside the lab lets you choose FLAMLET,
  AQUAPUP or SPROUTLE (and won't let you into the tall grass without one).
  Your house has MOM, who heals your team. There's also a sign, NPCs, and a
  secret garden behind a **CUT** tree.
- **Route 1.** Tall grass with wild encounters, one-way **ledges**, and a
  hiker trapped behind a **ROCK SMASH** boulder.
- **Tidewater City.** A beach and an island you reach with **SURF**.
- **FLY** from the start menu (Enter) to any town you've visited.
- Emerald-style feel: tap to turn in place, hold to walk, bump into walls,
  run at double speed, location banner on entering a map, typewriter text box.
- **Wild battles** in tall grass, Emerald style: FIGHT / BAG / MON / RUN,
  type matchups, critical hits, stat changes, PP, EXP and level-ups that teach
  new moves. Losing sends you home with your party healed.
- **Catching.** Open the BAG in battle and throw an orb. Weaken a monster
  first: the lower its HP, the better the odds (Emerald's formula). The orb
  shakes up to three times, and caught monsters join your party, or the BOX
  once you have six. POTIONs heal 20 HP. You start with 2 POTIONs, and the
  professor adds 5 MON ORBs.
- **Start menu (Enter):** MONSTERS (party list, a two-page summary, and
  SWITCH to change your lead), BAG (use POTIONs on any party member), FLY and
  SAVE. With a save, the game opens on a title screen with CONTINUE / NEW GAME.
- **A hand-drawn cast** of nine 16 × 16 characters (above) that mix and
  match heads and bodies, so adding a new trainer is a few lines of data.
- **Townsfolk** with tips: a GARDENER in Emberfall, a YOUNGSTER and a
  FIGHTER on Route 1, an OFFICER and a MYSTIC in Tidewater. They're
  converted from a downloaded sprite sheet into the game's palette.
- **Six hand-drawn monsters, each with a unique ability:** FLAMLET (KINDLE),
  AQUAPUP (SOAK UP), SPROUTLE (SUNSOAK), PEBBLET (STURDY SHELL), ZAPKIT
  (JOLT), SHADELING (DREAD). Route 1 has Sproutle, Pebblet, Zapkit and
  Flamlet.

  ![The six monsters from the front and from behind](docs/images/monsters.png)

## Project layout

```
autoload/      Events (signal bus), GameState (party, towns, flags), Audio
scenes/        main/, actors/ (GridActor, player, npc), maps/, objects/, ui/, battle/
scripts/       core/ (incl. GameData lookups), art/, audio/, items/ (ItemData),
               monsters/ (species, moves, abilities, Monster), battle/ (Battle rules)
data/          species/, moves/, abilities/, items/ (.tres files, edit in the inspector)
assets/        placeholder/ (generated PNGs), characters/townsfolk/ (converted pack
               sprites), tilesets/, ui/, fonts/, audio/
tools/         Headless generators for the art, TileSet, maps and monster data
tests/         Rule tests (battles, game state/saves) and a smoke test that plays the game
docs/          ARCHITECTURE.md, ASSETS.md
```

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): directory tree, node setups,
  physics layers, grid movement, field moves, the battle system, and how to
  add maps, monsters, moves and abilities.
- [docs/ASSETS.md](docs/ASSETS.md): what's generated, how to replace it, and
  free CC0 sources for tiles, sprites, monsters, SFX and music.

## Generated content

```sh
# Regenerate placeholder art; keeps the TileSet, maps and monster data you've edited
tools/rebuild_placeholders.sh
# Also rebuild those from tools/build_world.gd and tools/build_game_data.gd
tools/rebuild_placeholders.sh --force
```

Set `GODOT=/path/to/godot` if the binary isn't on your `PATH`. Sound needs no
build step: `Audio` synthesizes it at startup on a worker thread. Any file in
`assets/audio/` with a matching name replaces the generated sound.

The townsfolk aren't placeholders, so the script leaves them alone. After
changing their colors in `tools/import_townsfolk.gd`, re-convert them with:

```sh
godot --headless --path . --script res://tools/import_townsfolk.gd
godot --headless --path . --import
```

## Tests

```sh
# Battle rules: formulas, turn order, abilities, catching, items, PP, EXP (47 checks)
godot --headless --path . --script res://tests/battle_test.gd
# Party, BOX, BAG, flags and save/load round trips (19 checks)
godot --headless --path . --script res://tests/game_state_test.gd
# Plays the whole game by injecting input: starter, battles, menus, save, continue (44 checks)
godot --headless --path . --fixed-fps 60 --script res://tests/smoke_test.gd
```

Run the smoke test without `--headless` to also save screenshots to
`user://screenshots/`. The tests use their own save files and never touch
your real save.

## Roadmap

1. ~~**Monster data.**~~ Done: species, moves, abilities and `Monster` instances.
2. ~~**Battles.**~~ Done: wild battles with ability hooks, EXP and level-ups.
3. ~~**Catching.**~~ Done: orbs and POTIONs in the BAG, Gen 3 catch odds, the
   shake animation, and caught monsters joining the party or BOX.
4. ~~**Party & starter.**~~ Done: PROF. ASTER's starter, party screen and
   summary, BAG outside battle, MOM healing, save/load with a title screen.
5. **Field-move gating.** Unlock CUT/SURF/FLY through party moves and badges
   instead of the prototype's all-unlocked default.
6. **Content.** Trainers with line-of-sight battles, a Monster Center, a mart,
   a PC for the BOX, nicknames, more routes and towns, and real art from the
   sources in ASSETS.md.

## Credits

- Font: [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) by
  CodeMan38, SIL Open Font License 1.1 (`assets/fonts/PressStart2P-OFL.txt`).
- Palette: mostly [Sweetie 16](https://lospec.com/palette-list/sweetie-16) by GrafxKid.
- Townsfolk (YOUNGSTER, OFFICER, MYSTIC, FIGHTER, GARDENER): recolored
  from a 16 × 16 NES-style character sheet
  (`assets/characters/townsfolk/source/`). **TODO:** record the sheet's
  source page, author and license here before release.
- Everything else (characters, tiles, monsters, music, SFX) was drawn or
  generated by this project.
