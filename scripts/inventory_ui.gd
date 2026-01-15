extends Control

const CENA_DROP = preload("res://Scenes/ItemDrop.tscn") # Verifique o caminho!

@onready var is_open = false
@onready var grid = $Botton/GridItens

# Referências aos componentes do PAINEL DE DETALHES (Lado Direito)
@onready var painel_detalhes = $Panel
@onready var label_nome_detalhe = $Panel/Panel_Item/Name_item
# Esta é a referência para o TextureRect do ícone grande
@onready var label_icone_detalhe = $Panel/Slot99/IconeItem 
@onready var label_desc_detalhe = $Panel/description
@onready var btn_acao = $Panel/VBoxContainer/equip
@onready var btn_drop = $Panel/VBoxContainer/drop

var indice_selecionado: int = -1

func _ready():
	visible = false
	painel_detalhes.visible = false # Começa escondido
	
	# Conecta os botões do painel às funções
	btn_acao.pressed.connect(_on_btn_acao_pressed)
	btn_drop.pressed.connect(_on_btn_drop_pressed)

func _input(event):
	if get_tree().paused and not visible: return # Só abre se não estiver pausado por outro motivo
	
	if event.is_action_pressed("toggle_inventory"):
		if is_open:
			fechar()
		else:
			abrir()

func abrir():
	visible = true
	is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	atualizar_grid()

func fechar():
	visible = false
	is_open = false
	painel_detalhes.visible = false # Limpa a seleção ao fechar
	indice_selecionado = -1
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func atualizar_grid():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
		
	var slots = grid.get_children()
	
	for i in range(slots.size()):
		var slot_ui = slots[i]
		slot_ui.indice_slot = i
		
		# Conecta o sinal do slot à função de SELECIONAR (não usar direto)
		if not slot_ui.slot_clicado.is_connected(_on_slot_clicked):
			slot_ui.slot_clicado.connect(_on_slot_clicked)
		
		if i < player.inventario.size():
			var dados_slot = player.inventario[i]
			if dados_slot != null:
				slot_ui.item_armazenado = dados_slot["item"]
				slot_ui.atualizar_slot(dados_slot["item"], dados_slot["quantidade"])
			else:
				slot_ui.item_armazenado = null
				slot_ui.atualizar_slot(null, 0)

	# Se tiver algo selecionado, atualiza o painel também (ex: gastou poção, atualiza qtd ou fecha se acabou)
	if indice_selecionado != -1:
		validar_selecao_atual(player)

# --- NOVA LÓGICA DE SELEÇÃO ---

func _on_slot_clicked(indice, botao_mouse):
	var player = get_tree().get_first_node_in_group("player")
	# Se clicar com botão direito, já dropa direto (atalho)
	if botao_mouse == MOUSE_BUTTON_RIGHT:
		var slot_data = player.inventario[indice]
		if slot_data: dropar_item_logica(player, slot_data, indice)
		return

	# Seleção normal com botão esquerdo
	indice_selecionado = indice
	atualizar_painel_detalhes(player)

func atualizar_painel_detalhes(player):
	var dados = player.inventario[indice_selecionado]
	
	if dados == null:
		painel_detalhes.visible = false
		return
		
	painel_detalhes.visible = true
	var item = dados["item"]
	
	# === ADIÇÃO DA IMAGEM AQUI ===
	# Pega a textura do item e aplica no TextureRect do painel de detalhes
	label_icone_detalhe.texture = item.icone
	# =============================
	
	# Preenche Textos
	# (Verifique se seus Labels no Inspector têm Autowrap ligado para a descrição não vazar)
	label_nome_detalhe.text = item.nome
	if "descricao" in item:
		label_desc_detalhe.text = item.descricao
	else:
		label_desc_detalhe.text = "Sem descrição."
		
	# LÓGICA DO TEXTO DO BOTÃO
	if item.tipo == "consumivel":
		btn_acao.text = "Usar"
		
	elif item.tipo == "arma":
		# Verifica se ESSA arma específica está equipada
		if player.is_weapon_equipped and player.arma_equipada_ref == item:
			btn_acao.text = "Desequipar"
		else:
			btn_acao.text = "Equipar"
	
	else:
		btn_acao.text = "Usar" # Padrão

# --- AÇÕES DOS BOTÕES ---

func _on_btn_acao_pressed():
	if indice_selecionado == -1: return
	
	var player = get_tree().get_first_node_in_group("player")
	# Usa a função do player que já lida com equipar/desequipar/consumir
	player.usar_item_do_inventario(indice_selecionado)
	
	# Atualiza tudo
	atualizar_grid()
	validar_selecao_atual(player) # Re-checa o texto do botão (Equipar -> Desequipar)

func _on_btn_drop_pressed():
	if indice_selecionado == -1: return
	var player = get_tree().get_first_node_in_group("player")
	var dados = player.inventario[indice_selecionado]
	
	if dados:
		dropar_item_logica(player, dados, indice_selecionado)

# Lógica de Drop separada para reusar no clique direito
func dropar_item_logica(player, dados, indice):
	# 1. Instancia o Drop no Mundo
	if CENA_DROP:
		var novo_drop = CENA_DROP.instantiate()
		# Verifica se a cena de drop tem script com função 'configurar'
		if novo_drop.has_method("configurar"):
			novo_drop.configurar(dados["item"], dados["quantidade"])
		
		# Posição na frente do player
		var spawn_pos = player.global_position + (player.global_transform.basis.z * 1.5)
		spawn_pos.y += 0.5
		novo_drop.global_position = spawn_pos
		get_tree().current_scene.add_child(novo_drop)
	
	# 2. Se for arma equipada, desequipa
	if dados["item"].tipo == "arma" and player.arma_equipada_ref == dados["item"]:
		player.desequipar_arma()
		
	# 3. Limpa inventário
	player.inventario[indice] = null
	
	# 4. Atualiza UI
	painel_detalhes.visible = false # Fecha painel pois item sumiu
	indice_selecionado = -1
	atualizar_grid()

func validar_selecao_atual(player):
	# Verifica se o item selecionado ainda existe ou mudou de estado
	var dados = player.inventario[indice_selecionado]
	if dados == null:
		painel_detalhes.visible = false
		indice_selecionado = -1
	else:
		# Atualiza o texto do botão (caso tenha mudado de Equipar para Desequipar)
		atualizar_painel_detalhes(player)
