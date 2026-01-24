extends Control

const DROP_SCENE = preload("res://Scenes/ItemDrop.tscn")
const SLOT_SCENE = preload("res://Scenes/slot.tscn")

# ==============================================================================
# UI REFERENCES (Atualizado para imagem image_871acd.png)
# ==============================================================================

# --- SIDEBAR BUTTONS ---
@onready var btn_resources = $menu/side_menu/resources
@onready var btn_equip = $menu/side_menu/equipment
@onready var btn_files = $menu/side_menu/archives
@onready var btn_chest = $menu/side_menu/loot

# --- PLAYER GRID (ESQUERDA) ---
# Agora usa o novo nome "Bottom_Inventario"
@onready var grid_player = $Bottom_Inventario/GridItens 

# --- DETALHES (DIREITA - MODO 1) ---
# Referência ao PAI de todos os detalhes
@onready var mode_details_root = $Menu_Detalhes

# Filhos dentro de Menu_Detalhes
@onready var icon_detail = $Menu_Detalhes/Slot99/IconeItem
@onready var name_detail = $Menu_Detalhes/Panel_Item/Name_item
@onready var desc_detail = $Menu_Detalhes/description
@onready var btn_action = $Menu_Detalhes/VBoxContainer/equip
@onready var btn_drop = $Menu_Detalhes/VBoxContainer/drop
@onready var container_buttons = $Menu_Detalhes/VBoxContainer

# --- BAÚ (DIREITA - MODO 2) ---
# Referência ao PAI do baú (Agora separado!)
@onready var mode_chest_root = $Bau 

# Filhos dentro de Bau
@onready var mode_chest_grid = $Bau/GridContainer
@onready var mode_chest_label = $Bau/Panel_Item/Name_item

# ==============================================================================
# STATE VARIABLES
# ==============================================================================
var player_ref = null
var current_chest_ref = null
var selected_index: int = -1
var current_filter: String = "all"

func _ready():
	visible = false
	
	# Conexões dos botões do menu
	btn_resources.pressed.connect(func(): switch_tab("resource"))
	btn_equip.pressed.connect(func(): switch_tab("equipment"))
	btn_files.pressed.connect(func(): switch_tab("file"))
	btn_chest.pressed.connect(func(): switch_tab("chest"))
	
	# Conexões das ações
	btn_action.pressed.connect(_on_btn_action_pressed)
	btn_drop.pressed.connect(_on_btn_drop_pressed)
	
	# Estado inicial: Esconde botão de loot e painel do baú
	if btn_chest: btn_chest.visible = false
	if mode_chest_root: mode_chest_root.visible = false
	if mode_details_root: mode_details_root.visible = true # Começa mostrando detalhes

# ==============================================================================
# OPEN / CLOSE LOGIC
# ==============================================================================

func open_default(player):
	player_ref = player
	current_chest_ref = null
	
	if btn_chest: btn_chest.visible = false
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	switch_tab("all")

func open_with_chest(player, chest):
	player_ref = player
	current_chest_ref = chest
	
	if btn_chest: btn_chest.visible = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	switch_tab("chest")

func close():
	visible = false
	selected_index = -1
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if current_chest_ref and current_chest_ref.has_method("close_chest"):
		current_chest_ref.close_chest()

# ==============================================================================
# TABS & FILTERS (Lógica Simplificada!)
# ==============================================================================

func switch_tab(mode: String):
	current_filter = mode
	selected_index = -1
	
	if mode == "chest":
		# --- ATIVAR MODO BAÚ ---
		# Como você separou os nós, agora é fácil: desliga um, liga o outro.
		if mode_details_root: mode_details_root.visible = false
		if mode_chest_root: mode_chest_root.visible = true
		
		# Configura o Baú
		update_chest_grid()
		if current_chest_ref and mode_chest_label:
			mode_chest_label.text = "Conteúdo"
		
		update_player_grid("all")
		
	else:
		# --- ATIVAR MODO DETALHES ---
		if mode_chest_root: mode_chest_root.visible = false
		if mode_details_root: mode_details_root.visible = true
		
		update_player_grid(mode)
		update_details_panel()

# ==============================================================================
# GRID UPDATES
# ==============================================================================

func update_player_grid(filter: String):
	if not player_ref: return
	
	var slots = grid_player.get_children()
	var inventory = player_ref.inventory 
	
	for i in range(slots.size()):
		var slot_ui = slots[i]
		slot_ui.slot_index = i
		
		if not slot_ui.slot_clicked.is_connected(_on_slot_clicked):
			slot_ui.slot_clicked.connect(_on_slot_clicked.bind("PLAYER"))
		
		if i < inventory.size() and inventory[i] != null:
			var item = inventory[i]["item"]
			
			# Filtros
			var show = true
			if filter != "all":
				if filter == "equipment" and item.tipo != "arma": show = false
				elif filter == "resource" and item.tipo != "recurso": show = false
				elif filter == "file" and item.tipo != "arquivo": show = false
			
			if show:
				slot_ui.visible = true
				slot_ui.update_slot(item, inventory[i]["quantity"])
			else:
				slot_ui.visible = false 
		else:
			slot_ui.update_slot(null, 0)

