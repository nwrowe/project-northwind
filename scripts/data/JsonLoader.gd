class_name JsonLoader
extends RefCounted

static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("JSON file not found: %s" % path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: %s" % path)
		return []

	var text := file.get_as_text()
	file.close()

	var parsed := JSON.parse_string(text)
	if parsed == null:
		push_error("Failed to parse JSON file: %s" % path)
		return []

	return parsed
