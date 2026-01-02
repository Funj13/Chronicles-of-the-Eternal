extends Control

func _ready():
	hide()
	# Garante que este menu funcione mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Captura o ESC (ui_cancel) diretamente aqui
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

# Função de alternar (Abrir/Fechar)
func toggle_pause_menu():
	visible = not visible
	get_tree().paused = visible # Se visível = true, pausa = true
	
	if visible:
		# Solta o mouse para clicar nos botões
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Prende o mouse de volta para o jogo
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# --- BOTÕES ---

func _on_continuar_button_pressed():
	toggle_pause_menu()

func _on_salvar_button_pressed():
	# Chama nosso sistema global de save
	GameData.save_game()
	print("Jogo salvo via Menu de Pause!")
	# Dica: Futuramente você pode fazer um Label aparecer escrito "Salvo!"

func _on_menu_principal_pressed():
	# MUITO IMPORTANTE: Despausar antes de trocar de cena!
	# Se não fizer isso, o Menu Principal carrega congelado.
	get_tree().paused = false
	
	# Troca para a cena do menu (verifique se o caminho está certo)
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")

func _on_sair_desktop_pressed():
	# Fecha o jogo (Windows)
	get_tree().quit()
