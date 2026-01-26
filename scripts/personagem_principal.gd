extends CharacterBody3D

#==============================================================================#
# SIGNALS (UI COMMUNICATION)
#==============================================================================#
signal health_changed(new_health, max_health)
signal mana_changed(new_mana, max_mana)          # --- NOVO ---
signal stats_updated(total_defense, total_attack) # --- NOVO ---
signal gold_changed(new_gold)
signal xp_changed(new_xp, max_xp)
signal level_changed(new_level)

#==============================================================================#
# VARIABLES
#==============================================================================#

@export_category("Movement")
@export var velocidade_andar = 1.0
@export var velocidade_corrida = 3.0
@export var velocidade_agachado = 1.0
@export var forca_pulo = 4.0
@export var altura_degrau_snap = 0.5 

@onready var face_manager = $Face 

# --- DASH ---
@export var dash_speed = 25.0
@export var dash_duration = 0.2
var is_dashing := false 
@onready var dash_bubble = $corpo/DashBubble 
@onready var camera_principal = $CameraRoot/CameraHorizontal/CameraVertical/SpringArm3D/Camera3D 

# HEALTH & MANA (RPG)
@onready var vida: GameResource = $Health
# --- NOVO: Variáveis de Mana ---
@export var max_mana: int = 50
var current_mana: int = 50

# RPG STATS (Calculados)
var total_defense: int = 0  # --- NOVO ---
var total_attack: int = 0   # --- NOVO ---

# COMBAT & COMBO
var combo_count = 0
var timer_combo_window = 0.0 
var is_attacking = false
var in_attack_cooldown := false 

# WEAPON STATE (INVENTORY)
var is_weapon_equipped := false 
var weapon_drawn := false 
var equipped_weapon_ref: ItemData = null

@onready var hitbox_espada = $corpo/GeneralSkeleton/PontoAncoragemMao/weapon/Sketchfab_model/wado_fbx/RootNode/Box001/Object_4/ShapeKatana/HitboxArma

# VISUAL COMPONENTS (WEAPONS)
@onready var visual_espada_mao = $corpo/GeneralSkeleton/PontoAncoragemMao/weapon 
@onready var visual_espada_costas = $corpo/GeneralSkeleton/PontoAncoragemCostas/weapon

# PLAYER COMPONENTS
@onready var animation_player = $corpo/AnimationPlayer
@onready var animation_tree: AnimationTree = $corpo/AnimationTree
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var state_machine_combo = animation_tree.get("parameters/StateMachine_de_Combo/playback")

# MOVEMENT STATES
var is_crouching := false
var was_on_floor := false

# INTERACTION
@onready var raycast_interacao = $corpo/RayCast3D

# --- INVENTORY SYSTEM ---
var inventory = [] 

#==============================================================================#
# RPG STATS BASE
#==============================================================================#
var level: int = 1
var xp_atual: int = 0
var xp_proximo_nivel: int = 100
var ouro: int = 0
var atributos = {
	"forca": 10,
	"agilidade": 10,
	"inteligencia": 5
}

#==============================================================================#
# MAIN FUNCTIONS
#==============================================================================#

func _ready():
	animation_tree.active = true
	vida.depleated.connect(_on_vida_zerada)
	
	# Inicializa Mana
	current_mana = max_mana
	
	# UI INITIALIZATION
	await get_tree().process_frame
	
	notify_ui_update() # Atualiza Vida e Mana na UI
	calculate_stats()  # Calcula Defesa/Ataque iniciais
	atualizar_visual_armas()
	
	# Resize Inventory
	inventory.resize(20)

var proximo_ataque_agendado: bool = false 

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	
	# Combo Timer
	if combo_count > 0 and not is_attacking:
		timer_combo_window += delta
		if timer_combo_window > 1.5:
			combo_count = 0
			timer_combo_window = 0

	# --- STATE LOGIC ---
	
	# 1. DASH
	if is_dashing:
		move_and_slide()
		return 
		
	# 2. ATTACK
	elif is_attacking:
			if Input.is_action_just_pressed("attack"): proximo_ataque_agendado = true
			
			# Slow movement during attack
			velocity.x = move_toward(velocity.x, 0, 6.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 6.0 * delta)
			
			# Cancel with Dash
			if Input.is_action_just_pressed("dash") and is_on_floor():
				interromper_ataque_com_dash()
				
			move_and_slide()
			checar_fim_da_animacao_ataque()

	# 3. NORMAL
	else:
		handle_landing()
		handle_actions()
		
		# Combat Input
		handle_combat_input() 
		
		# Dash Input
		if Input.is_action_just_pressed("dash") and is_on_floor():
			executar_dash()
		
		if not is_dashing: 
			handle_movement()
			
		move_and_slide()
	
	update_animation_parameters()
	was_on_floor = is_on_floor()