func update_chest_grid():
	if not current_chest_ref or not mode_chest_grid: return
	
	# Limpa grid antigo
	for child in mode_chest_grid.get_children():
		child.queue_free()
		
	var chest_inv = current_chest_ref.chest_inventory
	
	# Cria novos slots
	for i in range(chest_inv.size()):
		var new_slot = SLOT_SCENE.instantiate()
		mode_chest_grid.add_child(new_slot)
		
		new_slot.slot_index = i
		new_slot.slot_clicked.connect(_on_slot_clicked.bind("CHEST"))
		
		if chest_inv[i]:
			new_slot.update_slot(chest_inv[i]["item"], chest_inv[i]["quantity"])
		else:
			new_slot.update_slot(null, 0)

# ==============================================================================
# INTERACTIONS
# ==============================================================================

func _on_slot_clicked(index, mouse_button, origin):
	
	# DIREITO: Transfere ou Usa
	if mouse_button == MOUSE_BUTTON_RIGHT:
		if current_filter == "chest" and current_chest_ref:
			if origin == "PLAYER":
				transfer_item(player_ref.inventory, current_chest_ref.chest_inventory, index)
			else:
				transfer_item(current_chest_ref.chest_inventory, player_ref.inventory, index)
			
			update_player_grid("all")
			update_chest_grid()
		else:
			if origin == "PLAYER":
				player_ref.use_item(index)
				update_player_grid(current_filter)
				update_details_panel()
		return

	# ESQUERDO: Seleciona
	if origin == "PLAYER":
		selected_index = index
		if current_filter != "chest":
			update_details_panel()

# ==============================================================================
# TRANSFER LOGIC
# ==============================================================================

func transfer_item(source_array, target_array, src_idx):
	var source_data = source_array[src_idx]
	if source_data == null: return
	
	var item = source_data["item"]
	var qty = source_data["quantity"]
	var transferred = false
	
	if item.empilhavel:
		for i in range(target_array.size()):
			if target_array[i] and target_array[i]["item"] == item:
				target_array[i]["quantity"] += qty
				transferred = true
				break
	
	if not transferred:
		for i in range(target_array.size()):
			if target_array[i] == null:
				target_array[i] = { "item": item, "quantity": qty }
				transferred = true
				break
	
	if transferred:
		source_array[src_idx] = null
	else:
		print("Sem espaço no destino!")

# # ==============================================================================
# DETAILS PANEL
# ==============================================================================

func update_details_panel():
	# Se nenhum item estiver selecionado ou o índice for inválido
	if selected_index == -1 or selected_index >= player_ref.inventory.size():
		limpar_detalhes()
		return

	var data = player_ref.inventory[selected_index]
	
	if data == null:
		limpar_detalhes()
		return
		
	container_buttons.visible = true
	var item = data["item"]
	
	# --- CORREÇÃO AQUI ---
	# Acessamos as propriedades direto (item.icone, item.nome, item.descricao)
	if icon_detail: icon_detail.texture = item.icone
	if name_detail: name_detail.text = item.nome
	
	# Removemos o .get() e acessamos direto. 
	# Se a descrição estiver vazia, colocamos um texto padrão manualmente.
	if desc_detail: 
		if item.descricao != "":
			desc_detail.text = item.descricao
		else:
			desc_detail.text = "Sem descrição disponível."
	
	# Lógica do Botão de Ação
	if item.tipo == "arma":
		if player_ref.equipped_weapon_ref == item:
			btn_action.text = "Desequipar"
		else:
			btn_action.text = "Equipar"
	else:
		btn_action.text = "Usar"

# Função auxiliar para limpar a tela (evita repetir código)
func limpar_detalhes():
	if icon_detail: icon_detail.texture = null
	if name_detail: name_detail.text = "Vazio"
	if desc_detail: desc_detail.text = ""
	container_buttons.visible = false

func _on_btn_action_pressed():
	if selected_index == -1: return
	player_ref.use_item(selected_index)
	update_player_grid(current_filter)
	update_details_panel()

func _on_btn_drop_pressed():
	if selected_index == -1: return
	var data = player_ref.inventory[selected_index]
	if data:
		drop_item_logic(player_ref, data, selected_index)

# ==============================================================================
# PHYSICS DROP
# ==============================================================================

func drop_item_logic(player, data, index):
	if not DROP_SCENE: return

	# 1. Cria o objeto
	var new_drop = DROP_SCENE.instantiate()
	get_tree().current_scene.add_child(new_drop)
	
	# 2. Passa os dados
	if new_drop.has_method("configurar"):
		new_drop.configurar(data["item"], data["quantity"])
	
	# 3. Define a Posição (Na frente do player)
	var spawn_pos = player.global_position + (player.global_transform.basis.z * 1.5)
	
	# Se for Area3D (flutuante), coloca na altura do peito, senão no chão
	if new_drop is Area3D:
		spawn_pos.y += 1.0 
	else:
		spawn_pos.y += 0.5

	# Aplica a posição com segurança
	if new_drop is Node3D:
		new_drop.global_position = spawn_pos
		
		# 4. Só aplica FORÇA se for um corpo físico (RigidBody)
		if new_drop is RigidBody3D:
			var throw_dir = (spawn_pos - player.global_position).normalized()
			new_drop.apply_central_impulse(throw_dir * 5.0)
	
	# 5. Remove do inventário e atualiza arma
	if data["item"].tipo == "arma" and player.equipped_weapon_ref == data["item"]:
		player.unequip_weapon()
		
	player.inventory[index] = null
	
	update_player_grid(current_filter)
	update_details_panel()
