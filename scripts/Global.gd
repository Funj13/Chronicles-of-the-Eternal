extends Node

func hit_stop(time_scale_novo: float, duracao: float):
	Engine.time_scale = time_scale_novo
	# Espera o tempo (usando o timer da árvore, ignorando o time_scale atual)
	await get_tree().create_timer(duracao * time_scale_novo, true, false, true).timeout
	Engine.time_scale = 1.0
