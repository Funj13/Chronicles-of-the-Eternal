extends Node3D

@onready var spawn_point = $SpawnPoint
@onready var hud_overlay = $Overlay

func _ready():
	spawnar_player()
	
	# Se o save tiver uma posição salva (diferente de zero), move o player pra lá
	# Se for Novo Jogo, GameData.player_position será (0,0,0) ou o valor padrão
	if GameData.player_position != Vector3.ZERO:
		# Precisamos achar o player que acabamos de criar.
		# Como ele é filho da cena, podemos buscar pelo grupo ou pegar o último filho.
		# O jeito mais seguro é guardar a referência na função spawnar:
		pass 

func spawnar_player():
	# 1. Pega a escolha do GameData
	var choice = GameData.selected_character
	
	# Segurança: Se por algum motivo estiver vazio, força o "Boy"
	if choice == "":
		choice = "Boy"
	
	# 2. Pega o caminho do arquivo na lista do GameData
	var path = GameData.CHAR_SCENES[choice]
	
	# 3. Carrega a cena do HD para a memória
	var player_scene = load(path) # <--- FALTAVA ISSO!
	
	# 4. Cria a cópia (instância) para colocar no jogo
	var player_instance = player_scene.instantiate()
	
	# 5. Adiciona na árvore do jogo
	add_child(player_instance)
	
	# 6. LÓGICA DE POSICIONAMENTO (Save System)
	if GameData.player_position != Vector3.ZERO:
		# Se tem posição salva, usa ela
		player_instance.global_position = GameData.player_position
		
		# (Opcional) Reseta para evitar bugs se voltar pro menu sem salvar
		# GameData.player_position = Vector3.ZERO 
	else:
		# Se é novo jogo, usa o SpawnPoint original
		player_instance.global_position = spawn_point.global_position

	# Mostra o HUD de vida
	if hud_overlay:
		hud_overlay.visible = true
	
	print("Personagem criado com sucesso: ", choice)

# --- SISTEMA DE SAVE TEMPORÁRIO (Tecla F5) ---
func _input(event):
	if event.is_action_pressed("save_game"): # Ou crie um Input Map "save_game" na tecla F5
		salvar_estado_atual()

func salvar_estado_atual():
	# 1. Encontra o player na cena
	# (Assumindo que o nome do nó seja "PlayerBoy" ou "PlayerGirl" ou tenha um grupo "Player")
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# 2. Atualiza o GameData com a posição atual dele
		GameData.player_position = player.global_position
		
		# 3. Manda salvar no arquivo
		GameData.save_game()
		print("Jogo Salvo na posição: ", player.global_position)
