extends Node

const SAVE_PATH := "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> Dictionary:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return {"success": false, "message": "Could not open save file for writing."}
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	file.close()
	return {"success": true, "message": "Game saved."}

func load_game() -> Dictionary:
	if not has_save():
		return {"success": false, "message": "No save found."}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"success": false, "message": "Could not open save file for reading."}

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"success": false, "message": "Save data is invalid."}

	GameState.load_from_dict(parsed as Dictionary)
	return {"success": true, "message": "Game loaded."}
