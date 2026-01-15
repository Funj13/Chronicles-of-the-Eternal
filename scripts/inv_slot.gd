extends Panel

@onready var visual_icone = $IconeItem
@onready var visual_qtd = $Amount
@onready var visual_name = $Name # Certifique-se que o Label no Godot chama "Name"

signal slot_clicado(meu_indice)
var item_armazenado = null
var indice_slot 

func atualizar_slot(item: ItemData, quantidade: int):
	if item == null:
		visual_icone.visible = false
		visual_qtd.visible = false
		visual_name.visible = false # Esconde o nome se não tiver item
	else:
		visual_icone.visible = true
		visual_icone.texture = item.icone
		
		# === AQUI ESTAVA FALTANDO ===
		visual_name.visible = true
		visual_name.text = item.nome # Pega o nome direto do recurso do item
		# ============================
		
		if item.empilhavel and quantidade > 1:
			visual_qtd.visible = true
			visual_qtd.text = str(quantidade)
		else:
			visual_qtd.visible = false

func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if item_armazenado:
			slot_clicado.emit(indice_slot, event.button_index)
