extends Node

# --- CONFIGURAÇÕES DE SAVE ---
const SAVE_DIR = "user://"
const SAVE_PREFIX = "save_slot_"

# --- VARIÁVEIS GLOBAIS ---
var player_name: String = "Herói"
var selected_character: String = ""
var player_position: Vector3 = Vector3.ZERO
var current_level: String = "res://world.tscn"

# Importante: Saber qual slot estamos usando
var current_save_slot: int = 1 

const CHAR_SCENES = {
	"Boy": "res://Assets/Characters/PlayerBoy.tscn",
	"Girl": "res://Assets/Characters/PlayerGirl.tscn"
	
}

# --- FUNÇÃO AUXILIAR: Gera o nome do arquivo (ex: save_slot_1.json) ---
func get_save_path(slot_id: int) -> String:
	return SAVE_DIR + SAVE_PREFIX + str(slot_id) + ".json"

# --- SALVAR O JOGO ---
func save_game():
	var save_data = {
		"player_name": player_name,
		"selected_character": selected_character,
		"current_level": current_level,
		"pos_x": player_position.x,
		"pos_y": player_position.y,
		"pos_z": player_position.z,
		"save_date": Time.get_datetime_string_from_system()
	}
	
	# Usa o slot atual para salvar no arquivo certo
	var path = get_save_path(current_save_slot)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Jogo Salvo no Slot ", current_save_slot)

# --- CARREGAR O JOGO (AQUI ESTAVA O ERRO) ---
# Antes era: func load_game():
# AGORA É: func load_game(slot_id: int) -> bool:
func load_game(slot_id: int) -> bool:
	var path = get_save_path(slot_id)
	
	if not FileAccess.file_exists(path):
		return false # Arquivo não existe
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error == OK:
		var data = json.data
		# Restaura os dados
		player_name = data.get("player_name", "Herói")
		selected_character = data["selected_character"]
		current_level = data["current_level"]
		player_position = Vector3(data["pos_x"], data["pos_y"], data["pos_z"])
		
		# Define este como o slot atual (para quando salvar de novo, salvar no mesmo lugar)
		current_save_slot = slot_id
		return true
		
	return false

# --- ESPIAR O SLOT (Para mostrar info no botão) ---
func get_slot_info(slot_id: int):
	var path = get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error == OK:
		return json.data
	return null
