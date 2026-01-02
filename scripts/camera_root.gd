extends Node3D
# ====================================
# SISTEMA DE CÂMERA SIMPLES E FUNCIONAL (CORRIGIDO)
# Para usar com CameraRoot (Node3D)
# ====================================

@export var mouse_sensitivity: float = 0.003
@export var camera_distance_min: float = 0.5
@export var camera_distance_max: float = 4.0
@export var camera_distance: float = 1.0
@export var zoom_speed: float = 0.5
@export var rotation_speed: float = 10.0

@export var angle_min: float = -60.0
@export var angle_max: float = 70.0

@export var camera_locked := false
@export var lock_follow_speed := 8.0


# VARIÁVEIS INTERNAS

var mouse_rotation := Vector2.ZERO
var camera_rotation := Vector2.ZERO

# REFERÊNCIAS
@onready var h_node = $CameraHorizontal
@onready var v_node = $CameraHorizontal/CameraVertical
@onready var spring_arm = $CameraHorizontal/CameraVertical/SpringArm3D


func _ready():
	# Inicializa variáveis
	mouse_rotation = Vector2.ZERO
	camera_rotation = Vector2.ZERO
	
	# Captura o mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Configura a distância da câmera
	if spring_arm:
		spring_arm.spring_length = camera_distance
		# Exclui a personagem das colisões
		var player = get_parent()
		if player:
			spring_arm.add_excluded_object(player.get_rid())
	
	print("✅ Câmera inicializada!")

func _input(event):
	# MOVIMENTO DO MOUSE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		# Eixo Vertical (Cima/Baixo)
		mouse_rotation.x += event.relative.y * mouse_sensitivity
		
		# ## CORREÇÃO AQUI ##
		# Trocamos += por -= para inverter a direção horizontal
		mouse_rotation.y -= event.relative.x * mouse_sensitivity

		
		# Limita rotação vertical
		mouse_rotation.x = clamp(mouse_rotation.x, deg_to_rad(angle_min), deg_to_rad(angle_max))
	
	# ZOOM COM SCROLL
	if event is InputEventMouseButton and spring_arm:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance += zoom_speed
		
		camera_distance = clamp(camera_distance, camera_distance_min, camera_distance_max)
		spring_arm.spring_length = camera_distance
	
	# ESC PARA LIBERAR MOUSE
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("camera_lock"):
		camera_locked = !camera_locked


func _process(delta):
	if delta <= 0:
		return

	if camera_locked:
		var player := get_parent()
		if player:
			camera_rotation.y = lerp_angle(
				camera_rotation.y,
				player.global_rotation.y,
				lock_follow_speed * delta
			)
	else:
		camera_rotation = camera_rotation.lerp(
			mouse_rotation,
			clamp(rotation_speed * delta, 0.0, 1.0)
		)

	h_node.rotation.y = camera_rotation.y
	v_node.rotation.x = camera_rotation.x