func _input(event):
	# Debug
	if Input.is_action_just_pressed("Suicidy"): receber_dano(10)

	# Debug Inventory (Key T)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		is_weapon_equipped = not is_weapon_equipped
		weapon_drawn = false 
		atualizar_visual_armas()
		calculate_stats() # Recalcula se debuggar
		print("Simulação: Arma equipada? ", is_weapon_equipped)
		
	# Interaction (E)
	if event.is_action_pressed("interact"): tentar_interagir()

	# UI (Pause and Inventory)
	if event.is_action_pressed("toggle_inventory"): # TAB
		toggle_inventory()

	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		# Close Inventory if open
		var inventario_ui = get_tree().get_first_node_in_group("ui_inventory")
		if inventario_ui and inventario_ui.visible:
			inventario_ui.close()
			get_viewport().set_input_as_handled()
			return 
			
		# Toggle Pause
		var menu_pause = get_tree().get_first_node_in_group("ui_pause")
		if menu_pause:
			menu_pause.toggle_pause_menu()
			get_viewport().set_input_as_handled()
		elif has_node("/root/World/Overlay/MenuPause"):
			get_node("/root/World/Overlay/MenuPause").toggle_pause_menu()

func toggle_inventory():
	var ui = get_tree().get_first_node_in_group("ui_inventory")
	if ui:
		if ui.visible:
			ui.close()
		else:
			ui.open_default(self)

func tentar_interagir():
	if raycast_interacao.is_colliding():
		var objeto = raycast_interacao.get_collider()
		if objeto.has_method("interact"): 
			objeto.interact(self)
		elif objeto.has_method("interagir"): 
			objeto.interagir(self)

#==============================================================================#
# COMBAT AND ACTIONS
#==============================================================================#

func handle_combat_input():
	if not is_weapon_equipped:
		return

	# Toggle weapon draw (R)
	if Input.is_action_just_pressed("equip_toggle"):
		weapon_drawn = not weapon_drawn
		atualizar_visual_armas()
	
	# Attack
	if Input.is_action_just_pressed("attack") and weapon_drawn:
		realizar_ataque_combo()

func atualizar_visual_armas():
	if not visual_espada_mao or not visual_espada_costas:
		return

	if not is_weapon_equipped:
		visual_espada_mao.visible = false
		visual_espada_costas.visible = false
	else:
		if weapon_drawn:
			visual_espada_mao.visible = true
			visual_espada_costas.visible = false
		else:
			visual_espada_mao.visible = false
			visual_espada_costas.visible = true

func unequip_weapon():
	if is_weapon_equipped:
		print("Unequipping weapon...")
		is_weapon_equipped = false
		weapon_drawn = false
		equipped_weapon_ref = null
		atualizar_visual_armas()
		calculate_stats() # --- NOVO: Atualiza defesa/ataque ao tirar arma ---
		
func realizar_ataque_combo():
	proximo_ataque_agendado = false
	
	var atk_speed := 2.0 
	animation_tree.set("parameters/TimeScale/scale", atk_speed)
	animation_tree.set("parameters/OneShot_Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	combo_count += 1
	timer_combo_window = 0 
	is_attacking = true 
	
	# Auto-Aim
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		var camera_rotation_y = $CameraRoot/CameraHorizontal.global_rotation.y
		var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rotation_y).normalized()
		$corpo.rotation.y = atan2(direction.x, direction.z)
		velocity = direction * (-4.0) 
	else:
		velocity = -$corpo.global_transform.basis.z * (-2.0)

	# Anim
	var anim_nome = "Atk1"
	if combo_count == 2: anim_nome = "Atk2"
	elif combo_count >= 3: 
		anim_nome = "Atk3"
		combo_count = 0 

	state_machine_combo.travel(anim_nome)
	face_manager.mudar_expressao("ih")
	hitbox_rotina_segura()

func checar_fim_da_animacao_ataque():
	var estado_atual = state_machine_combo.get_current_node()
	if estado_atual != "Atk1" and estado_atual != "Atk2" and estado_atual != "Atk3":
		if proximo_ataque_agendado:
			realizar_ataque_combo()
		else:
			is_attacking = false

func hitbox_rotina_segura():
	await get_tree().create_timer(0.2).timeout
	if not is_attacking: return 
	
	toggle_hitbox(true)
	await get_tree().create_timer(0.4).timeout 
	toggle_hitbox(false)

