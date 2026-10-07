# Bitglow interior pack (not included)

`assets/interiors/furniture.png` is built from Bitglow's pixel interior pack
(`pixelinterior_BR_v1.1`): beds, wardrobes, dressers, nightstands, vanities,
lamps, wall decorations and rugs, shrunk to half size for this game.

The pack's license lets the game use and modify the art, but not share the
original files, so they are kept out of the repository. To rebuild the
atlas, put `beds_BR.png`, `wardrobes_BR.png` and `decorations_BR.png` from
the pack in this folder, then run:

```sh
godot --headless --path . --script res://tools/import_interiors.gd
godot --headless --path . --import
```

The `.gdignore` file keeps Godot from importing (and exporting) the sheets.
