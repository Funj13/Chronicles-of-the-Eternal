extends Resource
class_name ItemData

@export var nome: String = "Nome do Item"
@export_multiline var descricao: String = "Descrição do item aqui."
@export var icone: Texture2D # A imagem que aparece no inventário
@export var empilhavel: bool = false # Se for poção, marca true. Se for espada, false.

@export var tipo: String = "consumivel" # "consumivel", "arma", "chave"
@export var valor_efeito: int = 0 # Quanto cura? Ou quanto dano dá?