func interromper_ataque_com_dash():
	is_attacking = false
	proximo_ataque_agendado = false
	toggle_hitbox(false)
	executar_dash()

func toggle_hitbox(ligar: bool):
	if not hitbox_espada: return
	hitbox_espada.monitoring = ligar

#==============================================================================#
# DAMAGE & RPG CALCULATION (CORE)
#==============================================================================#

# --- NOVO: Função para calcular Ataque e Defesa Total ---
func calculate_stats():
	# 1. Base (Vem dos atributos)
	total_attack = atributos["forca"]
	total_defense = int(atributos["agilidade"] / 2) # Exemplo: Agilidade dá esquiva/defesa
	
	# 2. Soma Itens Equipados (Arma)
	if is_weapon_equipped and equipped_weapon_ref:
		total_attack += equipped_weapon_ref.dano
		# Se a arma der defesa (ex: espada larga), soma aqui:
		total_defense += equipped_weapon_ref.defesa 
	
	# 3. Futuro: Somar Armaduras (Quando tiver slot de corpo)
	# if body_armor: total_defense += body_armor.defesa
	
	print("STATS: Defesa Total: ", total_defense, " | Ataque Total: ", total_attack)
	stats_updated.emit(total_defense, total_attack)

func receber_dano(quantidade: int):
	#face_manager.mudar_expressao("ou")
	
	# --- NOVO: Cálculo de Redução de Dano ---
	var dano_real = max(1, quantidade - total_defense)
	print("Dano recebido: ", quantidade, " - Defesa: ", total_defense, " = ", dano_real)
	
	vida.decrease(dano_real)
	
	# Atualiza a UI
	notify_ui_update()

func _on_vida_zerada():
	print("Você morreu!")
	get_tree().reload_current_scene()

func notify_ui_update():
	var max_v = 100
	if "max_amount" in vida: max_v = vida.max_amount
	
	health_changed.emit(vida.current_amount, max_v)
	mana_changed.emit(current_mana, max_mana)
	level_changed.emit(level)
	xp_changed.emit(xp_atual, xp_proximo_nivel)

# --- NOVO: Função para usar mana ---
func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

#==============================================================================#
# PROGRESSION AND INVENTORY
#==============================================================================#
func ganhar_xp(quantidade: int):
	xp_atual += quantidade
	xp_changed.emit(xp_atual, xp_proximo_nivel) 
	if xp_atual >= xp_proximo_nivel: subir_nivel()
		
func subir_nivel():
	level += 1
	xp_atual = xp_atual - xp_proximo_nivel
	xp_proximo_nivel = int(xp_proximo_nivel * 1.5)
	
	atributos["forca"] += 2
	atributos["agilidade"] += 1
	
	if "max_amount" in vida:
		vida.max_amount += 20 
		vida.current_amount = vida.max_amount
	
	current_mana = max_mana # Recupera mana ao subir de nivel
	
	notify_ui_update()
	calculate_stats() # Recalcula stats pois atributos mudaram

func receive_gold(amount: int):
	ouro += amount
	gold_changed.emit(ouro)

func add_item(item_novo: ItemData, qtd: int = 1) -> bool:
	# 1. Empilhar
	if item_novo.empilhavel:
		for i in range(inventory.size()):
			if inventory[i] != null and inventory[i]["item"] == item_novo:
				inventory[i]["quantity"] += qtd 
				on_inventory_changed()
				return true

	# 2. Slot Vazio
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = { "item": item_novo, "quantity": qtd }
			on_inventory_changed()
			return true
	return false

func on_inventory_changed():
	var ui = get_tree().get_first_node_in_group("ui_inventory")
	if ui and ui.visible: 
		ui.update_player_grid(ui.current_filter)

func use_item(index):
	var slot_data = inventory[index]
	if slot_data == null: return
	var item = slot_data["item"]
	
	if item.tipo == "consumivel":
		var usou = false
		
		# Poção de Vida
		if item.valor_efeito > 0 and vida.current_amount < vida.max_amount:
			vida.increase(item.valor_efeito)
			usou = true
		
		# Poção de Mana (Novo)
		if item.custo_mana < 0: # Se for negativo, recupera (hack) ou criar var recuperacao
			# Se você adicionou 'recuperacao' no ItemData use: item.recuperacao
			if current_mana < max_mana:
				current_mana = min(max_mana, current_mana + 20) # Exemplo fixo ou use item.recuperacao
				usou = true
		
		if usou:
			slot_data["quantity"] -= 1
			if slot_data["quantity"] <= 0: inventory[index] = null
			notify_ui_update() # Atualiza barras
			on_inventory_changed()

	elif item.tipo == "arma":
		if is_weapon_equipped and equipped_weapon_ref == item:
			unequip_weapon()
		else:
			is_weapon_equipped = true
			weapon_drawn = false 
			equipped_weapon_ref = item 
			atualizar_visual_armas()
			calculate_stats() # --- NOVO: Recalcula stats ao equipar ---
		
		on_inventory_changed()

