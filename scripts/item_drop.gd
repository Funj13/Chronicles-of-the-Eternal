extends Area3D

# O QUE TEM AQUI DENTRO?
var item_data: ItemData
var quantidade: int = 1

@onready var visual = $MeshInstance3D

func _ready():
	# Efeito visual: Faz o item flutuar e girar (Estilo Arcade)
	if visual:
		var tween = create_tween().set_loops()
		tween.tween_property(visual, "position:y", 0.2, 1.0).as_relative()
		tween.tween_property(visual, "position:y", -0.2, 1.0).as_relative()
	
	body_entered.connect(_on_body_entered)

func configurar(item: ItemData, qtd: int):
	item_data = item
	quantidade = qtd
	# Dica: Se quiser mudar a textura da mesh baseado no ícone:
	# if visual.material_override: visual.material_override.albedo_texture = item.icone

func _on_body_entered(body):
	# Verifica se é o player
	if body.is_in_group("player"):
		print("Tentando pegar do chão: ", item_data.nome)
		
		# --- CORREÇÃO IMPORTANTE AQUI ---
		# Mudamos de 'adicionar_item' para 'add_item' para bater com o Player novo
		if body.has_method("add_item"):
			var pegou = body.add_item(item_data, quantidade)
			
			if pegou:
				# Pode adicionar um som aqui: AudioStreamPlayer3D.play()
				queue_free() # Some com o item do chão
