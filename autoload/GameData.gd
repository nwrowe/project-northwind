extends Node

var goods_list: Array = []
var ports_list: Array = []
var ships_list: Array = []
var routes_list: Array = []
var events_list: Array = []
var upgrades_list: Array = []
var contracts_list: Array = []
var rumors_list: Array = []
var climates_list: Array = []
var npcs_list: Array = []

var goods_by_id: Dictionary = {}
var ports_by_id: Dictionary = {}
var ships_by_id: Dictionary = {}
var routes_by_id: Dictionary = {}
var upgrades_by_id: Dictionary = {}
var contracts_by_id: Dictionary = {}
var climates_by_id: Dictionary = {}
var npcs_by_id: Dictionary = {}

var validation_errors: Array[String] = []
var is_data_valid: bool = false

const GOODS_PATH := "res://data/goods.json"
const PORTS_PATH := "res://data/ports.json"
const SHIPS_PATH := "res://data/ships.json"
const ROUTES_PATH := "res://data/routes.json"
const EVENTS_PATH := "res://data/events.json"
const UPGRADES_PATH := "res://data/upgrades.json"
const CONTRACTS_PATH := "res://data/contracts.json"
const RUMORS_PATH := "res://data/rumors.json"
const CLIMATES_PATH := "res://data/climates.json"
const NPCS_PATH := "res://data/npcs.json"

func load_all_data() -> bool:
	validation_errors.clear()
	is_data_valid = false

	goods_list = _load_json_array(GOODS_PATH, "goods")
	ports_list = _load_json_array(PORTS_PATH, "ports")
	ships_list = _load_json_array(SHIPS_PATH, "ships")
	routes_list = _load_json_array(ROUTES_PATH, "routes")
	events_list = _load_json_array(EVENTS_PATH, "events")
	upgrades_list = _load_json_array(UPGRADES_PATH, "upgrades")
	contracts_list = _load_json_array(CONTRACTS_PATH, "contracts")
	rumors_list = _load_json_array(RUMORS_PATH, "rumors")
	climates_list = _load_json_array(CLIMATES_PATH, "climates")
	npcs_list = _load_json_array(NPCS_PATH, "npcs")

	goods_by_id = _index_by_id(goods_list)
	ports_by_id = _index_by_id(ports_list)
	ships_by_id = _index_by_id(ships_list)
	upgrades_by_id = _index_by_id(upgrades_list)
	contracts_by_id = _index_by_id(contracts_list)
	climates_by_id = _index_by_id(climates_list)
	npcs_by_id = _index_by_id(npcs_list)

	routes_list = _expand_bidirectional_routes(routes_list)
	routes_by_id = _index_by_id(routes_list)

	_validate_all_data()
	is_data_valid = validation_errors.is_empty()
	if not is_data_valid:
		push_error("GameData validation failed with %d issue(s)." % validation_errors.size())
		for error in validation_errors:
			push_error(error)
		return false

	return true

func get_validation_report() -> String:
	if validation_errors.is_empty():
		return "GameData validation passed."
	return "GameData validation failed:\n- %s" % "\n- ".join(validation_errors)

func _load_json_array(path: String, label: String) -> Array:
	var data: Variant = JsonLoader.load_json(path)
	if data is Array:
		return data
	validation_errors.append("%s data at %s must be a top-level array." % [label.capitalize(), path])
	return []

func _validate_all_data() -> void:
	_validate_required_fields(goods_list, "goods", ["id", "name", "base_price", "cargo_size"])
	_validate_required_fields(ports_list, "ports", ["id", "name", "climate_id", "goods_modifiers"])
	_validate_required_fields(ships_list, "ships", ["id", "name", "cargo_capacity", "max_durability", "speed", "supply_efficiency"])
	_validate_required_fields(routes_list, "routes", ["id", "from", "to", "distance", "risk"])
	_validate_required_fields(events_list, "events", ["id", "name", "type", "weight", "min_risk", "effects", "text"])
	_validate_required_fields(upgrades_list, "upgrades", ["id", "name", "cost", "effects"])
	_validate_required_fields(contracts_list, "contracts", ["id", "source_port", "target_port", "good_id", "quantity", "reward", "deadline_days"])
	_validate_required_fields(climates_list, "climates", ["id", "name", "description", "resource_bias", "refining_bias"])
	_validate_required_fields(rumors_list, "rumors", ["port_id"])
	_validate_required_fields(npcs_list, "npcs", ["id", "port_id", "category", "business_role", "display_name", "title", "description", "traits", "location_hint"])

	_validate_unique_ids(goods_list, "goods")
	_validate_unique_ids(ports_list, "ports")
	_validate_unique_ids(ships_list, "ships")
	_validate_unique_ids(routes_list, "routes")
	_validate_unique_ids(events_list, "events")
	_validate_unique_ids(upgrades_list, "upgrades")
	_validate_unique_ids(contracts_list, "contracts")
	_validate_unique_ids(climates_list, "climates")
	_validate_unique_ids(npcs_list, "npcs")

	_validate_port_references()
	_validate_route_references()
	_validate_contract_references()
	_validate_event_payloads()
	_validate_upgrade_payloads()
	_validate_rumor_references()
	_validate_npc_references()