#==============================================================================#
# MOVEMENT AND ANIMATION
#==============================================================================#

func handle_actions():
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = forca_pulo
		floor_snap_length = 0.0 
	else:
		floor_snap_length = altura_degrau_snap

	if Input.is_action_just_pressed("crouch") and is_on_floor():
		is_crouching = not is_crouching
		collision_shape.shape.height = 1.0 if is_crouching else 1.8
		collision_shape.position.y = 0.5 if is_crouching else 0.9

func handle_movement():
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir == Vector2.ZERO:
		velocity.x = lerp(velocity.x, 0.0, 0.15)
		velocity.z = lerp(velocity.z, 0.0, 0.15)
		return

	var velocidade_atual = velocidade_andar
	if is_crouching:
		velocidade_atual = velocidade_agachado
	elif Input.is_action_pressed("sprint"):
		velocidade_atual = velocidade_corrida

	var camera_horizontal = $CameraRoot/CameraHorizontal
	var camera_rotation_y = camera_horizontal.global_rotation.y
	var move_dir = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rotation_y).normalized()
	
	velocity.x = move_dir.x * velocidade_atual
	velocity.z = move_dir.z * velocidade_atual

	if move_dir.length() > 0.01:
		$corpo.rotation.y = lerp_angle($corpo.rotation.y, atan2(move_dir.x, move_dir.z), 0.15)

func update_animation_parameters():
	var vel_horizontal = Vector2(velocity.x, velocity.z).length()
	
	var anim_blend = Vector2(0, -1.0 if vel_horizontal > 0.1 else 0)
	if Input.is_action_pressed("sprint"): anim_blend.y = -2.0
	
	animation_tree.set("parameters/Locomocao/blend_position", anim_blend)

	var weapon_move_blend = clamp(vel_horizontal / velocidade_andar, 0.0, 1.0)
	animation_tree.set("parameters/Weapon_Movement/blend_position", weapon_move_blend)
	
	var target_blend = 1.0 if weapon_drawn else 0.0
	var current_blend = animation_tree.get("parameters/Posture_Weapon/blend_amount")
	animation_tree.set("parameters/Posture_Weapon/blend_amount", lerp(current_blend, target_blend, 0.1))

	animation_tree.set("parameters/Jump_Blender/blend_amount", 0.0 if is_on_floor() else 1.0)
	animation_tree.set("parameters/Crouch_Blender/blend_amount", 1.0 if is_crouching else 0.0)
	animation_tree.set("parameters/Air_Velocity_Blender/blend_amount", 1.0 if velocity.y < 0 else 0.0)

func handle_landing():
	if not was_on_floor and is_on_floor():
		animation_tree.set("parameters/Landing_OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

#==============================================================================#
# DASH SYSTEM
#==============================================================================#

func executar_dash():
	if is_dashing: return
	
	is_dashing = true
	
	# 1. DIRECTION
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		var camera_rotation_y = $CameraRoot/CameraHorizontal.global_rotation.y
		direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rotation_y).normalized()
		$corpo.rotation.y = atan2(direction.x, direction.z)
	else:
		direction = $corpo.global_transform.basis.z 

	# 2. PHYSICS
	velocity = direction * dash_speed
	
	# 3. ANIMATION
	animation_tree.set("parameters/OneShot_Dash/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	# 4. VISUALS
	var tween = create_tween().set_parallel(true)
	
	if camera_principal:
		tween.tween_property(camera_principal, "fov", 90.0, 0.1) # Zoom Out
	
	# 5. TIMER
	await get_tree().create_timer(dash_duration).timeout
	
	# 6. RESET
	var tween_volta = create_tween().set_parallel(true)
	tween_volta.tween_property($corpo, "rotation:x", 0.0, 0.2) 
	
	if camera_principal:
		tween_volta.tween_property(camera_principal, "fov", 75.0, 0.2) # Zoom Reset

	velocity = Vector3.ZERO
	is_dashing = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	pass


func _on_face_animation_player_animation_finished(anim_name: StringName) -> void:
	pass # Replace with function body.
