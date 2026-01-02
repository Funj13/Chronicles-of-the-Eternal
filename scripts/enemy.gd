extends CharacterBody3D

# --- CONFIGURAÇÕES ---
@export var vida_maxima: int = 100
@export var velocidade: float = 2.5
@export var dano_empurrao: float = 8.0
@export var distancia_visao: float = -5.0
@export var distancia_ataque: float = 2.0
@export var angulo_visao: float = 90.0

# Debug simples
@export var debug_visao: bool = true
@export var debug_print_cada_n_frames: int = 15

# --- REFERÊNCIAS ---
@onready var anim_player = $zombie/AnimationPlayer
@onready var texto_vida = $Label3D
@onready var olho: RayCast3D = $zombie/GeneralSkeleton/Head/Olho
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

# --- ESTADOS INTERNOS ---
var player: Node3D = null
var vida_atual: int = 0
var gravidade = ProjectSettings.get_setting("physics/3d/default_gravity")
var esta_morto = false
var esta_ferido = false
var esta_atacando = false

func _ready():
	vida_atual = vida_maxima
	atualizar_vida_visual()

	# Ajuda a evitar colidir com o próprio inimigo. [web:1]
	olho.exclude_parent = true
	olho.enabled = true
	
	olho.debug_shape_thickness = 6
	olho.debug_shape_custom_color = Color(1, 0, 0, 1) # vermelho


func _physics_process(delta):
	if esta_morto: return

	# Gravidade
	if not is_on_floor():
		velocity.y -= gravidade * delta

	player = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		parar()
		move_and_slide()
		return

	var viu = viu_player_no_raycast()

	# Debug (console)
	if debug_visao and (Engine.get_physics_frames() % debug_print_cada_n_frames == 0):
		print("Ray viu player? ", viu, " | colidindo: ", olho.is_colliding())

	if viu:
		# Só persegue se o RayCast acertou o player
		navigation_agent_3d.target_position = player.global_position

		var current_location = global_position
		var next_location = navigation_agent_3d.get_next_path_position()
		var new_velocity = (next_location - current_location).normalized() * velocidade

		velocity.x = new_velocity.x
		velocity.z = new_velocity.z
		tocar_animacao("zombie_walk/Walk")
	else:
		parar()

	move_and_slide()

func viu_player_no_raycast() -> bool:
	olho.target_position = Vector3(0, 0, -distancia_visao) # em vez de -3
	olho.force_raycast_update() # atualiza no mesmo frame [page:2]

	if not olho.is_colliding():
		return false

	var col = olho.get_collider() # [page:2]
	return (col is Node and (col as Node).is_in_group("player"))


func parar():
	velocity.x = move_toward(velocity.x, 0, velocidade)
	velocity.z = move_toward(velocity.z, 0, velocidade)
	tocar_animacao("zombie_idle/Idle")

func tocar_animacao(nome_anim: String):
	if anim_player and anim_player.current_animation != nome_anim:
		if anim_player.has_animation(nome_anim):
			anim_player.play(nome_anim, 0.2)

func atualizar_vida_visual():
	if texto_vida:
		texto_vida.text = str(vida_atual) + "/" + str(vida_maxima)
	
