extends CharacterBody3D

#==============================================================================#
# SINAIS (COMUNICAÇÃO COM A UI)
#==============================================================================#
signal mudou_vida(nova_vida, max_vida)
signal mudou_ouro(novo_ouro)
signal mudou_xp(novo_xp, xp_maximo)
signal mudou_nivel(novo_nivel)

#==============================================================================#
# VARIÁVEIS
#==============================================================================#

@export_category("Movimento")
@export var velocidade_andar = 1.0
@export var velocidade_corrida = 3.0
@export var velocidade_agachado = 1.0
@export var forca_pulo = 4.0
@export var altura_degrau_snap = 0.5 

@onready var face_manager = $Face 

# --- DASH (NOVO SISTEMA) ---
@export var dash_speed = 25.0
@export var dash_duration = 0.2
var is_dashing := false 
@onready var dash_bubble = $corpo/DashBubble # A bolha de distorção (MeshInstance3D)
@onready var camera_principal = $CameraRoot/CameraHorizontal/CameraVertical/SpringArm3D/Camera3D 

# VIDA
@onready var vida: GameResource = $Health

# COMBATE & COMBO
var combo_count = 0
var timer_combo_window = 0.0 
var is_attacking = false
var in_attack_cooldown := false 
var arma_equipada_ref: ItemData = null 

# ESTADO DA ARMA (INVENTÁRIO)
var is_weapon_equipped := false 
var weapon_drawn := false 

@onready var hitbox_espada = $corpo/GeneralSkeleton/PontoAncoragemMao/weapon/Sketchfab_model/wado_fbx/RootNode/Box001/Object_4/ShapeKatana/HitboxArma
# COMPONENTES VISUAIS (ARMAS)
@onready var visual_espada_mao = $corpo/GeneralSkeleton/PontoAncoragemMao/weapon 
@onready var visual_espada_costas = $corpo/GeneralSkeleton/PontoAncoragemCostas/weapon

# COMPONENTES DO PLAYER
@onready var animation_player = $corpo/AnimationPlayer
@onready var animation_tree: AnimationTree = $corpo/AnimationTree
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var state_machine_combo = animation_tree.get("parameters/StateMachine_de_Combo/playback")

# ESTADOS DE MOVIMENTO
var is_crouching := false
var was_on_floor := false

# INTERAÇÕES COM MAPA
@onready var raycast_interacao = $corpo/RayCast3D
var inventario = []

#==============================================================================#
# ESTATÍSTICAS DE RPG
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
# FUNÇÕES PRINCIPAIS
#==============================================================================#

func _ready():
	animation_tree.active = true
	vida.depleated.connect(_on_vida_zerada)
	
	# INICIALIZAÇÃO DA UI
	await get_tree().process_frame
	
	var vida_max = 100
	if "max_amount" in vida:
		vida_max = vida.max_amount
		
	mudou_vida.emit(vida.current_amount, vida_max)
	atualizar_visual_armas()
	inventario.resize(20)

var proximo_ataque_agendado: bool = false # Buffer

func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	
	# Timer do Combo
	if combo_count > 0 and not is_attacking:
		timer_combo_window += delta
		if timer_combo_window > 1.5:
			combo_count = 0
			timer_combo_window = 0

	# --- LÓGICA DE ESTADOS ---
	
	# 1. ESTADO DE DASH (PRIORIDADE MÁXIMA)
	if is_dashing:
		move_and_slide()
		return # Sai da função para não rodar mais nada
		
	# 2. ESTADO DE ATAQUE
	elif is_attacking:
			if Input.is_action_just_pressed("attack"): proximo_ataque_agendado = true
			
			# Movimento lento durante ataque (Hybrid Feel)
			velocity.x = move_toward(velocity.x, 0, 6.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 6.0 * delta)
			
			# Cancelamento com Dash
			if Input.is_action_just_pressed("dash") and is_on_floor():
				interromper_ataque_com_dash()
				
			move_and_slide()
			checar_fim_da_animacao_ataque()

	# 3. VIDA NORMAL
	else:
		handle_landing()
		handle_actions()
		
		# --- COMBATE RESTAURADO (INPUT R e CLICK) ---
		handle_combat_input() 
		# --------------------------------------------
		
		# Input de Dash Novo
		if Input.is_action_just_pressed("dash") and is_on_floor():
			executar_dash()
		
		# Só calcula movimento se NÃO estiver em dash (Correção do bug de travar)
		if not is_dashing: 
			handle_movement()
			
		move_and_slide()
	
	update_animation_parameters()
	was_on_floor = is_on_floor()

