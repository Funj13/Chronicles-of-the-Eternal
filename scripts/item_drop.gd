extends Area3D

# O QUE TEM AQUI DENTRO?
var item_data: ItemData
var quantidade: int = 1

@onready var visual = $MeshInstance3D

func _ready():
	# Efeito visual: Faz o item flutuar e girar devagarzinho
	var tween = create_tween().set_loops()
	tween.tween_property(visual, "position:y", 0.2, 1.0).as_relative()
	tween.tween_property(visual, "position:y", -0.2, 1.0).as_relative()
	
	# Conecta o sinal de colisão via código (mais rápido que ir na aba Sinais)
	body_entered.connect(_on_body_entered)

# Função chamada por quem criou este drop (InventoryUI ou Inimigo)
func configurar(item: ItemData, qtd: int):
	item_data = item
	quantidade = qtd
	# Aqui você poderia mudar a cor da Mesh dependendo se é Raro ou Comum

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Tentando pegar do chão: ", item_data.nome)
		
		# Tenta devolver pra mochila
		var pegou = body.adicionar_item(item_data, quantidade)
		
		if pegou:
			# Toca um som aqui futuramente!
			queue_free() # Destrói o objeto do chão
