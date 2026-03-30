extends Node

var current_port_id: String = ""
var money: int = 0
var ship_id: String = ""
var ship_durability: int = 0
var supplies: int = 0
var cargo: Dictionary = {}
var owned_upgrades: Array[String] = []
var day_count: int = 1
var active_contracts: Array = []
var completed_contract_ids: Array[String] = []
var pending_status_message: String = ""

var reserve_ship_ids: Array[String] = []
var crew_count: int = 4
var officer_assignments: Dictionary = {}
var trust_rating: int = 0
var infamy_rating: int = 0
var tavern_candidates_by_port: Dictionary = {}

func new_game() -> void:
	current_port_id = "aurelia"
	money = 150
	ship_id = "coastal_sloop"
	owned_upgrades = []
	ship_durability = get_effective_max_durability()
	supplies = 8
	cargo = {}
	day_count = 1
	active_contracts = []
	completed_contract_ids = []
	pending_status_message = ""
	reserve_ship_ids = []
	crew_count = 4
	officer_assignments = {}
	trust_rating = 0
	infamy_rating = 0
	tavern_candidates_by_port = {}

func to_dict() -> Dictionary:
	return {
		"current_port_id": current_port_id,
		"money": money,
		"ship_id": ship_id,
		"ship_durability": ship_durability,
		"supplies": supplies,
		"cargo": cargo,
		"owned_upgrades": owned_upgrades,
		"day_count": day_count,
		"active_contracts": active_contracts,
		"completed_contract_ids": completed_contract_ids,
		"reserve_ship_ids": reserve_ship_ids,
		"crew_count": crew_count,
		"officer_assignments": officer_assignments,
		"trust_rating": trust_rating,
		"infamy_rating": infamy_rating,
		"tavern_candidates_by_port": tavern_candidates_by_port,
	}

func load_from_dict(data: Dictionary) -> void:
	current_port_id = data.get("current_port_id", "aurelia")
	money = int(data.get("money", 150))
	ship_id = data.get("ship_id", "coastal_sloop")
	ship_durability = int(data.get("ship_durability", 100))
	supplies = int(data.get("supplies", 8))
	cargo = data.get("cargo", {})
	owned_upgrades = Array(data.get("owned_upgrades", []), TYPE_STRING, "", null)
	day_count = int(data.get("day_count", 1))
	active_contracts = _normalize_active_contracts(data.get("active_contracts", []))
	completed_contract_ids = Array(data.get("completed_contract_ids", []), TYPE_STRING, "", null)
	pending_status_message = ""
	reserve_ship_ids = Array(data.get("reserve_ship_ids", []), TYPE_STRING, "", null)
	crew_count = int(data.get("crew_count", 4))
	officer_assignments = data.get("officer_assignments", {})
	trust_rating = int(data.get("trust_rating", 0))
	infamy_rating = int(data.get("infamy_rating", 0))
	tavern_candidates_by_port = data.get("tavern_candidates_by_port", {})

func _normalize_active_contracts(raw_contracts: Array) -> Array:
	var normalized: Array = []
	for entry in raw_contracts:
		if entry is String:
			var contract_id: String = str(entry)
			var contract: Dictionary = GameData.contracts_by_id.get(contract_id, {})
			if contract.is_empty():
				continue
			var deadline_days: int = int(contract.get("deadline_days", 0))
			normalized.append({
				"contract_id": contract_id,
				"accepted_day": day_count,
				"deadline_day": day_count + deadline_days,
				"status": "active",
			})
		elif entry is Dictionary:
			var contract_id_dict: String = str(entry.get("contract_id", ""))
			if contract_id_dict.is_empty() or GameData.contracts_by_id.get(contract_id_dict, {}).is_empty():
				continue
			var fallback_deadline: int = day_count + int(GameData.contracts_by_id[contract_id_dict].get("deadline_days", 0))
			normalized.append({
				"contract_id": contract_id_dict,
				"accepted_day": int(entry.get("accepted_day", day_count)),
				"deadline_day": int(entry.get("deadline_day", fallback_deadline)),
				"status": str(entry.get("status", "active")),
			})
	return normalized

func get_ship_def() -> Dictionary:
	return GameData.get_ship(ship_id)

func _get_upgrade_bonus_int(key: String) -> int:
	var bonus: int = 0
	for upgrade_id in owned_upgrades:
		var upgrade: Dictionary = GameData.get_upgrade(upgrade_id)
		var effects: Dictionary = upgrade.get("effects", {})
		bonus += int(effects.get(key, 0))
	return bonus

