extends Control

const CENA_DROP = preload("res://Scenes/ItemDrop.tscn") # CONFIRA O CAMINHO!

@onready var is_open = false

@onready var grid = $Botton/GridItens # Verifique se o caminho do seu Grid está certo!
# Se o Grid for filho direto do Control, use só $GridItens. Ajuste conforme sua cena.

func _ready():
	# Começa fechado (Invisível)
	visible = false

func _input(event):
	# TRAVA DE SEGURANÇA: Se o jogo estiver pausado, ignora tudo.
	if get_tree().paused:
		return

	# Se apertar TAB...
	if event.is_action_pressed("toggle_inventory"):
		if is_open:
			fechar()
		else:
			abrir()
			
func abrir():
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# A MÁGICA REAL: Atualiza o visual
	atualizar_grid()

func fechar():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func atualizar_grid():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
		
	var slots = grid.get_children()
	
	for i in range(slots.size()):
		var slot_ui = slots[i]
		slot_ui.indice_slot = i
		
		# Conecta o sinal se necessário
		if not slot_ui.slot_clicado.is_connected(usar_item):
			slot_ui.slot_clicado.connect(usar_item)
		
		# --- ATUALIZAÇÃO DO VISUAL ---
		if i < player.inventario.size():
			var dados_slot = player.inventario[i] # Agora isso é um Dicionário ou Null
			
			if dados_slot != null:
				# Passa o Item e a Quantidade correta
				slot_ui.item_armazenado = dados_slot["item"] # Guarda ref pro clique funcionar
				slot_ui.atualizar_slot(dados_slot["item"], dados_slot["quantidade"])
			else:
				# Slot vazio
				slot_ui.item_armazenado = null
				slot_ui.atualizar_slot(null, 0)
				
				
# Esta função precisa estar conectada ao sinal 'slot_clicado' dos Slots
func usar_item(indice, botao_mouse = -1): # Aceita o botão agora
	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	# Pega o PACOTE (Dicionário)
	var slot_data = player.inventario[indice]
	if slot_data == null: return

	# === BOTÃO ESQUERDO (1) = USAR ===
	# (Se o botao_mouse for -1, é compatibilidade com código antigo)
	if botao_mouse == MOUSE_BUTTON_LEFT or botao_mouse == -1:
		player.usar_item_do_inventario(indice)
		atualizar_grid()

	# === BOTÃO DIREITO (2) = DROPAR ===
	elif botao_mouse == MOUSE_BUTTON_RIGHT:
		dropar_item(player, slot_data, indice)

func dropar_item(player, dados, indice):
	# 1. Instancia o objeto
	var novo_drop = CENA_DROP.instantiate()
	novo_drop.configurar(dados["item"], dados["quantidade"])
	
	var spawn_pos = player.global_position + (player.transform.basis.z * 1.0)
	spawn_pos.y += 1.0 
	novo_drop.global_position = spawn_pos
	
	get_tree().current_scene.add_child(novo_drop)
	
	# === AQUI ESTÁ A CORREÇÃO ===
	var item_sendo_dropado = dados["item"]
	
	# Se o item for do tipo "arma", manda o player desequipar visualmente
	if item_sendo_dropado.tipo == "arma":
		player.desequipar_arma()
	# ============================
	
	# Remove da mochila
	player.inventario[indice] = null
	atualizar_grid()
	
	print("Dropou: ", dados["item"].nome)
