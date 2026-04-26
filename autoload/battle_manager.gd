extends Node

signal action_executed(action_text)
signal turn_started(actor)
signal battle_ended(victory)
signal ui_update_needed

var party_members: Array[BattleEntity] = []
var enemies: Array[BattleEntity] = []
var turn_queue: Array[BattleEntity] = []
var current_turn_index: int = 0
var battle_active: bool = false
var current_actor: BattleEntity = null

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func start_battle(party: Array, enemy_group: Array):
	party_members = party
	enemies = enemy_group
	battle_active = true
	rebuild_turn_queue()
	process_next_turn()

func rebuild_turn_queue():
	# Speed-Based: Sort all alive actors by speed stat (highest first)
	var all_actors = party_members.filter(func(e): return e.stats.is_alive()) + \
					 enemies.filter(func(e): return e.stats.is_alive())
	
	turn_queue = all_actors
	turn_queue.sort_custom(func(a, b): return a.stats.speed > b.stats.speed)
	current_turn_index = 0
	
	# Optional: Speed variance for RNG (small randomness)
	if turn_queue.size() > 1:
		for i in range(turn_queue.size() - 1):
			if abs(turn_queue[i].stats.speed - turn_queue[i+1].stats.speed) < 5:
				if rng.randf() < 0.3:  # 30% chance to swap similar speeds
					var temp = turn_queue[i]
					turn_queue[i] = turn_queue[i+1]
					turn_queue[i+1] = temp

func process_next_turn():
	if not battle_active:
		return
	
	# Check win/loss conditions
	if check_battle_end():
		return
	
	if current_turn_index >= turn_queue.size():
		rebuild_turn_queue()
	
	current_actor = turn_queue[current_turn_index]
	current_turn_index += 1
	
	if current_actor.stats.is_alive():
		emit_signal("turn_started", current_actor)
		
		if current_actor is Enemy:
			# Enemy AI - automatically choose action
			var action = current_actor.choose_action(party_members, enemies)
			execute_action(action)
		# For Player characters, wait for UI input via submit_player_action
	else:
		process_next_turn()

func submit_player_action(action_data: Dictionary):
	if current_actor != action_data["actor"]:
		return
	
	# Add RNG for hit chance
	var hit_chance = rng.randf()
	if hit_chance < 0.1:  # 10% miss chance
		battle_log.add_message("%s's attack missed!" % current_actor.character_name)
		after_action_complete()
		return
	
	execute_action(action_data)

func execute_action(action_data: Dictionary):
	var actor = action_data["actor"]
	var action_type = action_data["type"]
	var target = action_data.get("target")
	var extra = action_data.get("extra", {})
	
	var message = ""
	var crit = false
	
	match action_type:
		"attack":
			var damage = actor.stats.strength
			crit = actor.stats.calculate_critical()
			if crit:
				damage = int(damage * 1.5)
				message = "[CRITICAL!] "
			var actual_damage = target.stats.take_damage(damage)
			message += "%s attacked %s for %d damage!" % [actor.character_name, target.character_name, actual_damage]
			
		"defend":
			message = "%s defends, reducing next incoming damage by 50%%!" % actor.character_name
			actor.defending = true
			
		"magic":
			var spell = extra.get("spell", "Fire")
			var mp_cost = extra.get("mp_cost", 10)
			if actor.stats.use_mp(mp_cost):
				var damage = actor.stats.magic * 2
				crit = actor.stats.calculate_critical()
				if crit:
					damage = int(damage * 1.5)
				var actual_damage = target.stats.take_damage(damage, true)
				message = "%s casts %s on %s for %d damage!" % [actor.character_name, spell, target.character_name, actual_damage]
				if crit:
					message = "[CRITICAL!] " + message
			else:
				message = "%s doesn't have enough MP for %s!" % [actor.character_name, spell]
				
		"heal":
			var heal_amount = extra.get("heal_amount", 50)
			var actual_heal = target.stats.heal(heal_amount)
			message = "%s heals %s for %d HP!" % [actor.character_name, target.character_name, actual_heal]
			
		"item":
			var item_name = extra.get("item_name", "Potion")
			var effect = extra.get("effect", 50)
			if item_name == "Potion":
				var actual_heal = target.stats.heal(effect)
				message = "%s used %s on %s, healing %d HP!" % [actor.character_name, item_name, target.character_name, actual_heal]
			elif item_name == "Ether":
				if target is PartyMember:
					var mp_restore = target.stats.use_mp(-effect)  # Negative to restore
					target.stats.mp = min(target.stats.max_mp, target.stats.mp + effect)
					message = "%s used %s on %s, restoring %d MP!" % [actor.character_name, item_name, target.character_name, effect]
					
		"limit_break":  # Unique mechanic
			message = "%s uses LIMIT BREAK: Omnislash! Massive damage to all enemies!" % actor.character_name
			for enemy in enemies:
				if enemy.stats.is_alive():
					var damage = actor.stats.strength * 4
					enemy.stats.take_damage(damage)
					message += "\n  → Hit %s for %d damage!" % [enemy.character_name, damage]
	
	battle_log.add_message(message)
	emit_signal("action_executed", message)
	
	# Reset defending status after turn
	if action_type == "defend":
		actor.defending = false
	
	after_action_complete()

func after_action_complete():
	emit_signal("ui_update_needed")
	await get_tree().create_timer(0.5).timeout  # Small delay for readability
	process_next_turn()

func check_battle_end() -> bool:
	var party_alive = false
	for member in party_members:
		if member.stats.is_alive():
			party_alive = true
			break
	
	var enemies_alive = false
	for enemy in enemies:
		if enemy.stats.is_alive():
			enemies_alive = true
			break
	
	if not party_alive:
		battle_active = false
		emit_signal("battle_ended", false)
		battle_log.add_message("GAME OVER - Your party was defeated!")
		return true
	elif not enemies_alive:
		battle_active = false
		emit_signal("battle_ended", true)
		battle_log.add_message("VICTORY! You defeated all enemies!")
		return true
	
	return false