func _input(event):
	# Debug
	if Input.is_action_just_pressed("Suicidy"): receber_dano(10)

	# Tecla T (Debug Inventário)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		is_weapon_equipped = not is_weapon_equipped
		weapon_drawn = false 
		atualizar_visual_armas()
		print("Simulação: Arma equipada? ", is_weapon_equipped)
		
	# Interação E
	if event.is_action_pressed("interact"): tentar_interagir()

	# UI (Pause e Inventário)
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var inventario_ui = get_tree().get_first_node_in_group("ui_inventario")
		if inventario_ui and inventario_ui.visible:
			inventario_ui.fechar()
			get_viewport().set_input_as_handled()
			return 
			
		var menu_pause = get_tree().get_first_node_in_group("ui_pause")
		if menu_pause:
			menu_pause.toggle_pause_menu()
			get_viewport().set_input_as_handled()
		elif has_node("/root/World/Overlay/MenuPause"):
			get_node("/root/World/Overlay/MenuPause").toggle_pause_menu()

func tentar_interagir():
	if raycast_interacao.is_colliding():
		var objeto = raycast_interacao.get_collider()
		if objeto.has_method("interagir"):
			objeto.interagir(self) 

#==============================================================================#
# COMBATE E AÇÕES
#==============================================================================#

# --- LÓGICA RESTAURADA DE INPUT DE COMBATE ---
func handle_combat_input():
	if not is_weapon_equipped:
		return

	# Sacar/Guardar arma com R (equip_toggle)
	if Input.is_action_just_pressed("equip_toggle"):
		weapon_drawn = not weapon_drawn
		atualizar_visual_armas()
	
	# Atacar apenas se a arma estiver SACADA (na mão)
	if Input.is_action_just_pressed("attack") and weapon_drawn:
		realizar_ataque_combo()
# ---------------------------------------------

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

func desequipar_arma():
	if is_weapon_equipped:
		print("Desequipando arma...")
		is_weapon_equipped = false
		weapon_drawn = false
		arma_equipada_ref = null
		atualizar_visual_armas()
		
func realizar_ataque_combo():
	proximo_ataque_agendado = false
	
	var atk_speed := 2.0 
	animation_tree.set("parameters/TimeScale/scale", atk_speed)
	animation_tree.set("parameters/OneShot_Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	combo_count += 1
	timer_combo_window = 0 
	is_attacking = true 
	
	# Auto-Aim e Impulso
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		var camera_rotation_y = $CameraRoot/CameraHorizontal.global_rotation.y
		var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rotation_y).normalized()
		$corpo.rotation.y = atan2(direction.x, direction.z)
		velocity = direction * (-4.0) 
	else:
		velocity = -$corpo.global_transform.basis.z * (-2.0)

	# Animação
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
			print("Fim do combo.")

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
	executar_dash() # Chama o dash novo

func toggle_hitbox(ligar: bool):
	if not hitbox_espada: return
	hitbox_espada.monitoring = ligar

# === DANO ===
func receber_dano(quantidade: int):
	face_manager.mudar_expressao("ou")
	vida.decrease(quantidade)
	
	var max_v = 100
	if "max_amount" in vida:
		max_v = vida.max_amount
	mudou_vida.emit(vida.current_amount, max_v)

func _on_vida_zerada():
	print("Você morreu!")
	get_tree().reload_current_scene()

#==============================================================================#
# PROGRESSÃO E INVENTÁRIO
#==============================================================================#
func ganhar_xp(quantidade: int):
	xp_atual += quantidade
	mudou_xp.emit(xp_atual, xp_proximo_nivel) 
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
		mudou_vida.emit(vida.current_amount, vida.max_amount)
	
	mudou_nivel.emit(level)
	mudou_xp.emit(xp_atual, xp_proximo_nivel) 

func receber_ouro(quantidade: int):
	ouro += quantidade
	mudou_ouro.emit(ouro)

func adicionar_item(item_novo: ItemData, qtd: int = 1) -> bool:
	if item_novo.empilhavel:
		for i in range(inventario.size()):
			if inventario[i] != null and inventario[i]["item"] == item_novo:
				inventario[i]["quantidade"] += qtd
				mudou_inventario()
				return true

	for i in range(inventario.size()):
		if inventario[i] == null:
			inventario[i] = { "item": item_novo, "quantidade": qtd }
			mudou_inventario()
			return true
	return false

func mudou_inventario():
	var ui = get_tree().get_first_node_in_group("ui_inventario")
	if ui and ui.visible: ui.atualizar_grid()

