extends Area3D

@export var dano: int = 20

func _ready():
	# Conecta o sinal de quando algo entra na área
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Verifica se o corpo que encostou tem a função de tomar dano
	if body.has_method("receber_dano"):
		print("Acertei o inimigo: ", body.name)
		body.receber_dano(dano, global_position)
