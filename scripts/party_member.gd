extends BattleEntity
class_name PartyMember

# 5+ unique commands spread across party
var unique_commands = {
	"Cloud": ["attack", "limit_break", "magic_fire", "defend", "item"],
	"Aeris": ["attack", "heal", "magic_ice", "defend", "item"],
}

func _init(name: String = "Cloud"):
	character_name = name
	commands = unique_commands.get(name, ["attack", "defend", "item"])
	
	# Set different stats per character
	match name:
		"Knight":
			stats = Stats.new()
			stats.max_hp = 2354
			stats.hp = 1873
			stats.max_mp = 350
			stats.mp = 294
			stats.strength = 45
			stats.magic = 20
			stats.speed = 32
		"Healer":
			stats = Stats.new()
			stats.max_hp = 1232
			stats.hp = 743
			stats.max_mp = 400
			stats.mp = 271
			stats.strength = 18
			stats.magic = 48
			stats.speed = 28
		"Monk":
			stats = Stats.new()
			stats.max_hp = 1505
			stats.hp = 760
			stats.max_mp = 320
			stats.mp = 297
			stats.strength = 35
			stats.magic = 30
			stats.speed = 40
