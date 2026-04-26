extends Resource
class_name Stats

@export var max_hp: int = 100
@export var hp: int = 100
@export var max_mp: int = 50
@export var mp: int = 50
@export var strength: int = 10
@export var magic: int = 10
@export var defense: int = 8
@export var magic_defense: int = 8
@export var speed: int = 10  # Critical for Speed-Based system
@export var level: int = 1
@export var exp_value: int = 50

# RNG elements
var rng = RandomNumberGenerator.new()

func _init():
	rng.randomize()

func take_damage(amount: int, is_magic: bool = false) -> int:
	var defense_stat = magic_defense if is_magic else defense
	var variance = rng.randf_range(0.85, 1.15)  # RNG damage roll
	var raw_damage = amount - defense_stat / 2
	var actual_damage = max(1, int(raw_damage * variance))
	hp = max(0, hp - actual_damage)
	return actual_damage

func heal(amount: int) -> int:
	var variance = rng.randf_range(0.9, 1.1)  # RNG heal variance
	var actual_heal = min(max_hp - hp, int(amount * variance))
	hp += actual_heal
	return actual_heal

func use_mp(amount: int) -> bool:
	if mp >= amount:
		mp -= amount
		return true
	return false

func is_alive() -> bool:
	return hp > 0

func calculate_critical() -> bool:
	return rng.randi() % 100 < 15  # 15% crit chance
