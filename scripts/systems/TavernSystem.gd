class_name TavernSystem
extends RefCounted

const FIRST_NAMES = ["Arin", "Basso", "Celia", "Daren", "Elia", "Ferris", "Galen", "Hesta", "Ivo", "Jora", "Kellan", "Lysa", "Mira", "Nico", "Orin", "Pella"]
const LAST_NAMES = ["Vale", "Morrow", "Thorne", "Sable", "Rowan", "Mar", "Quill", "Fen", "Corren", "Dusk"]
const TRAITS = ["steady", "bold", "careful", "cheap", "loyal", "scarred", "ambitious", "calm", "ruthless", "patient"]
const OFFICER_ROLES = ["captain", "navigator", "gunner", "carpenter"]

func get_rumors_for_current_port() -> Array:
	return GameData.get_rumors_for_port(GameState.current_port_id)

func get_tavernkeeper_name() -> String:
	var port_id = str(GameState.current_port_id)
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
	var port = GameData.get_port(GameState.current_port_id)
	return "%s welcomes captains, traders, and drifters from every dock in %s." % [get_tavernkeeper_name(), port.get("name", "this port")]

func get_random_rumor(exclude_id: String = "") -> Dictionary:
	var rumors = get_rumors_for_current_port()
	if rumors.is_empty():
		return {
			"id": "fallback",
			"speaker": get_tavernkeeper_name(),
			"title": "Nothing new tonight",
			"text": "The room is loud, but no useful rumor rises above the cups and dice tonight."
		}

	var filtered = []
	for rumor in rumors:
		if str(rumor.get("id", "")) != exclude_id:
			filtered.append(rumor)
	if filtered.is_empty():
		filtered = rumors

	var rumor_index = randi() % filtered.size()
	return filtered[rumor_index]

func ensure_candidates_for_current_port() -> void:
	var port_id = str(GameState.current_port_id)
	if not GameState.tavern_candidates_by_port.has(port_id):
		GameState.tavern_candidates_by_port[port_id] = _generate_candidate_pool(port_id)
		return
	var existing = GameState.tavern_candidates_by_port.get(port_id, [])
	if existing.is_empty():
		GameState.tavern_candidates_by_port[port_id] = _generate_candidate_pool(port_id)

func get_candidates_for_current_port() -> Array:
	ensure_candidates_for_current_port()
	return GameState.tavern_candidates_by_port.get(GameState.current_port_id, [])

func reroll_candidates_for_current_port() -> Dictionary:
	var port_id = str(GameState.current_port_id)
	GameState.tavern_candidates_by_port[port_id] = _generate_candidate_pool(port_id)
	return {"success": true, "message": "Fresh faces drift into the tavern tonight."}

func hire_candidate(candidate_id: String) -> Dictionary:
	ensure_candidates_for_current_port()
	var port_id = str(GameState.current_port_id)
	var candidates = GameState.tavern_candidates_by_port.get(port_id, [])
	var candidate_index = _find_candidate_index(candidates, candidate_id)
	if candidate_index < 0:
		return {"success": false, "message": "That recruit is no longer available."}
	var candidate = candidates[candidate_index]
	var role = str(candidate.get("role", ""))
	var cost = int(candidate.get("signing_cost", 0))
	if GameState.money < cost:
		return {"success": false, "message": "Not enough money to hire %s." % candidate.get("name", "this recruit")}

	if role == "crew":
		var amount = int(candidate.get("crew_amount", 0))
		if GameState.crew_count + amount > GameState.get_effective_crew_capacity():
			return {"success": false, "message": "Not enough crew space on your current ship."}
		GameState.money -= cost
		GameState.crew_count += amount
		GameState.change_reputation(1, 0)
		candidates.remove_at(candidate_index)
		GameState.tavern_candidates_by_port[port_id] = candidates
		return {"success": true, "message": "Hired %d deckhands for %d coins." % [amount, cost]}

	if GameState.get_active_officer_count() >= GameState.get_effective_officer_slots():
		return {"success": false, "message": "No open officer slots on this ship."}
	if GameState.officer_assignments.has(role):
		return {"success": false, "message": "You already have a %s assigned." % role.capitalize()}

	GameState.money -= cost
	GameState.officer_assignments[role] = candidate
	GameState.change_reputation(1, 0)
	candidates.remove_at(candidate_index)
	GameState.tavern_candidates_by_port[port_id] = candidates
	return {"success": true, "message": "Hired %s as %s for %d coins." % [candidate.get("name", "Officer"), role.capitalize(), cost]}

func get_officer_summary_lines() -> Array:
	var lines = []
	for role in OFFICER_ROLES:
		if GameState.officer_assignments.has(role):
			var officer = GameState.officer_assignments[role]
			lines.append("%s: %s" % [role.capitalize(), officer.get("name", "Assigned")])
		else:
			lines.append("%s: Vacant" % role.capitalize())
	return lines

func _generate_candidate_pool(port_id: String) -> Array:
	var pool = []
	var base_seed = int(Time.get_unix_time_from_system()) + GameState.day_count
	for i in range(3):
		var role = str(OFFICER_ROLES[i % OFFICER_ROLES.size()])
		pool.append(_make_officer_candidate(port_id, role, i, base_seed))
	pool.append(_make_crew_candidate(port_id, base_seed))
	return pool

func _make_officer_candidate(port_id: String, role: String, officer_num: int, base_seed: int) -> Dictionary:
	var name = _random_name(base_seed + officer_num * 11)
	var personality_trait = str(TRAITS[(base_seed + officer_num * 7) % TRAITS.size()])
	var sailing = 2 + ((base_seed + officer_num * 3) % 5)
	var repair = 1 + ((base_seed + officer_num * 5) % 5)
	var fighting = 1 + ((base_seed + officer_num * 7) % 5)
	var navigation = 1 + ((base_seed + officer_num * 9) % 5)
	var leadership = 1 + ((base_seed + officer_num * 13) % 5)
	var signing_cost = 70 + sailing * 8 + repair * 6 + fighting * 7 + navigation * 6 + leadership * 8
	return {
		"id": "%s_%s_%d_%d" % [port_id, role, GameState.day_count, officer_num],
		"type": "officer",
		"role": role,
		"name": name,
		"trait": personality_trait,
		"signing_cost": signing_cost,
		"sailing": sailing,
		"repair": repair,
		"fighting": fighting,
		"navigation": navigation,
		"leadership": leadership
	}

func _make_crew_candidate(port_id: String, base_seed: int) -> Dictionary:
	var amount = 2 + (base_seed % 4)
	var sailing = 1 + (base_seed % 3)
	var repair = 1 + ((base_seed + 2) % 3)
	var fighting = 1 + ((base_seed + 4) % 3)
	var signing_cost = 12 * amount + sailing * 4 + repair * 3 + fighting * 3
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
		"fighting": fighting
	}

func _find_candidate_index(candidates: Array, candidate_id: String) -> int:
	for i in range(candidates.size()):
		var candidate = candidates[i]
		if str(candidate.get("id", "")) == candidate_id:
			return i
	return -1

func _random_name(seed_value: int) -> String:
	var first_name = str(FIRST_NAMES[abs(seed_value) % FIRST_NAMES.size()])
	var last_seed = int(abs(seed_value) / 3)
	var last_name = str(LAST_NAMES[last_seed % LAST_NAMES.size()])
	return "%s %s" % [first_name, last_name]
