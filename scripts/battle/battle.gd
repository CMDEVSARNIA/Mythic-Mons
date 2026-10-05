class_name Battle
extends RefCounted
## The rules of a wild battle, with no visuals.
##
## Each call returns the events it produced, in order, as dictionaries.
## BattleScene plays them back as text and animation. Keeping the rules apart
## from the screen makes them testable (tests/battle_test.gd) and reusable for
## trainer battles later.
##
## Event types. Most also carry "side" (&"player" or &"enemy"):
##   message   {text, wait}        wait = needs a button press, else auto-advances
##   attack    {side, move}        the move's animation (MoveAnimator)
##   hit       {side, effectiveness}
##   hp        {side, hp}          animate the HP bar to this value
##   stat      {side, stat, stages}
##   faint     {side}
##   withdraw  {side}, send_out {side}
##   flee      {}
##   restore   {side}             healing-item sparkle (before its hp event)
##   throw     {item}             a ball flies at the wild monster
##   shake     {}                 the ball wobbles (0-3 times)
##   caught    {} / break_free {}
##
## Damage is the Generation 3 formula (STAB 1.5x, type matchups, 1/16 crits
## worth 2x, a random 85-100% roll), simplified to the five stats of Monster.
## Catching uses the Generation 3 formula too (see catch_shakes()).

enum Outcome { ONGOING, WON, LOST, FLED, CAUGHT }
enum Action { FIGHT, SWITCH, RUN, ITEM }

const PLAYER := &"player"
const ENEMY := &"enemy"
const CRIT_CHANCE := 1.0 / 16.0
const STRUGGLE_PATH := "res://data/moves/struggle.tres"
const STAT_NAMES := {&"attack": "ATTACK", &"defense": "DEFENSE", &"special": "SPECIAL", &"speed": "SPEED"}
## What the game says after the ball breaks open, by how many times it shook.
const BREAK_FREE_TEXT: Array[String] = [
	"Oh, no! The MONSTER\nbroke free!",
	"Aww! It appeared to\nbe caught!",
	"Aargh!\nAlmost had it!",
	"Shoot! It was so\nclose, too!",
]

var party: Array[Monster]
var player: Battler
var enemy: Battler
var rng: RandomNumberGenerator
var outcome := Outcome.ONGOING
## Used in "<trainer> used <item>!" messages.
var trainer_name := "YOU"
## Set before the first turn: was the wild monster met in the water (DIVE
## ORB), and has its species been caught before (REPEAT ORB)?
var in_water := false
var already_caught := false
## Turns played so far (TIMER ORB).
var turns := 0

var _events: Array[Dictionary] = []
var _after_hit: PackedStringArray = []
var _run_attempts := 0


## `party` must contain at least one monster that can still fight.
func _init(p_party: Array[Monster], wild: Monster, p_rng: RandomNumberGenerator = null) -> void:
	party = p_party
	rng = p_rng
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	player = Battler.new(first_healthy(), PLAYER)
	enemy = Battler.new(wild, ENEMY, true)


# --- Actions the player can choose ------------------------------------------

## `move_index` -1 means STRUGGLE (for when no move has PP left).
static func fight(move_index: int) -> Dictionary:
	return {"action": Action.FIGHT, "move": move_index}


static func switch_to(party_index: int) -> Dictionary:
	return {"action": Action.SWITCH, "index": party_index}


static func run_away() -> Dictionary:
	return {"action": Action.RUN}


## Balls and healing items. The caller removes the item from the BAG.
static func use_item(item: ItemData) -> Dictionary:
	return {"action": Action.ITEM, "item": item}


# --- Flow --------------------------------------------------------------------

## Abilities that trigger as the battle begins (call once, after the intro).
func start() -> Array[Dictionary]:
	for battler in _by_speed():
		_trigger_enter(battler)
	return _flush()


