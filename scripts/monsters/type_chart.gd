class_name TypeChart
extends RefCounted
## Element matchups. Elements are plain strings so species and moves can pick
## them from an @export_enum dropdown; keep those lists in sync with ELEMENTS.

const ELEMENTS: Array[String] = ["normal", "fire", "water", "grass", "rock", "electric", "ghost"]

## Attacking element -> {defending element: multiplier}. Missing pairs are 1x.
const CHART := {
	"normal": {"rock": 0.5, "ghost": 0.0},
	"fire": {"fire": 0.5, "water": 0.5, "grass": 2.0, "rock": 0.5},
	"water": {"fire": 2.0, "water": 0.5, "grass": 0.5, "rock": 2.0},
	"grass": {"fire": 0.5, "water": 2.0, "grass": 0.5, "rock": 2.0},
	"rock": {"fire": 2.0, "electric": 2.0, "rock": 0.5},
	"electric": {"water": 2.0, "grass": 0.5, "electric": 0.5, "rock": 0.5},
	"ghost": {"normal": 0.0, "ghost": 2.0},
}


static func multiplier(attacking: String, defending: String) -> float:
	return CHART.get(attacking, {}).get(defending, 1.0)
