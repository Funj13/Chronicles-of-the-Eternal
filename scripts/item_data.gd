extends Resource
class_name ItemData

@export_category("Visual")
@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var icone: Texture2D

@export_category("Tipo")
@export_enum("recurso", "equipamento", "consumivel", "arma") var tipo: String = "recurso"
@export var empilhavel: bool = false

# --- NOVO: ESTATÍSTICAS DE RPG ---
@export_category("Estatísticas (RPG)")
@export var defesa: int = 0         # Para armaduras/escudos
@export var dano: int = 0           # Para armas
@export var custo_mana: int = 0     # Se gastar magia
@export var recuperacao: int = 0    # Se for poção (quanto cura)
