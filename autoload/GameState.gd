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

func _normalize_active_contracts(raw_contracts: Array) -> Array:
	var normalized: Array = []
	for entry in raw_contracts:
		if entry is String:
			var contract_id: String = str(entry)
			var contract: Dictionary = GameData.contracts_by_id.get(contract_id, {})
			if contract.is_empty():
				continue
			var deadline_days := int(contract.get("deadline_days", 0))
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
			normalized.append({
				"contract_id": contract_id_dict,
				"accepted_day": int(entry.get("accepted_day", day_count)),
				"deadline_day": int(entry.get("deadline_day", day_count + int(GameData.contracts_by_id[contract_id_dict].get("deadline_days", 0)))),
				"status": str(entry.get("status", "active")),
			})
	return normalized

func get_ship_def() -> Dictionary:
	return GameData.get_ship(ship_id)

func get_effective_cargo_capacity() -> int:
	var base_capacity := int(get_ship_def().get("cargo_capacity", 0))
	var bonus := 0
	for upgrade_id in owned_upgrades:
		var upgrade := GameData.get_upgrade(upgrade_id)
		var effects: Dictionary = upgrade.get("effects", {})
		bonus += int(effects.get("cargo_capacity_bonus", 0))
	return base_capacity + bonus

func get_effective_max_durability() -> int:
	var base_durability := int(get_ship_def().get("max_durability", 0))
	var bonus := 0
	for upgrade_id in owned_upgrades:
		var upgrade := GameData.get_upgrade(upgrade_id)
		var effects: Dictionary = upgrade.get("effects", {})
		bonus += int(effects.get("max_durability_bonus", 0))
	return base_durability + bonus

func get_effective_supply_efficiency() -> float:
	var base_eff := float(get_ship_def().get("supply_efficiency", 1.0))
	var bonus := 0.0