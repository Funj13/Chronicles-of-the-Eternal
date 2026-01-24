extends Control
#
## === REFERÊNCIAS VISUAIS ===
## Certifique-se de que os nomes dos nós na sua cena são exatamente estes:
#@onready var health_bar = $Bars_Container/HP_Bar
#@onready var mana_bar = $Bars_Container/MP_Bar
#@onready var level_label = $Level_Display/Label_Level
#
#func _ready():
#	# Espera um frame para garantir que tudo carregou
#	await get_tree().process_frame
#	
#	# Busca o Player pelo grupo "player"
#	var player = get_tree().get_first_node_in_group("player")
#	
#	if player:
#		print("✅ UI_Stats: Conectado ao Player com sucesso!")
#		
#		# 1. Conecta os Sinais (Ouve o Player)
#		player.health_changed.connect(update_health)
#		player.mana_changed.connect(update_mana)
#		player.level_changed.connect(update_level)
#		
#		# 2. Atualização Inicial (Para as barras começarem cheias)
#		force_update(player)
#	else:
#		print("❌ UI ERROR: Player não encontrado! Verifique se o Player foi adicionado ao grupo 'player'.")
#
#func force_update(player):
#	# Previne erro se o player ainda não tiver vida configurada
#	var max_hp = 100
#	var current_hp = 100
#	
#	# Verifica se usa o sistema de GameResource antigo ou variável direta
#	if player.vida and "max_amount" in player.vida:
#		max_hp = player.vida.max_amount
#		current_hp = player.vida.current_amount
#	
#	update_health(current_hp, max_hp)
#	update_mana(player.current_mana, player.max_mana)
#	update_level(player.level)
#
## === FUNÇÕES DE ATUALIZAÇÃO ===
#
#func update_health(current, max_val):
#	health_bar.max_value = max_val
#	health_bar.value = current
#	# Como configuramos "Left to Right" e "AtlasTexture", 
#	# o Godot corta a imagem automaticamente aqui.
#
#func update_mana(current, max_val):
#	mana_bar.max_value = max_val
#	mana_bar.value = current
#
#func update_level(lvl):
#	# O "%02d" formata o número para ter sempre 2 dígitos.
#	# Ex: Nível 5 vira "05". Nível 10 vira "10".
#	level_label.text = "%02d" % lvl
