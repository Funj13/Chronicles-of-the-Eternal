extends CharacterBody3D

# --- CONFIGURAÇÕES ---
@export_group("Atributos")
@export var vida_maxima: int = 100
@export var velocidade: float = 2.5
@export var velocidade_patrulha: float = 1.5
@export var dano_empurrao: float = 8.0

@export_group("Combate")
@export var distancia_visao: float = 15.0
@export var distancia_ataque: float = 1.2 # Ajustei para ficar mais perto (era 2.5)
@export var angulo_visao: float = 90.0
@export var dano_ataque: int = 10
@export var cooldown_ataque: float = 2.0

@export_group("Patrulha")
@export var patrulhar: bool = true
@export var raio_patrulha: float = 10.0
@export var tempo_espera_patrulha: float = 3.0

@export_group("Comportamento/Animação")
@export var chance_susto: float = 0.4     # Chance de dar susto no Idle
@export var tempo_min_susto: float = 5.0
@export var tempo_max_susto: float = 10.0

@export_group("Debug")
@export var debug_visao: bool = true
@export var debug_print_cada_n_frames: int = 60

# --- REFERÊNCIAS ---
@onready var anim_player = $zombie/AnimationPlayer
@onready var texto_vida = $Label3D
@onready var olho: RayCast3D = $zombie/GeneralSkeleton/Head/Olho
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

# --- ESTADOS ---
enum Estado { IDLE, PATRULHA, PERSEGUINDO, ATACANDO }
var estado_atual: Estado = Estado.IDLE

# --- VARIÁVEIS INTERNAS ---
var player: Node3D = null
var vida_atual: int = 0
var gravidade = ProjectSettings.get_setting("physics/3d/default_gravity")
var esta_morto = false
var esta_ferido = false
var esta_fazendo_anim_especial = false # Para travar o Zumbi no Stop/Scary

# Ataque
var pode_atacar: bool = true

# Patrulha e Idle
var ponto_patrulha: Vector3
var posicao_inicial: Vector3
var timer_espera_patrulha: float = 0.0
var timer_susto: float = 0.0

func _ready():
	vida_atual = vida_maxima
	atualizar_vida_visual()
	posicao_inicial = global_position
	gerar_novo_ponto_patrulha()
	resetar_timer_susto()
	
	# Configuração do RayCast
	if olho:
		olho.exclude_parent = true
		olho.enabled = true
		olho.target_position = Vector3(0, 0, -distancia_visao)
		olho.debug_shape_thickness = 6
		olho.debug_shape_custom_color = Color(1, 0, 0, 1)
	
	# Aguarda setup da física
	await get_tree().physics_frame
	
	if patrulhar:
		mudar_estado(Estado.PATRULHA)
	else:
		mudar_estado(Estado.IDLE)

func _physics_process(delta):
	if esta_morto: return
	
	# 1. GRAVIDADE
	if not is_on_floor():
		velocity.y -= gravidade * delta
	
	# 2. STUN / DANO (Prioridade sobre movimento)
	if esta_ferido:
		# Fricção para ele não deslizar para sempre com o empurrão
		velocity.x = move_toward(velocity.x, 0, velocidade * delta * 2)
		velocity.z = move_toward(velocity.z, 0, velocidade * delta * 2)
		move_and_slide()
		return # Sai da função para não pensar nem atacar

	# Busca o player
	player = get_tree().get_first_node_in_group("player") as Node3D
	
	# Máquina de Estados
	match estado_atual:
		Estado.IDLE:
			processar_idle(delta)
		Estado.PATRULHA:
			processar_patrulha(delta)
		Estado.PERSEGUINDO:
			processar_perseguindo(delta)
		Estado.ATACANDO:
			processar_atacando(delta)
	
	move_and_slide()
	
	# Debug
	if debug_visao and (Engine.get_physics_frames() % debug_print_cada_n_frames == 0):
		print("Estado: ", Estado.keys()[estado_atual])

# ==================== ESTADOS ====================

func processar_idle(delta):
	# Se estiver fazendo animação especial (Stop ou Susto), espera acabar
	if esta_fazendo_anim_especial:
		velocity.x = move_toward(velocity.x, 0, velocidade * delta * 4) # Fricção forte
		velocity.z = move_toward(velocity.z, 0, velocidade * delta * 4)
		
		if not anim_player.is_playing():
			esta_fazendo_anim_especial = false # Destrava
		return

	parar()
	
	# Lógica do Susto (Scary)
	timer_susto -= delta
	if timer_susto <= 0:
		resetar_timer_susto()
		if randf() < chance_susto:
			tentar_tocar_susto()
	
	if player and verificar_cone_e_raycast():
		mudar_estado(Estado.PERSEGUINDO)
	elif patrulhar:
		mudar_estado(Estado.PATRULHA)