func take_turn(action: Dictionary) -> Array[Dictionary]:
	assert(outcome == Outcome.ONGOING and not player.is_fainted(), "take_turn() needs an active battle")
	match action.action:
		Action.RUN:
			if _try_run():
				message("Got away safely!", true)
				_push(&"flee", {})
				outcome = Outcome.FLED
				return _flush()
			message("Can't escape!")
			_use_move(enemy, player, _enemy_move())
		Action.SWITCH:
			_switch_player(action.index, false)
			_use_move(enemy, player, _enemy_move())
		Action.ITEM:
			_use_item(action.item)
			_use_move(enemy, player, _enemy_move())
		Action.FIGHT:
			var player_move := _player_move(action.move)
			var enemy_move := _enemy_move()
			if _goes_first(enemy, enemy_move, player, player_move):
				_use_move(enemy, player, enemy_move)
				_use_move(player, enemy, player_move)
			else:
				_use_move(player, enemy, player_move)
				_use_move(enemy, player, enemy_move)
	if outcome == Outcome.ONGOING:
		_end_of_turn()
	turns += 1
	return _flush()


## True when the active monster fainted and another one has to be sent out.
func player_must_switch() -> bool:
	return outcome == Outcome.ONGOING and player.is_fainted()


func switch_after_faint(party_index: int) -> Array[Dictionary]:
	_switch_player(party_index, true)
	return _flush()


func can_switch_to(party_index: int) -> bool:
	var monster := party[party_index]
	return not monster.is_fainted() and monster != player.monster


## Generation 3 catch check. Returns how many of the four shake checks pass:
## 4 means caught; 0-3 is how many times the ball wobbles before it breaks.
## Lower HP and a better ball raise the odds.
func catch_shakes(target: Monster, ball_multiplier: float) -> int:
	var max_hp := target.max_hp()
	var rate := (3 * max_hp - 2 * target.hp) * target.species.catch_rate * ball_multiplier / (3.0 * max_hp)
	if rate >= 255.0:
		return 4
	var shake_odds := floori(1048560.0 / sqrt(sqrt(16711680.0 / maxf(rate, 1.0))))
	var shakes := 0
	while shakes < 4 and rng.randi_range(0, 65535) < shake_odds:
		shakes += 1
	return shakes


## The catch multiplier `ball` has right now, counting special-orb bonuses.
## As in Gen 3, a NEST ORB gives (40 - level) / 10 (at least 1x), and a
## TIMER ORB (turns + 10) / 10 (at most 4x).
func ball_multiplier(ball: ItemData) -> float:
	match ball.bonus:
		ItemData.Bonus.ELEMENT:
			if StringName(enemy.element) in ball.bonus_elements:
				return ball.bonus_multiplier
		ItemData.Bonus.IN_WATER:
			if in_water:
				return ball.bonus_multiplier
		ItemData.Bonus.REPEAT:
			if already_caught:
				return ball.bonus_multiplier
		ItemData.Bonus.LOW_LEVEL:
			return maxf(1.0, (40 - enemy.monster.level) / 10.0)
		ItemData.Bonus.TIMER:
			return minf(4.0, (turns + 10) / 10.0)
	return ball.catch_multiplier


## EXP for defeating the wild monster: exp_yield * level / 7.
func exp_reward() -> int:
	return maxi(1, floori(enemy.monster.species.exp_yield * enemy.monster.level / 7.0))


func first_healthy() -> Monster:
	for monster in party:
		if not monster.is_fainted():
			return monster
	return null


## Generation 3 damage formula. `roll` is the 85-100 random factor.
func calculate_damage(user: Battler, target: Battler, move: MoveData, crit: bool, effectiveness: float, roll: int) -> int:
	var physical := move.category == MoveData.Category.PHYSICAL
	var attack_stat := &"attack" if physical else &"special"
	var defense_stat := &"defense" if physical else &"special"
	var attack_stage: int = user.stages[attack_stat]
	var defense_stage: int = target.stages[defense_stat]
	if crit: # Critical hits ignore the attacker's drops and the defender's boosts.
		attack_stage = maxi(attack_stage, 0)
		defense_stage = mini(defense_stage, 0)
	var attack := user.stat_at_stage(attack_stat, attack_stage)
	var defense := target.stat_at_stage(defense_stat, defense_stage)
	var level_factor := floori(2.0 * user.monster.level / 5.0) + 2
	var base := floori(floori(level_factor * move.power * attack / float(defense)) / 50.0) + 2
	var modifier := effectiveness * roll / 100.0
	if crit:
		modifier *= 2.0
	if move.element == user.element:
		modifier *= 1.5
	if user.ability:
		modifier *= user.ability.damage_multiplier(self, user, target, move)
	return maxi(1, floori(base * modifier))


