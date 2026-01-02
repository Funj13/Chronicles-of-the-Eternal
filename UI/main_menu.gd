
extends Control

# --- REFERÊNCIAS VISUAIS ---
@onready var menu_inicial = $MenuInicial_Container
@onready var criar_save_panel = $CriarSave_Panel
@onready var loading_screen = $LoadingScreen
@onready var progress_bar = $LoadingScreen/ProgressBar
@onready var input_nome = $CriarSave_Panel/menu_organizator/InputNome

# --- BOTÕES DE SELEÇÃO (Para destacar qual foi escolhido) ---
@onready var btn_boy = $CriarSave_Panel/menu_organizator/HBoxContainer/BtnBoy
@onready var btn_girl = $CriarSave_Panel/menu_organizator/HBoxContainer/BtnGirl

# Referências DA TELA DE CARREGAR SAVE
@onready var carregar_panel = $CarregarJogo_Panel # Verifique o nome na árvore!
@onready var btn_slot_1 = $CarregarJogo_Panel/ListaSaves/BtnSlot1
@onready var btn_slot_2 = $CarregarJogo_Panel/ListaSaves/BtnSlot2
@onready var btn_slot_3 = $CarregarJogo_Panel/ListaSaves/BtnSlot3

# --- VARIÁVEIS DE LÓGICA ---
var scene_path = "res://world.tscn"
var is_loading = false
var progress_array = []
var personagem_selecionado: String = "" # Começa vazio

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Estado inicial: Mostra Menu Principal, Esconde o resto
	menu_inicial.visible = true
	criar_save_panel.visible = false
	loading_screen.visible = false
	carregar_panel.visible = false
	
	# Reseta transparências
	loading_screen.modulate.a = 0.0
	menu_inicial.modulate.a = 1.0

# ==========================================
# PARTE 1: NAVEGAÇÃO DO MENU (Abrir/Fechar Janelas)
# ==========================================

# Sair do Jogo
func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_btn_novo_jogo_pressed():
	# Esconde menu principal, mostra tela de criar save
	menu_inicial.visible = false
	criar_save_panel.visible = true
	
	# Reseta a seleção
	personagem_selecionado = ""
	input_nome.text = "" 
	_atualizar_visual_selecao() # Tira o destaque dos botões

func _on_loading_pressed() -> void:
	# Em vez de carregar direto, vamos abrir o menu de slots
	
	# 1. Troca visual (Esconde menu principal, mostra painel de slots)
	menu_inicial.visible = false
	carregar_panel.visible = true
	
	# 2. Atualiza os textos dos botões (para mostrar quem está salvo em cada slot)
	atualizar_botoes_slots()
	
	
		
func _on_btn_voltar_pressed():
	# Cancela e volta pro menu principal
	criar_save_panel.visible = false
	menu_inicial.visible = true
	carregar_panel.visible = false

func _on_btn_sair_pressed():
	get_tree().quit()

# ==========================================
# PARTE 2: SELEÇÃO DE PERSONAGEM
# ==========================================

func _on_btn_boy_pressed():
	personagem_selecionado = "Boy"
	_atualizar_visual_selecao()

func _on_btn_girl_pressed():
	personagem_selecionado = "Girl"
	_atualizar_visual_selecao()

func _atualizar_visual_selecao():
	# Aqui você pode mudar a cor ou borda do botão para mostrar qual está marcado
	# Exemplo simples: Mudar a cor do texto ou opacidade
	if personagem_selecionado == "Boy":
		btn_boy.modulate = Color(1, 1, 1, 1) # Aceso
		btn_girl.modulate = Color(0.5, 0.5, 0.5, 1) # Apagado
	elif personagem_selecionado == "Girl":
		btn_boy.modulate = Color(0.5, 0.5, 0.5, 1)
		btn_girl.modulate = Color(1, 1, 1, 1)
	else:
		# Nenhum selecionado
		btn_boy.modulate = Color(1, 1, 1, 1)
		btn_girl.modulate = Color(1, 1, 1, 1)




# ==========================================
# PARTE 3: CARREGAR SAVE DO JOGO
# ==========================================