func _validate_required_fields(items: Array, label: String, required_fields: Array[String]) -> void:
	for i in range(items.size()):
		var item: Variant = items[i]
		if not item is Dictionary:
			validation_errors.append("%s[%d] must be a Dictionary." % [label, i])
			continue
		for field_name in required_fields:
			if not (item as Dictionary).has(field_name):
				validation_errors.append("%s[%d] is missing required field '%s'." % [label, i, field_name])

func _validate_unique_ids(items: Array, label: String) -> void:
	var seen: Dictionary = {}
	for i in range(items.size()):
		var item: Variant = items[i]
		if not item is Dictionary or not (item as Dictionary).has("id"):
			continue
		var item_id: String = str((item as Dictionary).get("id", ""))
		if item_id.is_empty():
			validation_errors.append("%s[%d] has an empty id." % [label, i])
		elif seen.has(item_id):
			validation_errors.append("%s has duplicate id '%s'." % [label.capitalize(), item_id])
		else:
			seen[item_id] = true

func _validate_port_references() -> void:
	for port in ports_list:
		if not port is Dictionary:
			continue
		var port_dict: Dictionary = port
		var port_id: String = str(port_dict.get("id", ""))
		var climate_id: String = str(port_dict.get("climate_id", ""))
		if not climates_by_id.has(climate_id):
			validation_errors.append("Port '%s' references unknown climate_id '%s'." % [port_id, climate_id])
		var modifiers: Variant = port_dict.get("goods_modifiers", {})
		if not modifiers is Dictionary:
			validation_errors.append("Port '%s' has non-dictionary goods_modifiers." % port_id)
			continue
		for good_id in (modifiers as Dictionary).keys():
			if not goods_by_id.has(str(good_id)):
				validation_errors.append("Port '%s' references unknown good '%s' in goods_modifiers." % [port_id, str(good_id)])

func _validate_route_references() -> void:
	for route in routes_list:
		if not route is Dictionary:
			continue
		var route_dict: Dictionary = route
		var route_id: String = str(route_dict.get("id", ""))
		var from_port: String = str(route_dict.get("from", ""))
		var to_port: String = str(route_dict.get("to", ""))
		if not ports_by_id.has(from_port):
			validation_errors.append("Route '%s' references unknown from port '%s'." % [route_id, from_port])
		if not ports_by_id.has(to_port):
			validation_errors.append("Route '%s' references unknown to port '%s'." % [route_id, to_port])
		if int(route_dict.get("distance", 0)) <= 0:
			validation_errors.append("Route '%s' must have distance > 0." % route_id)

func _validate_contract_references() -> void:
	for contract in contracts_list:
		if not contract is Dictionary:
			continue
		var contract_dict: Dictionary = contract
		var contract_id: String = str(contract_dict.get("id", ""))
		var source_port: String = str(contract_dict.get("source_port", ""))
		var target_port: String = str(contract_dict.get("target_port", ""))
		var good_id: String = str(contract_dict.get("good_id", ""))
		if not ports_by_id.has(source_port):
			validation_errors.append("Contract '%s' references unknown source_port '%s'." % [contract_id, source_port])
		if not ports_by_id.has(target_port):
			validation_errors.append("Contract '%s' references unknown target_port '%s'." % [contract_id, target_port])
		if not goods_by_id.has(good_id):
			validation_errors.append("Contract '%s' references unknown good_id '%s'." % [contract_id, good_id])
		if int(contract_dict.get("quantity", 0)) <= 0:
			validation_errors.append("Contract '%s' must have quantity > 0." % contract_id)
		if int(contract_dict.get("deadline_days", 0)) <= 0:
			validation_errors.append("Contract '%s' must have deadline_days > 0." % contract_id)

func _validate_event_payloads() -> void:
	for event_data in events_list:
		if not event_data is Dictionary:
			continue
		var event_dict: Dictionary = event_data
		var event_id: String = str(event_dict.get("id", ""))
		if float(event_dict.get("weight", 0.0)) <= 0.0:
			validation_errors.append("Event '%s' must have weight > 0." % event_id)
		var effects: Variant = event_dict.get("effects", {})
		if not effects is Dictionary:
			validation_errors.append("Event '%s' must have dictionary effects." % event_id)
			continue
		for field_name in ["durability_loss", "supply_loss", "money_loss", "cargo_loss_percent"]:
			if not (effects as Dictionary).has(field_name):
				validation_errors.append("Event '%s' effects are missing '%s'." % [event_id, field_name])

