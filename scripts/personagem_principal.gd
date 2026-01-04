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

# DASH / ROLAMENTO
@export var velocidade_rolamento = 6.0
var is_rolling := false 

# VIDA
@onready var vida: GameResource = $Health

# COMBATE & COMBO
var combo_count = 0
var timer_combo_window = 0.0 
var is_attacking = false
var in_attack_cooldown := false 
var arma_equipada_ref: ItemData = null # Guarda qual item está na mão

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
var was_on_floor := true

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
	
	# INICIALIZAÇÃO DA UI VIA SINAIS
	# Esperamos um frame para garantir que a UI carregou
	await get_tree().process_frame
	
	# Atualiza a barra de vida imediatamente ao iniciar
	# (Assumindo que seu recurso vida tem max_amount, se não tiver, use 100)
	var vida_max = 100
	if "max_amount" in vida:
		vida_max = vida.max_amount
		
	mudou_vida.emit(vida.current_amount, vida_max)
	
	# Garante visual das armas
	atualizar_visual_armas()
	
	# Inicializa a mochila com 20 espaços vazios (null)
	inventario.resize(20)

func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# Lógica de Tempo do Combo
	if combo_count > 0:
		timer_combo_window += delta
		if timer_combo_window > 1.5:
			combo_count = 0
			timer_combo_window = 0
			is_attacking = false

	# Processamento de ações
	if not is_rolling:
		handle_landing()
		handle_actions() 
		handle_combat_input() 
		handle_movement() 
	else:
		move_and_slide() 

	move_and_slide() 
	
	update_animation_parameters()
	was_on_floor = is_on_floor()
	


func _input(event):
	# Rolamento
	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling:
		handle_roll_action()
		
	# Debug de Dano
	if Input.is_action_just_pressed("Suicidy"):
		receber_dano(10)

	# Teste de Inventário (Tecla T)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		is_weapon_equipped = not is_weapon_equipped
		weapon_drawn = false 
		atualizar_visual_armas()
		print("Simulação: Arma equipada? ", is_weapon_equipped)
		
	# Interação (Botão E)
	if event.is_action_pressed("interact"):
		tentar_interagir()

	# ==================================================================
	# LÓGICA DE UI (INVENTÁRIO E PAUSE) - VERSÃO FINAL
	# ==================================================================
	# Verifica se apertou ESC ou a ação de pause
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		
		# 1. PRIORIDADE MÁXIMA: O INVENTÁRIO
		# Tenta achar quem tem a etiqueta "ui_inventario"
		var inventario = get_tree().get_first_node_in_group("ui_inventario")
		
		# Se achou e ele está ABERTO, fecha ele e encerra por aqui.
		if inventario and inventario.visible:
			inventario.fechar()
			get_viewport().set_input_as_handled() # Diz pro Godot: "Já resolvi, não espalha"
			return # <--- O PARE!
			
		# 2. PRIORIDADE SECUNDÁRIA: O MENU DE PAUSE
		# Se chegou aqui, é porque o inventário estava fechado.
		# Agora tenta achar quem tem a etiqueta "ui_pause"
		var menu_pause = get_tree().get_first_node_in_group("ui_pause")
		
		if menu_pause:
			# Chama a função de abrir/fechar do seu script de pause
			menu_pause.toggle_pause_menu()
			get_viewport().set_input_as_handled()
		else:
			print("ERRO: Não encontrei o nó do Pause com o grupo 'ui_pause'")	# Rolamento
	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling:
		handle_roll_action()
		
	# Debug de Dano
	if Input.is_action_just_pressed("Suicidy"):
		receber_dano(10)

	# Teste de Inventário (Tecla T)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		is_weapon_equipped = not is_weapon_equipped
		weapon_drawn = false 
		atualizar_visual_armas()
		print("Simulação de Inventário: Arma equipada? ", is_weapon_equipped)
		
	# Interação (Botão E)
	if event.is_action_pressed("interact"):
		tentar_interagir()


		# 3. Se não tinha inventário, aí sim abre o Menu de Pause
		if has_node("M"): 
			get_node("/root/World/Overlay/MenuPause").toggle_pause_menu()
		elif has_node("/root/world/Overlay/MenuPause"):
			get_node("/root/world/Overlay/MenuPause").toggle_pause_menu()			
			
func tentar_interagir():
	if raycast_interacao.is_colliding():
		var objeto = raycast_interacao.get_collider()
		if objeto.has_method("interagir"):
			print("Encontrei um objeto interagível: ", objeto.name)
			objeto.interagir(self) 


#==============================================================================#
# DESCER E SUBIR ESCADAS
#==============================================================================#
func _snap_down_to_stairs():
	pass
	
