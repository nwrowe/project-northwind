extends Node

const LEGACY_SAVE_PATH := "user://savegame.json"
const SAVE_DIR := "user://saves"
const SLOT_IDS := ["slot_1", "slot_2", "slot_3", "slot_4", "slot_5", "slot_6"]

func has_save(slot_id: String = "") -> bool:
	_migrate_legacy_save_if_needed()

	if slot_id.is_empty():
		return has_any_save()

	return FileAccess.file_exists(_get_slot_path(slot_id))

func has_any_save() -> bool:
	_migrate_legacy_save_if_needed()

	for slot_id in SLOT_IDS:
		if FileAccess.file_exists(_get_slot_path(slot_id)):
			return true
	return false

func list_slots() -> Array:
	_migrate_legacy_save_if_needed()

	var slots: Array = []
	for slot_id in SLOT_IDS:
		var slot_info := _build_empty_slot_info(slot_id)
		var wrapped := _read_slot_file(slot_id)
		if not wrapped.is_empty():
			var meta: Dictionary = wrapped.get("meta", {})
			slot_info["has_save"] = true
			slot_info["display_name"] = str(meta.get("display_name", slot_info["slot_label"]))
			slot_info["day_count"] = int(meta.get("day_count", 1))
			slot_info["port_id"] = str(meta.get("port_id", ""))
			slot_info["port_name"] = str(meta.get("port_name", "Unknown Port"))
			slot_info["money"] = int(meta.get("money", 0))
			slot_info["saved_at_unix"] = int(meta.get("saved_at_unix", 0))
		slots.append(slot_info)

	return slots

func get_latest_slot() -> Dictionary:
	var latest: Dictionary = {}
	var latest_saved_at: int = -1

	for slot in list_slots():
		if not bool(slot.get("has_save", false)):
			continue

		var saved_at: int = int(slot.get("saved_at_unix", 0))
		if saved_at > latest_saved_at:
			latest_saved_at = saved_at
			latest = slot

	return latest

func save_game(slot_id: String = "slot_1", display_name: String = "") -> Dictionary:
	_migrate_legacy_save_if_needed()
	_ensure_save_dir()

	if slot_id.is_empty():
		slot_id = SLOT_IDS[0]

	var existing_slot := _get_slot_info(slot_id)
	var resolved_name := display_name.strip_edges()

	if resolved_name.is_empty() and bool(existing_slot.get("has_save", false)):
		resolved_name = str(existing_slot.get("display_name", ""))

	if resolved_name.is_empty():
		resolved_name = get_slot_label(slot_id)

	var state_data: Dictionary = GameState.to_dict()
	var payload := {
		"meta": _build_metadata(slot_id, resolved_name, state_data),
		"state": state_data,
	}

	var file := FileAccess.open(_get_slot_path(slot_id), FileAccess.WRITE)
	if file == null:
		return {"success": false, "message": "Could not open save file for writing."}

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	return {
		"success": true,
		"message": "Saved %s." % resolved_name,
		"slot_id": slot_id,
		"display_name": resolved_name,
	}

func load_game(slot_id: String = "") -> Dictionary:
	_migrate_legacy_save_if_needed()

	if slot_id.is_empty():
		return load_latest_game()

	var wrapped := _read_slot_file(slot_id)
	if wrapped.is_empty():
		return {"success": false, "message": "No save found in %s." % get_slot_label(slot_id)}

	var state_data: Dictionary = wrapped.get("state", {})
	if state_data.is_empty():
		return {"success": false, "message": "Save data is invalid."}

	GameState.load_from_dict(state_data)

	var meta: Dictionary = wrapped.get("meta", {})
	var display_name: String = str(meta.get("display_name", get_slot_label(slot_id)))

	return {
		"success": true,
		"message": "Loaded %s." % display_name,
		"slot_id": slot_id,
		"display_name": display_name,
	}

func load_latest_game() -> Dictionary:
	var latest_slot := get_latest_slot()
	if latest_slot.is_empty():
		return {"success": false, "message": "No save found."}

	return load_game(str(latest_slot.get("slot_id", "")))

func get_slot_label(slot_id: String) -> String:
	var index := SLOT_IDS.find(slot_id)
	if index == -1:
		return "Save Slot"
	return "Slot %d" % (index + 1)

func _get_slot_info(slot_id: String) -> Dictionary:
	for slot in list_slots():
		if str(slot.get("slot_id", "")) == slot_id:
			return slot
	return _build_empty_slot_info(slot_id)

func _build_empty_slot_info(slot_id: String) -> Dictionary:
	return {
		"slot_id": slot_id,
		"slot_label": get_slot_label(slot_id),
		"has_save": false,
		"display_name": "",
		"day_count": 1,
		"port_id": "",
		"port_name": "Unknown Port",
		"money": 0,
		"saved_at_unix": 0,
	}

func _build_metadata(slot_id: String, display_name: String, state_data: Dictionary) -> Dictionary:
	var port_id: String = str(state_data.get("current_port_id", ""))
	var port_name := "Unknown Port"
	if not port_id.is_empty():
		var port: Dictionary = GameData.get_port(port_id)
		port_name = str(port.get("name", port_id))

	return {
		"slot_id": slot_id,
		"display_name": display_name,
		"day_count": int(state_data.get("day_count", 1)),
		"port_id": port_id,
		"port_name": port_name,
		"money": int(state_data.get("money", 0)),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}

func _read_slot_file(slot_id: String) -> Dictionary:
	var path := _get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	var data: Dictionary = parsed

	# Wrapped slot format.
	if data.has("state") and data.get("state") is Dictionary:
		return data

	# Legacy/raw dict fallback.
	return {
		"meta": _build_metadata(slot_id, get_slot_label(slot_id), data),
		"state": data,
	}

func _get_slot_path(slot_id: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot_id]

func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and not dir.dir_exists("saves"):
		dir.make_dir_recursive("saves")

func _migrate_legacy_save_if_needed() -> void:
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return

	for slot_id in SLOT_IDS:
		if FileAccess.file_exists(_get_slot_path(slot_id)):
			return

	var file := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var payload := {
		"meta": _build_metadata(SLOT_IDS[0], get_slot_label(SLOT_IDS[0]), parsed as Dictionary),
		"state": parsed as Dictionary,
	}

	_ensure_save_dir()

	var out_file := FileAccess.open(_get_slot_path(SLOT_IDS[0]), FileAccess.WRITE)
	if out_file == null:
		return

	out_file.store_string(JSON.stringify(payload, "\t"))
	out_file.close()