func processar_patrulha(delta):
	# Verifica se viu o player
	if player and verificar_cone_e_raycast():
		mudar_estado(Estado.PERSEGUINDO)
		return
	
	# Aguarda antes de ir para próximo ponto
	if timer_espera_patrulha > 0:
		timer_espera_patrulha -= delta
		processar_idle(delta) 
		return
	
	# --- MOVIMENTAÇÃO ---
	navigation_agent_3d.target_position = ponto_patrulha
	var distancia_ponto = global_position.distance_to(ponto_patrulha)
	
	if distancia_ponto < 1.0:
		# Chegou no ponto
		timer_espera_patrulha = tempo_espera_patrulha
		gerar_novo_ponto_patrulha()
		mudar_estado(Estado.IDLE) 
	else:
		mover_para_destino(velocidade_patrulha)
		
		# --- LÓGICA DA ANIMAÇÃO DE SAÍDA (INIT) ---
		var anim_init = "zombie_walk/Init_Walk" # Nome da animação de começar a andar
		var anim_walk = "zombie_walk/Walk"      # Nome do loop de andar
		
		# 1. Se já estamos tocando o loop de andar, mantém e ajusta velocidade
		if anim_player.current_animation == anim_walk:
			tocar_animacao(anim_walk, velocidade_patrulha / 1.5)
			
		# 2. Se estamos tocando a animação de INÍCIO (Init)
		elif anim_player.current_animation == anim_init:
			# Verifica se ela já terminou (is_playing fica false quando acaba se não tiver loop)
			if not anim_player.is_playing():
				tocar_animacao(anim_walk, velocidade_patrulha / 1.5)
				
		# 3. Se não estamos tocando nenhuma das duas (Vindo do Idle)
		else:
			tocar_animacao(anim_init)


func processar_perseguindo(delta):
	if not player:
		mudar_estado(Estado.IDLE)
		return
	
	var distancia = global_position.distance_to(player.global_position)
	
	if not verificar_cone_e_raycast():
		mudar_estado(Estado.IDLE if not patrulhar else Estado.PATRULHA)
		return
	
	if distancia <= distancia_ataque:
		mudar_estado(Estado.ATACANDO)
		return
	
	navigation_agent_3d.target_position = player.global_position
	mover_para_destino(velocidade)
	# Velocidade ajustada para corrida (Moonwalk fix)
	tocar_animacao("zombie_walk/Walk", velocidade / 1.2)

func processar_atacando(delta):
	if not player:
		mudar_estado(Estado.IDLE)
		return
	
	var distancia = global_position.distance_to(player.global_position)
	
	if distancia > distancia_ataque + 1.0:
		mudar_estado(Estado.PERSEGUINDO)
		return
	
	velocity.x = 0
	velocity.z = 0
	olhar_para_player()
	
	if pode_atacar:
		executar_ataque()

# ==================== FUNÇÕES AUXILIARES ====================

func mudar_estado(novo_estado: Estado):
	if estado_atual == novo_estado:
		return
	
	var estado_anterior = estado_atual
	
	# Transição: Se estava andando e parou, tenta tocar o STOP
	if novo_estado == Estado.IDLE and (estado_anterior == Estado.PERSEGUINDO or estado_anterior == Estado.PATRULHA):
		if anim_player.has_animation("zombie_walk/Stop"):
			print("🛑 Freando...")
			tocar_animacao("zombie_walk/Stop")
			esta_fazendo_anim_especial = true
	
	estado_atual = novo_estado
	
	match estado_atual:
		Estado.IDLE:
			resetar_timer_susto()
		Estado.PATRULHA:
			if estado_anterior != Estado.IDLE:
				gerar_novo_ponto_patrulha()
		Estado.ATACANDO:
			pode_atacar = true

func verificar_cone_e_raycast() -> bool:
	if not player: return false
	
	var distancia = global_position.distance_to(player.global_position)
	if distancia > distancia_visao: return false
	
	# 2. CONE (Ajuste conforme seu modelo, aqui mantive o -Z do seu código original)
	var frente = -global_transform.basis.z 
	frente.y = 0
	frente = frente.normalized()
	
	var para_player = (player.global_position - global_position).normalized()
	para_player.y = 0
	
	var dot = frente.dot(para_player)
	var limite_dot = cos(deg_to_rad(angulo_visao / 2.0))
	
	if dot < limite_dot: return false
	
	# 3. RAYCAST
	var alvo = player.global_position + Vector3(0, 1.5, 0)
	olho.look_at(alvo, Vector3.UP)
	olho.target_position = Vector3(0, 0, -distancia_visao)
	olho.force_raycast_update()
	
	if not olho.is_colliding(): return false
	
	var colisor = olho.get_collider()
	return (colisor is Node and (colisor as Node).is_in_group("player"))