func usar_item_do_inventario(indice):
	var slot_data = inventario[indice]
	if slot_data == null: return
	var item = slot_data["item"]
	
	if item.tipo == "consumivel":
		if vida.current_amount < vida.max_amount:
			vida.increase(item.valor_efeito)
			mudou_vida.emit(vida.current_amount, vida.max_amount)
			slot_data["quantidade"] -= 1
			if slot_data["quantidade"] <= 0: inventario[indice] = null
			mudou_inventario()

	elif item.tipo == "arma":
		if is_weapon_equipped and arma_equipada_ref == item:
			desequipar_arma()
		else:
			is_weapon_equipped = true
			weapon_drawn = false # <--- VOLTOU AQUI: Começa guardada!
			arma_equipada_ref = item 
			atualizar_visual_armas()
		var inv_ui = get_tree().get_first_node_in_group("ui_inventario")
		if inv_ui: inv_ui.fechar()

#==============================================================================#
# MOVIMENTO E ANIMAÇÃO
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
	var blend_pos = 0.0
	
	if vel_horizontal > 0.1:
		blend_pos = vel_horizontal / velocidade_corrida 
	
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
# NOVO SISTEMA DE DASH (Substitui Rolada)
#==============================================================================#

func executar_dash():
	if is_dashing: return
	
	is_dashing = true
	
	# 1. DIREÇÃO: Baseada na Câmera
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		var camera_rotation_y = $CameraRoot/CameraHorizontal.global_rotation.y
		direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rotation_y).normalized()
		# Gira o corpo visualmente para a direção do dash
		$corpo.rotation.y = atan2(direction.x, direction.z)
	else:
		# Se não apertar nada, dash para frente (para onde o corpo está olhando)
		direction = $corpo.global_transform.basis.z 

	# 2. FÍSICA EXPLOSIVA
	velocity = direction * dash_speed
	
	# 3. ANIMAÇÃO (Dispara o nó que você configurou na AnimationTree)
	# Isso vai tocar a animação de "Strafe" por cima de tudo
	animation_tree.set("parameters/OneShot_Dash/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	# 4. EFEITOS VISUAIS (Bolha + Inclinação em Pé)
	#if dash_bubble:
	#	dash_bubble.visible = 
	#	dash_bubble.scale = Vector3(1, 1, 1) # Reinicia tamanho
	#	
	var tween = create_tween().set_parallel(true)
	#	
	#	# A bolha cresce rápido
	#	tween.tween_property(dash_bubble, "scale", Vector3(2.5, 2.5, 2.5), 0.2)
		
		# --- EFEITO NIER EM PÉ ---
		# Apenas inclina o tronco 15 graus para frente (Aerodinâmica)
		# Não mexemos na position.y, então ele desliza em pé!
	#	tween.tween_property($corpo, "rotation:x", deg_to_rad(-15), 0.1) 
		
	if camera_principal:
		tween.tween_property(camera_principal, "fov", 90.0, 0.1) # Zoom Out (Warp)
	
	# 5. TEMPO (Duração do Dash)
	await get_tree().create_timer(dash_duration).timeout
	
	# 6. RESET E LIMPEZA
	#if dash_bubble:
	#	dash_bubble.visible = false
		
	# Volta a inclinação e a câmera ao normal suavemente
	var tween_volta = create_tween().set_parallel(true)
	tween_volta.tween_property($corpo, "rotation:x", 0.0, 0.2) 
	
	if camera_principal:
		tween_volta.tween_property(camera_principal, "fov", 75.0, 0.2)

	velocity = Vector3.ZERO # Para o movimento
	is_dashing = false
	if is_dashing: return
	
	is_dashing = true
	
	# 1. DIREÇÃO: Baseada na Câmera
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		var camera_rotation_y = $CameraRoot/CameraHorizontal.global_rotation.y
		direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rotation_y).normalized()
		# Gira o corpo visualmente
		$corpo.rotation.y = atan2(direction.x, direction.z)
	else:
		# Se não apertar nada, dash para onde o corpo está olhando
		direction = $corpo.global_transform.basis.z 

	# 2. FÍSICA EXPLOSIVA
	velocity = direction * dash_speed
	
	# 3. EFEITOS VISUAIS (BOLHA + FOV)
	#if dash_bubble:
	#	dash_bubble.visible = true
	#	dash_bubble.scale = Vector3(1, 1, 1) # Reinicia tamanho
		
	#var tween = create_tween().set_parallel(true)
		#tween.tween_property(dash_bubble, "scale", Vector3(1.0, 1.0, 1.0), 0.2) # Bolha cresce
		
	if camera_principal:
		tween.tween_property(camera_principal, "fov", 90.0, 0.1) # Zoom Out
	
	# 4. TEMPO
	await get_tree().create_timer(dash_duration).timeout
	
	# 5. RESET
	if dash_bubble:
		dash_bubble.visible = false
		
	if camera_principal:
		tween_volta = create_tween()
		tween_volta.tween_property(camera_principal, "fov", 75.0, 0.2) # Zoom Volta

	velocity = Vector3.ZERO
	is_dashing = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	pass
