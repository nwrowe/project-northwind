class_name ClimateSystem
extends RefCounted

func get_current_port_profile() -> Dictionary:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	var climate: Dictionary = GameData.get_climate(str(port.get("climate_id", "")))
	return {
		"port": port,
		"climate": climate,
		"gathering_options": port.get("gathering_options", []),
		"refining_options": port.get("refining_options", []),
	}

func get_climate_name_for_current_port() -> String:
	var profile: Dictionary = get_current_port_profile()
	var climate: Dictionary = profile.get("climate", {})
	return str(climate.get("name", "Unclassified Climate"))

func get_climate_description_for_current_port() -> String:
	var profile: Dictionary = get_current_port_profile()
	var climate: Dictionary = profile.get("climate", {})
	return str(climate.get("description", "No climate profile recorded yet."))

func get_gathering_summary_for_current_port() -> String:
	var profile: Dictionary = get_current_port_profile()
	var gathering: Array = profile.get("gathering_options", [])
	if gathering.is_empty():
		return "No known gathering opportunities yet."
	return ", ".join(gathering)

func get_refining_summary_for_current_port() -> String:
	var profile: Dictionary = get_current_port_profile()
	var refining: Array = profile.get("refining_options", [])
	if refining.is_empty():
		return "No known refining specialties yet."
	return ", ".join(refining)
