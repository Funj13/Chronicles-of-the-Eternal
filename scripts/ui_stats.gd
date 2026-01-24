extends Control

# --- REFERÊNCIAS VISUAIS ---
# Ajuste os caminhos ($) conforme sua árvore de nós real!
@onready var health_bar = $Bars_Container/HP_Bar
@onready var mana_bar = $Bars_Container/MP_Bar
@onready var level_label = $Level_Display/Label_Level

# Se você quiser mostrar a defesa na tela depois, crie um Label e referencie aqui
# @onready var defense_label = $InfoContainer/DefenseLabel 

func _ready():
	# Busca o Player
	await get_tree().process_frame
	# DICA: Garanta que seu Player esteja no grupo "player" (Node > Groups)
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		connect_signals(player)
	else:
		print("UI_Stats: Player não encontrado! Verifique o grupo 'player'.")

func connect_signals(player):
	# Conecta os sinais do player às funções desta UI
	player.health_changed.connect(update_health)
	player.mana_changed.connect(update_mana)
	player.level_changed.connect(update_level)
	# player.stats_updated.connect(update_stats) # Descomente quando tiver onde mostrar a defesa

# --- ATUALIZAÇÃO DAS BARRAS ---

func update_health(current, max_val):
	health_bar.max_value = max_val
	health_bar.value = current
	# O TextureProgressBar cortará a imagem automaticamente

func update_mana(current, max_val):
	mana_bar.max_value = max_val
	mana_bar.value = current

func update_level(lvl):
	# Formata para ter sempre 2 dígitos (ex: 01, 05, 10) fica mais "Tech"
	level_label.text = "%02d" % lvl

# Opcional: Se você criou um Label para defesa
# func update_stats(defense, attack):
# 	defense_label.text = str(defense)
