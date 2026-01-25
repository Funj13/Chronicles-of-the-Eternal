extends Node3D # Já que você usou um Node3D

# Arraste o nó "FaceAnimationPlayer" para cá no Inspector
@export var anim_player: AnimationPlayer 



var timer_piscar = Timer.new()
var expressao_atual = "neutral"

func _ready():
	# Configura o timer interno de piscar
	add_child(timer_piscar)
	timer_piscar.wait_time = randf_range(2.0, 4.0)
	timer_piscar.one_shot = true
	timer_piscar.timeout.connect(_on_blink_timer)
	timer_piscar.start()
	
	# Garante que o rosto comece neutro
	mudar_expressao("neutral")

func _on_blink_timer():
	# Só pisca se a cara estiver "limpa" (sem dor ou ataque)
	if expressao_atual == "neutral" or expressao_atual == "relaxed":
		if anim_player and anim_player.has_animation("blink"):
			anim_player.play("blink", 0.1)
			# O blink geralmente é rápido, então não precisamos forçar a volta
	
	# Agenda a próxima piscada
	timer_piscar.wait_time = randf_range(2.0, 6.0)
	timer_piscar.start()

# Essa é a função que o Player vai chamar
func mudar_expressao(nome_anim: String):
	if not anim_player or not anim_player.has_animation(nome_anim): 
		return
	
	expressao_atual = nome_anim
	anim_player.play(nome_anim, 0.2)
	
	# Se for expressão temporária (dor/esforço), volta ao normal depois
	if nome_anim != "neutral" and nome_anim != "relaxed":
		# Cria um timer descartável para voltar
		await get_tree().create_timer(1.0).timeout
		voltar_neutro()

func voltar_neutro():
	expressao_atual = "neutral"
	if anim_player and anim_player.has_animation("neutral"):
		anim_player.play("neutral", 0.5)
