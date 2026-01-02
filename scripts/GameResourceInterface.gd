extends Control

# Não precisamos mais exportar o resource aqui, pois o Player vai nos avisar via sinal
# @export var resource: GameResource 

# REFERÊNCIAS VISUAIS
@onready var barra_vida := $TextureRect/Life_Bar # Renomeei para ficar padrão
@onready var label_ouro = $VBoxContainer/Gold_Label
@onready var label_nivel = $VBoxContainer/Label_Level
@onready var barra_xp = $VBoxContainer/XP_Bar

func _ready() -> void:
	# Espera um pouquinho para garantir que o player carregou na cena
	await get_tree().process_frame
	
	# Busca o player no grupo "player"
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("✅ UI: Conectada ao Player!")
		
		# Conecta os sinais de estatísticas
		player.mudou_ouro.connect(atualizar_ouro)
		player.mudou_xp.connect(atualizar_xp)
		player.mudou_nivel.connect(atualizar_nivel)
		
		# Conecta o sinal de VIDA (Novo)
		player.mudou_vida.connect(atualizar_vida)
		
		# --- ATUALIZAÇÃO INICIAL (Para não começar zerado) ---
		atualizar_ouro(player.ouro)
		atualizar_nivel(player.level)
		atualizar_xp(player.xp_atual, player.xp_proximo_nivel)
		
		# Pega a vida inicial direto do resource do player para preencher a barra agora
		if player.vida:
			# Verifica se tem max_amount, se não usa 100 como padrão
			var max_v = 100
			if "max_amount" in player.vida:
				max_v = player.vida.max_amount
			atualizar_vida(player.vida.current_amount, max_v)
	else:
		print("❌ UI ERRO: Player não encontrado no grupo 'player'")

# === FUNÇÕES QUE RECEBEM O SINAL ===

func atualizar_vida(valor_atual, valor_maximo):
	barra_vida.max_value = valor_maximo
	barra_vida.value = valor_atual

func atualizar_ouro(novo_valor):
	label_ouro.text = "💰 " + str(novo_valor)

func atualizar_nivel(novo_valor):
	label_nivel.text = "Nível: " + str(novo_valor)

func atualizar_xp(valor_atual, valor_maximo):
	barra_xp.max_value = valor_maximo
	barra_xp.value = valor_atual
