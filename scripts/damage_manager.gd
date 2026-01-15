extends Node

# Pré-carrega a cena UMA vez só aqui no gerenciador
var floating_text_scene = preload("res://UI/floating_text.tscn")

func exibir_dano(posicao_mundo: Vector3, valor: int, critico: bool = false):
	if floating_text_scene:
		var texto = floating_text_scene.instantiate()
		
		# Adiciona na raiz da árvore de cenas (get_root)
		# Isso é vital: se adicionar no inimigo e o inimigo morrer/sumir, o texto some junto.
		# Adicionando na raiz, o texto vive independente.
		get_tree().root.add_child(texto)
		
		# Posiciona acima do alvo
		texto.global_position = posicao_mundo + Vector3(0, 1.8, 0)
		
		# Chama a função de animação que criamos antes
		if texto.has_method("exibir_valor"):
			texto.exibir_valor(valor, critico)
