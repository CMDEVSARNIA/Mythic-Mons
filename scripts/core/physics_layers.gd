class_name PhysicsLayers
extends RefCounted
## Bit values for the 2D physics layers named in Project Settings > Layer Names.

const WORLD := 1       ## Walls, buildings, signs, ledges: blocks everyone.
const WATER := 2       ## Water tiles: blocks walkers, ignored while surfing.
const ACTORS := 4      ## Player and NPCs.
const OBSTACLES := 8   ## Field-move blockers (CUT trees, ROCK SMASH rocks, STRENGTH boulders).
const TRIGGERS := 16   ## Warps and other step-on areas (never block movement).

## What a walking actor collides with.
const WALKER_MASK := WORLD | WATER | ACTORS | OBSTACLES
## What the player can press A on.
const INTERACT_MASK := WORLD | ACTORS | OBSTACLES