func mover_para_destino(velocidade_movimento: float):
	var next_location = navigation_agent_3d.get_next_path_position()
	var direcao = (next_location - global_position).normalized()
	
	velocity.x = direcao.x * velocidade_movimento
	velocity.z = direcao.z * velocidade_movimento
	
	if direcao.length() > 0.01:
		var alvo_look = global_position + direcao
		# Suaviza a rotação para não ficar robótico
		var transform_alvo = transform.looking_at(alvo_look, Vector3.UP)
		transform.basis = transform.basis.slerp(transform_alvo.basis, 0.1)

func olhar_para_player():
	if not player: return
	var direcao = (player.global_position - global_position).normalized()
	direcao.y = 0
	if direcao.length() > 0.01:
		look_at(global_position + direcao, Vector3.UP)

func executar_ataque():
	pode_atacar = false
	
	# Lista de Ataques Aleatórios
	var ataques = ["zombie_attack/Attack", "zombie_attack/Kick", "zombie_attack/Headbutt"]
	var escolhido = ataques.pick_random()
	
	if anim_player.has_animation(escolhido):
		print("⚔️ Zumbi usou: ", escolhido)
		tocar_animacao(escolhido, 1.2) # Levemente mais rápido
	else:
		tocar_animacao("zombie_attack/Attack")
	
	if player and player.has_method("receber_dano"):
		player.receber_dano(dano_ataque)
	
	await get_tree().create_timer(cooldown_ataque).timeout
	pode_atacar = true

func tentar_tocar_susto():
	var anim_susto = "zombie_scream/Hit"
	if anim_player.has_animation(anim_susto):
		print("👻 Boo!")
		tocar_animacao(anim_susto)
		esta_fazendo_anim_especial = true

func gerar_novo_ponto_patrulha():
	var angulo = randf() * TAU
	var dist = randf_range(raio_patrulha * 0.5, raio_patrulha)
	ponto_patrulha = posicao_inicial + Vector3(cos(angulo) * dist, 0, sin(angulo) * dist)

func parar():
	velocity.x = move_toward(velocity.x, 0, velocidade)
	velocity.z = move_toward(velocity.z, 0, velocidade)
	tocar_animacao("zombie_idle/Idle")

func tocar_animacao(nome_anim: String, escala_velocidade: float = 1.0):
	if not anim_player: return
	
	if anim_player.current_animation != nome_anim:
		if anim_player.has_animation(nome_anim):
			# Blend de 0.2s para transição suave
			anim_player.play(nome_anim, 0.2, escala_velocidade)
	else:
		# Atualiza velocidade se já estiver tocando (corrige moonwalk em tempo real)
		anim_player.speed_scale = escala_velocidade

func resetar_timer_susto():
	timer_susto = randf_range(tempo_min_susto, tempo_max_susto)

func atualizar_vida_visual():
	if texto_vida:
		texto_vida.text = str(vida_atual) + "/" + str(vida_maxima)

# ==================== SISTEMA DE DANO ====================

func receber_dano(dano: int, posicao_atacante: Vector3 = Vector3.ZERO):
	if esta_morto: return
	
	vida_atual -= dano
	atualizar_vida_visual()
	
	if posicao_atacante != Vector3.ZERO:
		var empurrao = (global_position - posicao_atacante).normalized()
		empurrao.y = 0.5
		velocity = empurrao * dano_empurrao
	
	if vida_atual <= 0:
		morrer()
	else:
		aplicar_hit_reaction()

func aplicar_hit_reaction():
	esta_ferido = true
	esta_fazendo_anim_especial = false # Cancela qualquer susto/stop que estivesse rolando
	pode_atacar = false # Trava ataque
	
	var anim_hit = "zombie_reaction/Hit"
	if anim_player.has_animation(anim_hit):
		anim_player.play(anim_hit, 0.1, 1.5)
	
	await get_tree().create_timer(0.6).timeout
	esta_ferido = false
	pode_atacar = true
	
	# Se ainda ver o player, volta furioso
	if player and verificar_cone_e_raycast():
		mudar_estado(Estado.PERSEGUINDO)

func morrer():
	esta_morto = true
	texto_vida.visible = false
	$CollisionShape3D.set_deferred("disabled", true) # Desliga colisão
	
	tocar_animacao("zombie_death/Death")
	print("Inimigo Morreu!")
	
	await get_tree().create_timer(3.0).timeout
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	await tween.finished
	queue_free()