# --- Helpers for abilities ---------------------------------------------------

func foe_of(battler: Battler) -> Battler:
	return enemy if battler == player else player


func message(text: String, wait := false) -> void:
	_push(&"message", {"text": text, "wait": wait})


## Queues a message to show right after the current hit's damage.
func message_after_hit(text: String) -> void:
	_after_hit.append(text)


## Heals up to `amount` HP and returns how much was actually restored.
func heal(battler: Battler, amount: int) -> int:
	var monster := battler.monster
	var before := monster.hp
	monster.hp = mini(monster.hp + amount, monster.max_hp())
	if monster.hp != before:
		_push(&"hp", {"side": battler.side, "hp": monster.hp})
	return monster.hp - before


## Changes a stat stage and reports it. Returns false if it was already at the limit.
func change_stat(battler: Battler, stat: StringName, stages: int) -> bool:
	var before: int = battler.stages[stat]
	var after := clampi(before + stages, Battler.MIN_STAGE, Battler.MAX_STAGE)
	var stat_name: String = STAT_NAMES[stat]
	if after == before:
		message("%s's %s won't go\n%s!" % [battler.name, stat_name, "higher" if stages > 0 else "lower"])
		return false
	battler.stages[stat] = after
	_push(&"stat", {"side": battler.side, "stat": stat, "stages": after - before})
	var how := ""
	match after - before:
		1:
			how = "rose!"
		-1:
			how = "fell!"
		_:
			how = "sharply rose!" if after > before else "harshly fell!"
	message("%s's %s\n%s" % [battler.name, stat_name, how])
	return true


# --- Internals ---------------------------------------------------------------

func _use_move(user: Battler, target: Battler, move: MoveData) -> void:
	if outcome != Outcome.ONGOING or user.is_fainted():
		return
	_spend_pp(user, move)
	message("%s used\n%s!" % [user.name, move.display_name])
	var targets_self := not move.is_damaging() and move.stat_target == MoveData.Target.SELF
	if not targets_self and rng.randi_range(1, 100) > move.accuracy:
		message("%s's attack missed!" % user.name)
		return
	if not move.is_damaging():
		_push(&"attack", {"side": user.side, "move": move})
		_apply_stat_effect(user, target, move)
		return

	var effectiveness := TypeChart.multiplier(move.element, target.element)
	if effectiveness == 0.0:
		message("It doesn't affect\n%s..." % target.name)
		return
	var crit := rng.randf() < CRIT_CHANCE
	var damage := calculate_damage(user, target, move, crit, effectiveness, rng.randi_range(85, 100))
	_push(&"attack", {"side": user.side, "move": move})
	if target.ability:
		damage = target.ability.modify_damage_taken(self, target, user, move, damage)
	if damage > 0:
		target.monster.hp = maxi(target.monster.hp - damage, 0)
		_push(&"hit", {"side": target.side, "effectiveness": effectiveness})
		_push(&"hp", {"side": target.side, "hp": target.monster.hp})
		if crit:
			message("A critical hit!")
		if effectiveness > 1.0:
			message("It's super effective!")
		elif effectiveness < 1.0:
			message("It's not very\neffective...")
	for text in _after_hit:
		message(text)
	_after_hit.clear()
	if _check_faint(target):
		return
	if damage > 0 and target.ability:
		target.ability.on_hit(self, target, user, move, damage)
	if not move.stat_changes.is_empty() and rng.randi_range(1, 100) <= move.effect_chance:
		_apply_stat_effect(user, target, move)


func _use_item(item: ItemData) -> void:
	message("%s used\n%s!" % [trainer_name, item.display_name])
	match item.kind:
		ItemData.Kind.BALL:
			_throw_ball(item)
		ItemData.Kind.HEAL:
			_push(&"restore", {"side": player.side})
			var healed := heal(player, item.heal_amount)
			message("%s's HP was\nrestored by %d point%s." % [player.name, healed, "" if healed == 1 else "s"])


