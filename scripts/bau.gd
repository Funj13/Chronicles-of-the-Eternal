extends StaticBody3D 

@onready var anim = $AnimationPlayer 

# --- CHEST CONFIGURATION ---
@export var initial_items: Array[ItemData] = [] 
@export var gold_reward: int = 100 
@export var chest_size: int = 10 

var chest_inventory = [] # The "Database" of the chest
var is_open = false

func _ready():
	# Initialize the chest database
	chest_inventory.resize(chest_size)
	
	for i in range(initial_items.size()):
		if i < chest_size:
			chest_inventory[i] = { "item": initial_items[i], "quantity": 1 }

func interact(player):
	if is_open: 
		open_ui(player) # Just open UI if already looted
		return
	
	is_open = true
	print("--- Chest Opened ---")
	
	# 1. Animation
	if anim and anim.has_animation("open"):
		anim.play("open")
	
	# 2. Gold (Instant)
	if gold_reward > 0:
		player.receive_gold(gold_reward)
		gold_reward = 0
	
	# 3. Open UI (Delayed slightly for effect)
	await get_tree().create_timer(0.3).timeout
	open_ui(player)

func open_ui(player):
	var ui = get_tree().get_first_node_in_group("ui_inventory") # Mudei o grupo para ui_inventory para ser padrão
	if ui:
		ui.open_with_chest(player, self)
	else:
		print("Error: Inventory UI not found in group 'ui_inventory'")

# Helper function for the UI to call when closing
func close_chest():
	# If you have a close animation, play it here
	pass
