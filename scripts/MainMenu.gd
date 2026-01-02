extends Control

func _on_btn_boy_pressed():
	# Salva a escolha na variável global
	GameData.selected_character = "Boy"
	iniciar_jogo()

func _on_btn_girl_pressed():
	# Salva a escolha na variável global
	GameData.selected_character = "Girl"
	iniciar_jogo()

func iniciar_jogo():
	# Troca para a cena do mapa
	get_tree().change_scene_to_file("res://Level/World.tscn")