# --- BOTÃO DO MENU PRINCIPAL "CARREGAR" ---
func _on_btn_carregar_pressed():
	# 1. Esconde menu, mostra tela de slots
	menu_inicial.visible = false
	carregar_panel.visible = true
	
	# 2. Atualiza o texto dos botões lendo os arquivos
	atualizar_botoes_slots()

# --- ATUALIZA A LISTA VISUAL ---
func atualizar_botoes_slots():
	configurar_botao_slot(btn_slot_1, 1)
	configurar_botao_slot(btn_slot_2, 2)
	configurar_botao_slot(btn_slot_3, 3)

func configurar_botao_slot(btn: Button, slot_id: int):
	var info = GameData.get_slot_info(slot_id)
	
	if info == null:
		btn.text = "Slot " + str(slot_id) + " - Vazio"
		# Dica: Deixe o botão meio transparente ou cinza se estiver vazio
		btn.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		# Mostra: "Slot 1: Arthur (Cavaleiro) - 2025-12-28"
		var texto = "Slot " + str(slot_id) + ": " + info["player_name"]
		texto += " (" + info["selected_character"] + ")"
		btn.text = texto
		btn.modulate = Color(1, 1, 1, 1) # Aceso

# --- QUANDO CLICA NO SLOT ---
func _on_btn_slot_1_pressed():
	tenter_carregar_slot(1)

func _on_btn_slot_2_pressed():
	tenter_carregar_slot(2)

func _on_btn_slot_3_pressed():
	tenter_carregar_slot(3)

func tenter_carregar_slot(slot_id: int):
	# Tenta carregar usando a função nova do GameData
	if GameData.load_game(slot_id):
		# Se deu certo, inicia a transição bonita
		# Precisamos esconder o painel de load agora
		carregar_panel.visible = false
		_animar_transicao_loading()
	else:
		print("Slot Vazio!")
		# Aqui você pode tocar um som de erro

# ==========================================
# PARTE 4: INICIAR JOGO (O antigo "comecar_carregamento")
# ==========================================
func _on_btn_iniciar_jornada_pressed():
	# 1. Validação: O jogador escolheu alguém?
	if personagem_selecionado == "":
		print("Erro: Selecione um personagem!")
		# Dica: Você pode mudar a cor do Label de aviso aqui para vermelho
		return
	
	# Validação do Nome (Agora é obrigatório para o save ficar bonito)
	if input_nome.text == "":
		print("Erro: Digite um nome para o herói!")
		return 

	# 2. Passa os dados para o Cérebro Global (GameData)
	GameData.selected_character = personagem_selecionado
	GameData.player_name = input_nome.text # Salva o nome digitado
	
	# Zera a posição para garantir que o jogo novo comece no SpawnPoint
	# (Evita bugs se você jogou, voltou pro menu e clicou em novo jogo)
	GameData.player_position = Vector3.ZERO

	# 3. Define o Slot e Cria o Arquivo
	# Por enquanto forçamos o Slot 1. Futuramente você pode deixar escolher.
	GameData.current_save_slot = 1 
	
	# Salva AGORA. Assim, se o jogo fechar no loading, o save já existe.
	GameData.save_game()

	# 4. Começa a transição visual (Loading)
	_animar_transicao_loading()
	
func _animar_transicao_loading():
	# Bloqueia cliques
	criar_save_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Anima sumiço do painel de save
	var tween = create_tween()
	tween.tween_property(criar_save_panel, "modulate:a", 0.0, 0.5)
	await tween.finished
	criar_save_panel.visible = false
	
	# Anima entrada do loading
	loading_screen.visible = true
	var tween_load = create_tween()
	tween_load.tween_property(loading_screen, "modulate:a", 1.0, 0.5)
	await tween_load.finished
	
	# Inicia carregamento real
	ResourceLoader.load_threaded_request(scene_path)
	is_loading = true

func _process(_delta):
	if not is_loading: return
	
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress_array)
	if progress_array.size() > 0:
		progress_bar.value = progress_array[0] * 100
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		is_loading = false
		var nova_cena = ResourceLoader.load_threaded_get(scene_path)
		get_tree().change_scene_to_packed(nova_cena)

# --- BOTÃO VOLTAR (DA TELA DE CARREGAR) ---
func _on_btn_voltar_carregar_pressed():
	carregar_panel.visible = false
	menu_inicial.visible = true
