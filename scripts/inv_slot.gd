extends Panel

@onready var visual_icone = $IconeItem
@onready var visual_qtd = $Amount

signal slot_clicado(meu_indice) # Novo Sinal!
var item_armazenado = null
var indice_slot # Vamos numerar os slots para saber qual é qual

func atualizar_slot(item: ItemData, quantidade: int): # <--- Agora aceita o tipo ItemData
	if item == null:
		visual_icone.visible = false
		visual_qtd.visible = false
	else:
		visual_icone.visible = true
		visual_icone.texture = item.icone # Pega a foto do arquivo .tres
		
		# Só mostra número se for empilhável E maior que 1
		if item.empilhavel and quantidade > 1:
			visual_qtd.visible = true
			visual_qtd.text = str(quantidade)
		else:
			visual_qtd.visible = false


#func _on_button_pressed():
#	# Quando clicar no botão transparente, avisa o Pai (Inventário)
#	# "Ei, clicaram no slot número X!"
#	if item_armazenado: # Só avisa se tiver item
#		slot_clicado.emit(indice_slot)


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if item_armazenado:
			# Envia Indice E o Botão Clicado
			slot_clicado.emit(indice_slot, event.button_index)
