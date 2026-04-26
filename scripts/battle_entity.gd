extends Node2D
class_name BattleEntity

@export var character_name: String = "Hero"
@export var stats: Stats
@export var commands: Array[String] = ["attack", "defend", "item"]

var defending: bool = false

func _ready():
	if not stats:
		stats = Stats.new()

func take_damage(amount: int, is_magic: bool = false) -> int:
	var final_damage = amount
	if defending:
		final_damage = int(final_damage * 0.5)
		defending = false
	return stats.take_damage(final_damage, is_magic)
