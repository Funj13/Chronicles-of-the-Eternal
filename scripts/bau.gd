extends Interagivel

@onready var mesh = $MeshInstance3D
var esta_aberto = false


# --- CONFIGURAÇÃO DO BAÚ ---
@export var item_recompensa: ItemData 
@export var quantidade_recompensa: int = 1
@export var ouro_recompensa: int = 100   # <--- Volta o Ouro (editável no inspetor)
@export var xp_recompensa: int = 50      # <--- Bônus: XP também!

func interagir(player):
	if not esta_aberto:
		abrir(player)

func abrir(player):
	esta_aberto = true
	mesh.scale.y = 0.5 
	
	print("--- Baú Aberto ---")
	
	# 1. ENTREGA O OURO
	if ouro_recompensa > 0:
		player.receber_ouro(ouro_recompensa)
		# Se tiver função de XP no player, descomente abaixo:
		# player.ganhar_xp(xp_recompensa) 
		print("Ouro recebido: ", ouro_recompensa)

	# 2. ENTREGA O ITEM (Lógica que já fizemos)
	if item_recompensa:
		var pegou = player.adicionar_item(item_recompensa, quantidade_recompensa)
		if pegou:
			print("Item recebido: ", quantidade_recompensa, "x ", item_recompensa.nome)
		else:
			print("Mochila cheia! O item caiu no chão (Lógica futura)")
