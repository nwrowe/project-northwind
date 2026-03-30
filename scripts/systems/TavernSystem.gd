class_name TavernSystem
extends RefCounted

func get_rumors_for_current_port() -> Array:
	return GameData.get_rumors_for_port(GameState.current_port_id)

func get_tavernkeeper_name() -> String:
	var port_id: String = GameState.current_port_id
	match port_id:
		"aurelia":
			return "Mira of the Lantern Cup"
		"varenna":
			return "Basso the Ledger Host"
		"cyr_port":
			return "Captain Sorell"
		"marsa_quay":
			return "Sena of the Salt Table"
		"thalos":
			return "Nera's Quiet Glass"
		_:
			return "The Tavern Keeper"

func get_tavern_intro() -> String:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	return "%s welcomes captains, traders, and drifters from every dock in %s." % [get_tavernkeeper_name(), port.get("name", "this port")]

func get_random_rumor(exclude_id: String = "") -> Dictionary:
	var rumors: Array = get_rumors_for_current_port()
	if rumors.is_empty():
		return {
			"id": "fallback",
			"speaker": get_tavernkeeper_name(),
			"title": "Nothing new tonight",
			"text": "The room is loud, but no useful rumor rises above the cups and dice tonight.",
		}

	var filtered: Array = []
	for rumor in rumors:
		if str(rumor.get("id", "")) != exclude_id:
			filtered.append(rumor)
	if filtered.is_empty():
		filtered = rumors

	var index: int = randi() % filtered.size()
	return filtered[index]
