class_name TavernSystem
extends RefCounted

const FIRST_NAMES := ["Arin", "Basso", "Celia", "Daren", "Elia", "Ferris", "Galen", "Hesta", "Ivo", "Jora", "Kellan", "Lysa", "Mira", "Nico", "Orin", "Pella"]
const LAST_NAMES := ["Vale", "Morrow", "Thorne", "Sable", "Rowan", "Mar", "Quill", "Fen", "Corren", "Dusk"]
const TRAITS := ["steady", "bold", "careful", "cheap", "loyal", "scarred", "ambitious", "calm", "ruthless", "patient"]
const OFFICER_ROLES := ["captain", "navigator", "gunner", "carpenter"]

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

func ensure_candidates_for_current_port() -> void:
	var port_id: String = GameState.current_port_id
	if not GameState.tavern_candidates_by_port.has(port_id) or Array(GameState.tavern_candidates_by_port[port_id]).is_empty():
		GameState.tavern_candidates_by_port[port_id] = _generate_candidate_pool(port_id)

func get_candidates_for_current_port() -> Array:
	ensure_candidates_for_current_port()
	return GameState.tavern_candidates_by_port.get(GameState.current_port_id, [])

func reroll_candidates_for_current_port() -> Dictionary:
	var port_id: String = GameState.current_port_id
	GameState.tavern_candidates_by_port[port_id] = _generate_candidate_pool(port_id)
	return {"success": true, "message": "Fresh faces drift into the tavern tonight."}

func hire_candidate(candidate_id: String) -> Dictionary:
	ensure_candidates_for_current_port()
	var port_id: String = GameState.current_port_id
	var candidates: Array = GameState.tavern_candidates_by_port.get(port_id, [])
	var index: int = _find_candidate_index(candidates, candidate_id)
	if index < 0:
		return {"success": false, "message": "That recruit is no longer available."}
	var candidate: Dictionary = candidates[index]
	var role: String = str(candidate.get("role", ""))
	var cost: int = int(candidate.get("signing_cost", 0))
	if GameState.money < cost:
		return {"success": false, "message": "Not enough money to hire %s." % candidate.get("name", "this recruit")}

	if role == "crew":
		var amount: int = int(candidate.get("crew_amount", 0))
		if GameState.crew_count + amount > GameState.get_effective_crew_capacity():
			return {"success": false, "message": "Not enough crew space on your current ship."}
		GameState.money -= cost
		GameState.crew_count += amount
		GameState.change_reputation(1, 0)
		candidates.remove_at(index)
		GameState.tavern_candidates_by_port[port_id] = candidates
		return {"success": true, "message": "Hired %d deckhands for %d coins." % [amount, cost]}

	if GameState.get_active_officer_count() >= GameState.get_effective_officer_slots():
		return {"success": false, "message": "No open officer slots on this ship."}
	if GameState.officer_assignments.has(role):
		return {"success": false, "message": "You already have a %s assigned." % role.capitalize()}

	GameState.money -= cost
	GameState.officer_assignments[role] = candidate
	GameState.change_reputation(1, 0)
	candidates.remove_at(index)
	GameState.tavern_candidates_by_port[port_id] = candidates
	return {"success": true, "message": "Hired %s as %s for %d coins." % [candidate.get("name", "Officer"), role.capitalize(), cost]}

func get_officer_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	for role in OFFICER_ROLES:
		if GameState.officer_assignments.has(role):
			var officer: Dictionary = GameState.officer_assignments[role]
			lines.append("%s: %s" % [role.capitalize(), officer.get("name", "Assigned")])
		else:
			lines.append("%s: Vacant" % role.capitalize())
	return lines

func _generate_candidate_pool(port_id: String) -> Array:
	var pool: Array = []
	var base_seed: int = int(Time.get_unix_time_from_system()) + GameState.day_count
	for i in range(3):
		var role: String = OFFICER_ROLES[i % OFFICER_ROLES.size()]
		pool.append(_make_officer_candidate(port_id, role, i, base_seed))
	pool.append(_make_crew_candidate(port_id, base_seed))
	return pool

func _make_officer_candidate(port_id: String, role: String, index: int, base_seed: int) -> Dictionary:
	var name: String = _random_name(base_seed + index * 11)
	var trait: String = TRAITS[(base_seed + index * 7) % TRAITS.size()]
	var sailing: int = 2 + ((base_seed + index * 3) % 5)
	var repair: int = 1 + ((base_seed + index * 5) % 5)
	var fighting: int = 1 + ((base_seed + index * 7) % 5)
	var navigation: int = 1 + ((base_seed + index * 9) % 5)
	var leadership: int = 1 + ((base_seed + index * 13) % 5)
	var signing_cost: int = 70 + sailing * 8 + repair * 6 + fighting * 7 + navigation * 6 + leadership * 8
	return {
		"id": "%s_%s_%d_%d" % [port_id, role, GameState.day_count, index],
		"type": "officer",
		"role": role,
		"name": name,
		"trait": trait,
		"signing_cost": signing_cost,
		"sailing": sailing,
		"repair": repair,
		"fighting": fighting,
		"navigation": navigation,
		"leadership": leadership,
	}

func _make_crew_candidate(port_id: String, base_seed: int) -> Dictionary:
	var amount: int = 2 + (base_seed % 4)
	var sailing: int = 1 + (base_seed % 3)
	var repair: int = 1 + ((base_seed + 2) % 3)
	var fighting: int = 1 + ((base_seed + 4) % 3)
	var signing_cost: int = 12 * amount + sailing * 4 + repair * 3 + fighting * 3
	return {
		"id": "%s_crew_%d" % [port_id, GameState.day_count],
		"type": "crew",
		"role": "crew",
		"name": "Deckhands for hire",
		"trait": "practical",
		"crew_amount": amount,
		"signing_cost": signing_cost,
		"sailing": sailing,
		"repair": repair,
		"fighting": fighting,
	}

func _find_candidate_index(candidates: Array, candidate_id: String) -> int:
	for i in range(candidates.size()):
		var candidate: Dictionary = candidates[i]
		if str(candidate.get("id", "")) == candidate_id:
			return i
	return -1

func _random_name(seed_value: int) -> String:
	var first: String = FIRST_NAMES[abs(seed_value) % FIRST_NAMES.size()]
	var last: String = LAST_NAMES[abs(seed_value / 3) % LAST_NAMES.size()]
	return "%s %s" % [first, last]
