extends BattleEntity
class_name Enemy

@export var enemy_type: String = "soldier"
@export var exp_reward: int = 100
@export var gold_reward: int = 150

var rng = RandomNumberGenerator.new()

func _init(type: String = "soldier"):
	enemy_type = type
	character_name = type.capitalize()
	commands = ["attack", "special_attack"]
	
	match type:
		"soldier":
			stats = Stats.new()
			stats.max_hp = 850
			stats.hp = 850
			stats.strength = 25
			stats.defense = 15
			stats.speed = 20
			exp_reward = 80
		"mage":
			stats = Stats.new()
			stats.max_hp = 600
			stats.hp = 600
			stats.magic = 35
			stats.strength = 12
			stats.speed = 18
			commands = ["attack", "fire_spell"]
			exp_reward = 120
		"boss":
			stats = Stats.new()
			stats.max_hp = 2500
			stats.hp = 2500
			stats.strength = 40
			stats.magic = 30
			stats.defense = 25
			stats.speed = 35
			commands = ["attack", "special_attack", "defend"]
			exp_reward = 500

func choose_action(party: Array, all_enemies: Array) -> Dictionary:
	# RNG-based enemy move selection
	var action_choice = rng.randi() % commands.size()
	var selected_command = commands[action_choice]
	
	# Find a random alive target
	var alive_targets = party.filter(func(p): return p.stats.is_alive())
	if alive_targets.is_empty():
		return {"actor": self, "type": "attack", "target": null}
	
	var target = alive_targets[rng.randi() % alive_targets.size()]
	
	match selected_command:
		"attack":
			return {"actor": self, "type": "attack", "target": target}
		"special_attack":
			return {"actor": self, "type": "special_attack", "target": target, "extra": {"damage_mult": 1.8}}
		"fire_spell":
			return {"actor": self, "type": "magic", "target": target, "extra": {"spell": "Fire", "mp_cost": 0}}
		"defend":
			return {"actor": self, "type": "defend", "target": null}
	
	return {"actor": self, "type": "attack", "target": target}
