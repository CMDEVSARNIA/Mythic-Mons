# Audio overrides

Every sound in the game has an id. Until a file exists for an id, the `Audio`
autoload plays a chiptune version generated at runtime
(`scripts/audio/chip_synth.gd`, `scripts/audio/songs.gd`).

Drop a file named after the id here and it is used instead (`.ogg`, `.wav` or
`.mp3`). No code changes needed.

| Folder   | Ids in use |
|----------|------------|
| `music/` | `town`, `route` (maps choose one with `WorldMap.music`) |
| `sfx/`   | `bump`, `select`, `menu`, `door`, `jump`, `cut`, `smash`, `surf`, `fly`, `encounter` |

For music, enable **Loop** in the Import dock after adding the file.
