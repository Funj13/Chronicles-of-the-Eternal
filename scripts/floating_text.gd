extends Marker3D

@onready var label = $Label3D

# Configurações de Animação
var altura_subida: float = 1.5  # Quanto ele sobe
var tempo_duracao: float = 0.8  # Quanto tempo fica na tela
var espalhar_x: float = 0.5     # Variação lateral para não encavalar

func _ready():
	# Opcional: Começa invisível se quiser, mas geralmente já iniciamos chamando a função
	pass

# Essa é a função que você vai chamar quando der o dano
func exibir_valor(valor: int, critico: bool = false):
	# 1. Configura o Texto
	label.text = str(valor)
	
	# Se for crítico, muda cor e aumenta (Visual Juice!)
	if critico:
		label.modulate = Color(1, 0, 0) # Vermelho puro
		label.font_size = 96            # Maior
		label.outline_modulate = Color(1, 1, 0) # Borda Amarela
	else:
		label.modulate = Color(1, 1, 1) # Branco normal (ou a cor que você definiu no editor)
	
	# 2. Variação Aleatória (Para números não ficarem um em cima do outro)
	var offset_random = Vector3(randf_range(-espalhar_x, espalhar_x), 0, 0)
	position += offset_random
	
	# 3. A Mágica do TWEEN (Animação)
	var tween = create_tween()
	
	# Garante que as animações rodem juntas (em paralelo)
	tween.set_parallel(true)
	
	# A: Mover para cima
	var destino_final = position + Vector3(0, altura_subida, 0)
	tween.tween_property(self, "position", destino_final, tempo_duracao).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# B: Aumentar escala (efeito "Pop" inicial)
	scale = Vector3.ZERO # Começa pequeno
	tween.tween_property(self, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# C: Desaparecer (Fade Out) no finalzinho
	# Espera 50% do tempo, depois diminui o Alpha (transparência) para 0
	tween.tween_property(label, "modulate:a", 0.0, tempo_duracao * 0.5).set_delay(tempo_duracao * 0.5)
	
	# 4. Limpeza (Garbage Collection)
	# Quando o Tween terminar tudo, deleta este nó para não pesar o jogo
	tween.chain().tween_callback(queue_free)
