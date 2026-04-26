extends Control

@onready var action_panel = $ActionPanel
@onready var target_panel = $TargetPanel
@onready var targets_container = $TargetPanel/TargetsContainer
@onready var battle_log_display = $BattleLog

# This will be set by the main scene
var battle_manager = null
var current_actor = null
var pending_action_type = ""
var pending_action_data = null

func _ready():
	# Don't connect anything yet - wait for setup() to be called
	pass

# Call this from your main scene after creating the UI
func setup(manager):
	battle_manager = manager
	battle_manager.turn_started.connect(_on_turn_started)
	print("BattleUI connected to BattleManager")

func _on_turn_started(actor):
	print("Turn started for: ", actor.character_name)
	current_actor = actor
	if actor.has_method("get_class") and actor.get_class() == "PartyMember":
		action_panel.show()
		target_panel.hide()

# BUTTON CALLBACKS - Connect these in the editor
func _on_attack_pressed():
	print("Attack pressed")
	pending_action_type = "attack"
	show_targets("enemy")

func _on_magic_pressed():
	print("Magic pressed")
	pending_action_type = "magic"
	pending_action_data = {"spell": "Fire", "mp_cost": 15}
	show_targets("enemy")

func _on_heal_pressed():
	print("Heal pressed")
	pending_action_type = "heal"
	pending_action_data = {"heal_amount": 80}
	show_targets("ally")

func _on_defend_pressed():
	print("Defend pressed")
	submit_action(null)

func show_targets(target_group):
	if not battle_manager:
		print("ERROR: battle_manager not set!")
		return
	
	action_panel.hide()
	target_panel.show()
	
	# Clear old buttons
	for child in targets_container.get_children():
		child.queue_free()
	
	# Get valid targets based on group
	var targets = []
	if target_group == "enemy":
		targets = battle_manager.enemies.filter(func(e): return e.stats.hp > 0)
	else:  # ally
		targets = battle_manager.party_members.filter(func(p): return p != current_actor and p.stats.hp > 0)
	
	print("Found ", targets.size(), " targets")
	
	# Create button for each target
	for target in targets:
		var btn = Button.new()
		btn.text = "%s (HP: %d/%d)" % [target.character_name, target.stats.hp, target.stats.max_hp]
		btn.custom_minimum_size = Vector2(150, 40)
		btn.pressed.connect(_on_target_selected.bind(target))
		targets_container.add_child(btn)
	
	# Add cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(150, 40)
	cancel_btn.pressed.connect(_on_cancel_targeting)
	targets_container.add_child(cancel_btn)

func _on_target_selected(target):
	print("Target selected: ", target.character_name)
	submit_action(target)

func _on_cancel_targeting():
	target_panel.hide()
	action_panel.show()

func submit_action(target):
	if not battle_manager:
		print("ERROR: Cannot submit action - battle_manager missing")
		return
	
	var action = {
		"actor": current_actor,
		"type": pending_action_type,
		"target": target
	}
	
	if pending_action_data:
		action["extra"] = pending_action_data
	
	print("Submitting action: ", action)
	battle_manager.submit_player_action(action)
	
	# Clean up
	target_panel.hide()
	action_panel.hide()
	pending_action_data = null
	current_actor = null