func _validate_upgrade_payloads() -> void:
	for upgrade in upgrades_list:
		if not upgrade is Dictionary:
			continue
		var upgrade_dict: Dictionary = upgrade
		var upgrade_id: String = str(upgrade_dict.get("id", ""))
		var effects: Variant = upgrade_dict.get("effects", {})
		if not effects is Dictionary:
			validation_errors.append("Upgrade '%s' must have dictionary effects." % upgrade_id)
			continue
		for field_name in ["cargo_capacity_bonus", "max_durability_bonus", "speed_bonus", "supply_efficiency_bonus", "firepower_bonus", "hull_armor_bonus", "evasion_bonus", "intimidation_bonus", "crew_capacity_bonus", "officer_slots_bonus", "boarding_strength_bonus"]:
			if not (effects as Dictionary).has(field_name):
				validation_errors.append("Upgrade '%s' effects are missing '%s'." % [upgrade_id, field_name])

func _validate_rumor_references() -> void:
	for i in range(rumors_list.size()):
		var rumor: Variant = rumors_list[i]
		if not rumor is Dictionary:
			continue
		var port_id: String = str((rumor as Dictionary).get("port_id", ""))
		if not port_id.is_empty() and not ports_by_id.has(port_id):
			validation_errors.append("rumors[%d] references unknown port_id '%s'." % [i, port_id])

func _validate_npc_references() -> void:
	for i in range(npcs_list.size()):
		var npc_data: Variant = npcs_list[i]
		if not npc_data is Dictionary:
			continue
		var npc_dict: Dictionary = npc_data
		var port_id: String = str(npc_dict.get("port_id", ""))
		if not ports_by_id.has(port_id):
			validation_errors.append("NPC '%s' references unknown port_id '%s'." % [str(npc_dict.get("id", "")), port_id])
		var category: String = str(npc_dict.get("category", ""))
		if category != "resident" and category != "notable":
			validation_errors.append("NPC '%s' has unsupported category '%s'." % [str(npc_dict.get("id", "")), category])
		if not npc_dict.get("traits", []) is Array:
			validation_errors.append("NPC '%s' must have an array of traits." % str(npc_dict.get("id", "")))

func _index_by_id(items: Array) -> Dictionary:
	var indexed := {}
	for item in items:
		if item is Dictionary and item.has("id"):
			indexed[item["id"]] = item
	return indexed

func _expand_bidirectional_routes(input_routes: Array) -> Array:
	var expanded: Array = []
	for route in input_routes:
		expanded.append(route)
		if route.get("bidirectional", false):
			var reverse_route: Dictionary = route.duplicate(true)
			reverse_route["id"] = "%s_rev" % route["id"]
			reverse_route["from"] = route["to"]
			reverse_route["to"] = route["from"]
			reverse_route["bidirectional"] = false
			expanded.append(reverse_route)
	return expanded

func get_good(id: String) -> Dictionary:
	return goods_by_id.get(id, {})

func get_port(id: String) -> Dictionary:
	return ports_by_id.get(id, {})

func get_ship(id: String) -> Dictionary:
	return ships_by_id.get(id, {})

func get_route(id: String) -> Dictionary:
	return routes_by_id.get(id, {})

func get_upgrade(id: String) -> Dictionary:
	return upgrades_by_id.get(id, {})

func get_climate(id: String) -> Dictionary:
	return climates_by_id.get(id, {})

func get_npc(id: String) -> Dictionary:
	return npcs_by_id.get(id, {})

func get_routes_from(port_id: String) -> Array:
	var results: Array = []
	for route in routes_list:
		if route.get("from", "") == port_id:
			results.append(route)
	return results

func get_contracts_for_port(port_id: String) -> Array:
	var results: Array = []
	for contract in contracts_list:
		if contract.get("source_port", "") == port_id:
			results.append(contract)
	return results

func get_rumors_for_port(port_id: String) -> Array:
	var results: Array = []
	for rumor in rumors_list:
		if str(rumor.get("port_id", "")) == port_id:
			results.append(rumor)
	return results

func get_npcs_for_port(port_id: String) -> Array:
	var results: Array = []
	for npc_data in npcs_list:
		if str(npc_data.get("port_id", "")) == port_id:
			results.append(npc_data)
	return results

func get_residents_for_port(port_id: String) -> Array:
	var results: Array = []
	for npc_data in npcs_list:
		if str(npc_data.get("port_id", "")) == port_id and str(npc_data.get("category", "")) == "resident":
			results.append(npc_data)
	return results

func get_notable_npcs_for_port(port_id: String) -> Array:
	var results: Array = []
	for npc_data in npcs_list:
		if str(npc_data.get("port_id", "")) == port_id and str(npc_data.get("category", "")) == "notable":
			results.append(npc_data)
	return results