var _was_on_floor_last_frame = false
var _snapped_to_stairs_last_frame = false
func _snap_down_to_stairs_check():
	var did_snap = false
	if not is_on_floor() and velocity.y <= 0 and (_was_on_floor_last_frame or _snapped_to_stairs_last_frame) and $StairsBelowRayCast3D.is_colliding():
		var body_test_result = PhysicsTestMotionResult3D.new()
		var params = PhysicsTestMotionParameters3D.new()
		var max_step_down = -0.5
		params.from = self.global_transform
		params.motion = Vector3(0,max_step_down,0)
		if PhysicsServer3D.body_test_motion(self.get_rid(), params, body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true

	_was_on_floor_last_frame = is_on_floor()
	_snapped_to_stairs_last_frame = did_snap

#==============================================================================#
# COMBATE E AÇÕES
#==============================================================================#

func handle_combat_input():
	if not is_weapon_equipped:
		return

	if Input.is_action_just_pressed("equip_toggle"):
		weapon_drawn = not weapon_drawn
		atualizar_visual_armas()
	
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

func desequipar_arma():
	# Só faz sentido desequipar se tiver algo equipado
	if is_weapon_equipped:
		print("Desequipando arma...")
		is_weapon_equipped = false
		weapon_drawn = false
		
		arma_equipada_ref = null # <--- LIMPA A MEMÓRIA
		
		atualizar_visual_armas()
		
func realizar_ataque_combo():
	if in_attack_cooldown:
		return

	if combo_count == 0:
		animation_tree.set("parameters/OneShot_Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	combo_count += 1
	timer_combo_window = 0 
	is_attacking = true
	
	# Controle da animação na State Machine
	if combo_count == 1:
		state_machine_combo.travel("Atk1")
	elif combo_count == 2:
		state_machine_combo.travel("Atk2")
	elif combo_count >= 3:
		state_machine_combo.travel("Atk3")
		combo_count = 0 

	in_attack_cooldown = true
	
	# --- AQUI ESTÁ O SEGREDO DO DANO ---
	# Liga a hitbox logo depois de começar a animação (0.1s de atraso para sincronizar com o 'swing')
	await get_tree().create_timer(0.1).timeout
	toggle_hitbox(true)
	
	# Deixa a hitbox ligada durante o golpe (0.3s)
	await get_tree().create_timer(0.3).timeout
	toggle_hitbox(false)
	# -----------------------------------
	
	in_attack_cooldown = false

# --- NOVA FUNÇÃO DE CONTROLE DA HITBOX ---
func toggle_hitbox(ligar: bool):
	# Se a hitbox não existir ou o caminho estiver errado, avisa no erro
	if not hitbox_espada:
		push_error("ERRO: Hitbox da espada não encontrada no Player!")
		return
	
	hitbox_espada.monitoring = ligar
	
	# Debug visual 
	print("Hitbox Ligada: ", ligar)


# === DANO ===
func receber_dano(quantidade: int):
	vida.decrease(quantidade)
	print("Vida atual: ", vida.current_amount)
	
	#SE O VALOR FOR NULL ELE MUDA PARA 100
	var max_v = 100
	if "max_amount" in vida:
		max_v = vida.max_amount
	
	mudou_vida.emit(vida.current_amount, max_v)

func _on_vida_zerada():
	print("Você morreu!")
	get_tree().reload_current_scene()

#==============================================================================#
# PROGRESSÃO (XP / OURO)
#==============================================================================#

func ganhar_xp(quantidade: int):
	xp_atual += quantidade
	mudou_xp.emit(xp_atual, xp_proximo_nivel) 
	
	if xp_atual >= xp_proximo_nivel:
		subir_nivel()
		
func subir_nivel():
	level += 1
	xp_atual = xp_atual - xp_proximo_nivel
	xp_proximo_nivel = int(xp_proximo_nivel * 1.5)
	
	atributos["forca"] += 2
	atributos["agilidade"] += 1
	
	# Cura e Aumenta Vida Máxima
	if "max_amount" in vida:
		vida.max_amount += 20 
		vida.current_amount = vida.max_amount
		# Atualiza UI de vida também!
		mudou_vida.emit(vida.current_amount, vida.max_amount)
	
	mudou_nivel.emit(level)
	mudou_xp.emit(xp_atual, xp_proximo_nivel) 
	print("LEVEL UP! Você alcançou o nível ", level, "!")

func receber_ouro(quantidade: int):
	ouro += quantidade
	mudou_ouro.emit(ouro)
	print("Tintim! Recebeu ", quantidade, " moedas de ouro. Total: ", ouro)

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

#==============================================================================#
# ANIMAÇÃO
#==============================================================================#

func update_animation_parameters():
	var vel_horizontal = Vector2(velocity.x, velocity.z).length()
	var blend_pos = 0.0
	
	
	if vel_horizontal > 0.1:
		blend_pos = vel_horizontal / velocidade_corrida 
	
	# 1. LOCOMOÇÃO
	var anim_blend = Vector2(0, -1.0 if vel_horizontal > 0.1 else 0)
	if Input.is_action_pressed("sprint"): anim_blend.y = -2.0
	
	animation_tree.set("parameters/Locomocao/blend_position", anim_blend)



	# Calcula a intensidade do movimento para a postura de arma
	# Se vel > 0.1, vai para 1.0 (Walk). Se parado, vai para 0.0 (Idle).
	var weapon_move_blend = clamp(vel_horizontal / velocidade_andar, 0.0, 1.0)
	
	# Envia para o novo BlendSpace que criamos
	animation_tree.set("parameters/Weapon_Movement/blend_position", weapon_move_blend)
	
	# ========================
	# 2. POSTURA DE ARMA (Blend2)
	# Mistura visualmente os braços
	var target_blend = 1.0 if weapon_drawn else 0.0
	var current_blend = animation_tree.get("parameters/Posture_Weapon/blend_amount")
	animation_tree.set("parameters/Posture_Weapon/blend_amount", lerp(current_blend, target_blend, 0.1))

	# 3. ESTADOS DE MOVIMENTO
	animation_tree.set("parameters/Jump_Blender/blend_amount", 0.0 if is_on_floor() else 1.0)
	animation_tree.set("parameters/Crouch_Blender/blend_amount", 1.0 if is_crouching else 0.0)
	animation_tree.set("parameters/Air_Velocity_Blender/blend_amount", 1.0 if velocity.y < 0 else 0.0)

func handle_landing():
	if not was_on_floor and is_on_floor():
		animation_tree.set("parameters/Landing_OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func handle_roll_action():
	is_rolling = true
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		var camera_rotation_y = $CameraRoot/CameraHorizontal.global_rotation.y
		direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_rotation_y).normalized()
		$corpo.rotation.y = atan2(direction.x, direction.z)
	else:
		direction = $corpo.global_transform.basis.z 

	animation_tree.set("parameters/OneShot_Roll/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	velocity = direction * velocidade_rolamento
	
	var tween = create_tween()
	tween.tween_property(self, "velocity", Vector3.ZERO, 0.8) 
	
	await get_tree().create_timer(0.8).timeout
	is_rolling = false

#==============================================================================#
# HITBOXES
#==============================================================================#

func _on_hitbox_espada_area_entered(area: Area3D):
	if area.is_in_group("inimigos_hurtbox"):
		var inimigo = area.owner
		if inimigo.has_method("receber_dano"):
			inimigo.receber_dano(25)

# Função para adicionar item ao inventário
func adicionar_item(item_novo: ItemData, qtd: int = 1) -> bool:
	# 1. Tenta EMPILHAR (Se o item permitir)
	if item_novo.empilhavel:
		for i in range(inventario.size()):
			# Verifica se o slot não é null E se o item é igual ao novo
			if inventario[i] != null and inventario[i]["item"] == item_novo:
				inventario[i]["quantidade"] += qtd
				print("Adicionado +", qtd, " ao slot ", i)
				mudou_inventario() # Função auxiliar (veja abaixo)
				return true

	# 2. Se não empilhou, procura slot VAZIO
	for i in range(inventario.size()):
		if inventario[i] == null:
			# Cria o Dicionário (O Pacote)
			inventario[i] = {
				"item": item_novo,
				"quantidade": qtd
			}
			print("Novo item no slot ", i)
			mudou_inventario()
			return true
	
	print("Mochila Cheia!")
	return false

# Adicione essa função auxiliarzinha pra facilitar a vida da UI
func mudou_inventario():
	# Se a UI estiver ouvindo, avisa ela (opcional, mas bom pra atualizar em tempo real)
	var ui = get_tree().get_first_node_in_group("ui_inventario")
	if ui and ui.visible:
		ui.atualizar_grid()

func usar_item_do_inventario(indice):
	var slot_data = inventario[indice]
	if slot_data == null: return
	
	var item = slot_data["item"]
	
	# --- USO DE POÇÃO ---
	if item.tipo == "consumivel":
		# ... (seu código de poção que já funciona) ...
		if vida.current_amount < vida.max_amount:
			vida.increase(item.valor_efeito)
			mudou_vida.emit(vida.current_amount, vida.max_amount)
			slot_data["quantidade"] -= 1
			if slot_data["quantidade"] <= 0:
				inventario[indice] = null
			mudou_inventario()

	# --- USO DE ARMA (EQUIPAR) ---
	elif item.tipo == "arma":
		# VERIFICAÇÃO INTELIGENTE:
		# Se já tenho uma arma equipada E ela é igual a que cliquei agora...
		if is_weapon_equipped and arma_equipada_ref == item:
			# ...então guarda ela!
			desequipar_arma()
			
		else:
			# Caso contrário (ou estou desarmado, ou é uma espada diferente), EQUIPA!
			print("Equipando: ", item.nome)
			is_weapon_equipped = true
			weapon_drawn = false 
			
			arma_equipada_ref = item # <--- GUARDA NA MEMÓRIA QUEM É ELA
			
			atualizar_visual_armas()
			
			# Opcional: Tocar um som de 'bainha' aqui
		
		# (Opcional) Fechar o inventário ao equipar para ver o resultado
		var inv_ui = get_tree().get_first_node_in_group("ui_inventario")
		if inv_ui: inv_ui.fechar()