func _throw_ball(ball: ItemData) -> void:
	_push(&"throw", {"item": ball})
	var shakes := catch_shakes(enemy.monster, ball_multiplier(ball))
	for i in mini(shakes, 3):
		_push(&"shake", {})
	if shakes >= 4:
		_push(&"caught", {})
		message("Gotcha!\n%s was caught!" % enemy.monster.get_display_name(), true)
		if not ball.resource_path.is_empty():
			enemy.monster.orb = GameData.id_of(ball)
		outcome = Outcome.CAUGHT
	else:
		_push(&"break_free", {})
		message(BREAK_FREE_TEXT[shakes])


func _apply_stat_effect(user: Battler, target: Battler, move: MoveData) -> void:
	var affected := user if move.stat_target == MoveData.Target.SELF else target
	for stat: StringName in move.stat_changes:
		change_stat(affected, stat, move.stat_changes[stat])


## Reports a faint and updates the outcome. Returns true if `battler` fainted.
func _check_faint(battler: Battler) -> bool:
	if not battler.is_fainted():
		return false
	_push(&"faint", {"side": battler.side})
	message("%s fainted!" % battler.name, true)
	if battler == enemy:
		outcome = Outcome.WON
	elif first_healthy() == null:
		outcome = Outcome.LOST
	return true


func _end_of_turn() -> void:
	for battler in _by_speed():
		if outcome != Outcome.ONGOING or battler.is_fainted() or battler.ability == null:
			continue
		battler.ability.on_turn_end(self, battler)
		_check_faint(battler)


func _switch_player(party_index: int, forced: bool) -> void:
	if not forced:
		message("%s, come back!" % player.name)
		_push(&"withdraw", {"side": PLAYER})
	player = Battler.new(party[party_index], PLAYER)
	message("Go! %s!" % player.name)
	_push(&"send_out", {"side": PLAYER})
	_trigger_enter(player)


func _trigger_enter(battler: Battler) -> void:
	if battler.ability:
		battler.ability.on_enter(self, battler)


func _spend_pp(user: Battler, move: MoveData) -> void:
	var index := user.monster.moves.find(move)
	if index >= 0:
		user.monster.pp[index] = maxi(user.monster.pp[index] - 1, 0)


func _player_move(index: int) -> MoveData:
	var moves := player.monster.moves
	return moves[index] if index >= 0 and index < moves.size() else _struggle()


## Wild monsters pick a random move that still has PP.
func _enemy_move() -> MoveData:
	var usable: Array[int] = []
	for i in enemy.monster.moves.size():
		if enemy.monster.pp[i] > 0:
			usable.append(i)
	if usable.is_empty():
		return _struggle()
	return enemy.monster.moves[usable[rng.randi_range(0, usable.size() - 1)]]


func _struggle() -> MoveData:
	return load(STRUGGLE_PATH)


func _goes_first(a: Battler, a_move: MoveData, b: Battler, b_move: MoveData) -> bool:
	if a_move.priority != b_move.priority:
		return a_move.priority > b_move.priority
	var a_speed := a.stat(&"speed")
	var b_speed := b.stat(&"speed")
	if a_speed != b_speed:
		return a_speed > b_speed
	return rng.randf() < 0.5


## Generation 3 escape odds: faster always escapes, otherwise it gets easier
## with every attempt.
func _try_run() -> bool:
	_run_attempts += 1
	var mine := player.stat(&"speed")
	var theirs := enemy.stat(&"speed")
	if mine >= theirs:
		return true
	var odds := (floori(mine * 128.0 / theirs) + 30 * _run_attempts) % 256
	return rng.randi_range(0, 255) < odds


func _by_speed() -> Array[Battler]:
	return [player, enemy] if player.stat(&"speed") >= enemy.stat(&"speed") else [enemy, player]


func _push(type: StringName, data: Dictionary) -> void:
	data["type"] = type
	_events.append(data)


func _flush() -> Array[Dictionary]:
	var events := _events
	_events = []
	return events
