extends Node
## Global signal bus (autoload "Events").
## Systems talk through these signals instead of holding references to each other.

## Ask Main to load a map. `spawn_id` names a SpawnPoint under the map's Spawns node.
signal warp_requested(map_path: String, spawn_id: StringName)
## A map finished loading and the player has been placed in it.
signal map_entered(map: WorldMap)
## The player stepped on encounter terrain and the encounter roll succeeded.
signal wild_encounter(species_id: StringName)
## An unbeaten trainer saw the player step into view. Main has them walk over.
signal trainer_spotted(trainer: Node) # A Trainer (untyped: autoloads load first).
## A trainer finished their intro lines. Main runs the battle.
signal trainer_battle(trainer: TrainerData)
