# Audio overrides

Every sound in the game has an id. Until a file exists for an id, the `Audio`
autoload plays a chiptune version generated at runtime
(`scripts/audio/chip_synth.gd`, `scripts/audio/songs.gd`).

Drop a file named after the id here and it is used instead (`.ogg`, `.wav` or
`.mp3`). No code changes needed.

| Folder   | Ids in use |
|----------|------------|
| `music/` | `title` (title screen and new-game intro), `town`, `route` (maps choose one with `WorldMap.music`), `battle` (wild), `trainer_battle`, `gym_battle` (uses `trainer_battle`'s file if it has none), `spotted` (a trainer walking up to you), `victory` |
| `sfx/`   | `bump`, `select`, `menu`, `door`, `jump`, `cut`, `smash`, `surf`, `fly`, `encounter`, `hit`, `hit_super`, `hit_weak`, `faint`, `stat_up`, `stat_down`, `flee`, `level_up`, `throw`, `ball_shake`, `break_free`, `catch`, `heal`, `purchase`, `evolve`, `exclaim`, `poison`, `sleep`, `pc_on`, `pc_off`, `badge`, `orb_open`, `orb_bounce`, `recall`, and the move sounds `swish`, `slash`, `burn`, `splash`, `bubble`, `leaf`, `zap`, `thunder`, `rock`, `ghost`, `growl`, `glint` |

Music files loop from start to end automatically (`Audio._music_file()`).

## Songs in `music/`

Supplied by the project owner as WAV and converted to OGG Vorbis (quality 5)
with `ffmpeg -i in.wav -c:a libvorbis -q:a 5 out.ogg`:

| File | Song |
|------|------|
| `title.ogg` | Square Wave Title |
| `town.ogg` | Beep-Boo |
| `route.ogg` | Square Wave Adventure |
| `battle.ogg` | Pixel Battle |
| `trainer_battle.ogg` | Pixel Battle Theme (also gym battles) |
| `victory.ogg` | Triumphant Fanfare |

`spotted` and every sound effect are still generated.
