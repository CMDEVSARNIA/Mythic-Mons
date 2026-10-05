extends Node
## Global signal bus (autoload "Events").
## Systems talk through these signals instead of holding references to each other.

## Ask Main to load a map. `spawn_id` names a SpawnPoint under the map's Spawns node.
signal warp_requested(map_path: String, spawn_id: StringName)
## A map finished loading and the player has been placed in it.
signal map_entered(map: WorldMap)
## The player stepped on encounter terrain and the encounter roll succeeded.
signal wild_encounter(species_id: StringName)
