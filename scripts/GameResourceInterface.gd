extends Control

# UI REFERENCES
# Mantive os caminhos ($...) iguais, mas mudei os nomes das variáveis para inglês
@onready var health_bar := $TextureRect/Life_Bar
@onready var gold_label = $VBoxContainer/Gold_Label
@onready var level_label = $VBoxContainer/Label_Level
@onready var xp_bar = $VBoxContainer/XP_Bar

func _ready() -> void:
	# Wait for player to load
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("✅ UI: Connected to Player!")
		
		# --- CONNECT NEW ENGLISH SIGNALS ---
		player.gold_changed.connect(update_gold)
		player.xp_changed.connect(update_xp)
		player.level_changed.connect(update_level)
		player.health_changed.connect(update_health)
		
		# --- INITIAL UPDATE ---
		# Note: Variáveis do player ainda estão em misto (ouro/level/xp_atual) 
		# conforme o script do player que definimos antes.
		update_gold(player.ouro)
		update_level(player.level)
		update_xp(player.xp_atual, player.xp_proximo_nivel)
		
		if player.vida:
			var max_v = 100
			if "max_amount" in player.vida:
				max_v = player.vida.max_amount
			update_health(player.vida.current_amount, max_v)
	else:
		print("❌ UI ERROR: Player not found in group 'player'")

# === UPDATE FUNCTIONS (ENGLISH) ===

func update_health(current_val, max_val):
	health_bar.max_value = max_val
	health_bar.value = current_val

func update_gold(new_val):
	# Mantive o emoji, se quiser tirar é só apagar o "💰 "
	gold_label.text = "💰 " + str(new_val)

func update_level(new_val):
	# Traduzi o texto de exibição também, mas pode manter "Nível" se preferir
	level_label.text = "Level: " + str(new_val)

func update_xp(current_val, max_val):
	xp_bar.max_value = max_val
	xp_bar.value = current_val