func _get_upgrade_bonus_float(key: String) -> float:
	var bonus: float = 0.0
	for upgrade_id in owned_upgrades:
		var upgrade: Dictionary = GameData.get_upgrade(upgrade_id)
		var effects: Dictionary = upgrade.get("effects", {})
		bonus += float(effects.get(key, 0.0))
	return bonus

func get_effective_cargo_capacity() -> int:
	var base_capacity: int = int(get_ship_def().get("cargo_capacity", 0))
	return max(0, base_capacity + _get_upgrade_bonus_int("cargo_capacity_bonus"))

func get_effective_max_durability() -> int:
	var base_durability: int = int(get_ship_def().get("max_durability", 0))
	return max(1, base_durability + _get_upgrade_bonus_int("max_durability_bonus"))

func get_effective_supply_efficiency() -> float:
	var base_eff: float = float(get_ship_def().get("supply_efficiency", 1.0))
	return max(0.1, base_eff + _get_upgrade_bonus_float("supply_efficiency_bonus"))

func get_effective_speed() -> float:
	var base_speed: float = float(get_ship_def().get("speed", 1.0))
	return max(0.1, base_speed + _get_upgrade_bonus_float("speed_bonus"))

func get_effective_firepower() -> int:
	var base_value: int = int(get_ship_def().get("firepower", 0))
	return max(0, base_value + _get_upgrade_bonus_int("firepower_bonus"))

func get_effective_hull_armor() -> int:
	var base_value: int = int(get_ship_def().get("hull_armor", 0))
	return max(0, base_value + _get_upgrade_bonus_int("hull_armor_bonus"))

func get_effective_evasion() -> int:
	var base_value: int = int(get_ship_def().get("evasion", 0))
	return max(0, base_value + _get_upgrade_bonus_int("evasion_bonus"))

func get_effective_intimidation() -> int:
	var base_value: int = int(get_ship_def().get("intimidation", 0))
	return max(0, base_value + _get_upgrade_bonus_int("intimidation_bonus"))

func get_effective_crew_capacity() -> int:
	var base_value: int = int(get_ship_def().get("crew_capacity", 0))
	return max(1, base_value + _get_upgrade_bonus_int("crew_capacity_bonus"))

func get_effective_officer_slots() -> int:
	var base_value: int = int(get_ship_def().get("officer_slots", 0))
	return max(1, base_value + _get_upgrade_bonus_int("officer_slots_bonus"))

func get_effective_boarding_strength() -> int:
	var base_value: int = int(get_ship_def().get("boarding_strength", 0))
	return max(0, base_value + _get_upgrade_bonus_int("boarding_strength_bonus"))

func get_current_cargo_used() -> int:
	var total: int = 0
	for good_id in cargo.keys():
		var qty: int = int(cargo[good_id])
		var good: Dictionary = GameData.get_good(str(good_id))
		var cargo_size: int = int(good.get("cargo_size", 1))
		total += qty * cargo_size
	return total

func get_active_officer_count() -> int:
	return officer_assignments.size()

func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in owned_upgrades

func apply_upgrade(upgrade_id: String) -> void:
	if not has_upgrade(upgrade_id):
		owned_upgrades.append(upgrade_id)
		ship_durability = min(ship_durability, get_effective_max_durability())
		crew_count = min(crew_count, get_effective_crew_capacity())

func add_cargo(good_id: String, qty: int) -> void:
	cargo[good_id] = int(cargo.get(good_id, 0)) + qty
	if int(cargo[good_id]) <= 0:
		cargo.erase(good_id)

func change_reputation(trust_delta: int, infamy_delta: int) -> void:
	trust_rating += trust_delta
	infamy_rating += infamy_delta

func apply_event_effects(effects: Dictionary) -> void:
	ship_durability = max(0, ship_durability - int(effects.get("durability_loss", 0)))
	supplies -= int(effects.get("supply_loss", 0))
	money -= int(effects.get("money_loss", 0))

	var cargo_loss_percent: float = float(effects.get("cargo_loss_percent", 0.0))
	if cargo_loss_percent > 0.0:
		for good_id in cargo.keys().duplicate():
			var good_id_str: String = str(good_id)
			var qty: int = int(cargo[good_id_str])
			var lost: int = int(floor(qty * cargo_loss_percent))
			cargo[good_id_str] = max(0, qty - lost)
			if int(cargo[good_id_str]) == 0:
				cargo.erase(good_id_str)

	supplies = max(0, supplies)
	money = max(0, money)
