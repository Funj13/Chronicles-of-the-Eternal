extends Panel

# Referências Visuais (Mantive os nomes dos Nós como no Godot para não quebrar)
@onready var visual_icon = $IconeItem
@onready var visual_qty = $Amount
@onready var visual_name = $Name 

# SINAL PADRONIZADO (Inglês)
# Envia o índice e qual botão do mouse foi apertado
signal slot_clicked(index, mouse_button)

var stored_item = null
var slot_index: int = 0

func update_slot(item: ItemData, quantity: int):
	stored_item = item 
	
	if item == null:
		visual_icon.visible = false
		visual_qty.visible = false
		visual_name.visible = false 
	else:
		visual_icon.visible = true
		# Obs: Mantive item.icone e item.nome em PT pois vêm do Resource (ItemData)
		visual_icon.texture = item.icone 
		
		visual_name.visible = true
		visual_name.text = item.nome 
		
		# Obs: Mantive item.empilhavel em PT
		if item.empilhavel and quantity > 1:
			visual_qty.visible = true
			visual_qty.text = str(quantity)
		else:
			visual_qty.visible = false

func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Verifica se tem item antes de emitir o sinal (Lógica original mantida)
		if stored_item:
			slot_clicked.emit(slot_index, event.button_index)
