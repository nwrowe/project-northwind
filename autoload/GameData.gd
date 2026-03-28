extends Node

var goods_list: Array = []
var ports_list: Array = []
var ships_list: Array = []
var routes_list: Array = []
var events_list: Array = []
var upgrades_list: Array = []
var contracts_list: Array = []

var goods_by_id: Dictionary = {}
var ports_by_id: Dictionary = {}
var ships_by_id: Dictionary = {}
var routes_by_id: Dictionary = {}
var upgrades_by_id: Dictionary = {}
var contracts_by_id: Dictionary = {}

const GOODS_PATH := "res://data/goods.json"
const PORTS_PATH := "res://data/ports.json"
const SHIPS_PATH := "res://data/ships.json"
const ROUTES_PATH := "res://data/routes.json"
const EVENTS_PATH := "res://data/events.json"
const UPGRADES_PATH := "res://data/upgrades.json"
const CONTRACTS_PATH := "res://data/contracts.json"

func load_all_data() -> void:
	goods_list = JsonLoader.load_json(GOODS_PATH)
	ports_list = JsonLoader.load_json(PORTS_PATH)
	ships_list = JsonLoader.load_json(SHIPS_PATH)
	routes_list = JsonLoader.load_json(ROUTES_PATH)
	events_list = JsonLoader.load_json(EVENTS_PATH)
	upgrades_list = JsonLoader.load_json(UPGRADES_PATH)
	contracts_list = JsonLoader.load_json(CONTRACTS_PATH)

	goods_by_id = _index_by_id(goods_list)
	ports_by_id = _index_by_id(ports_list)
	ships_by_id = _index_by_id(ships_list)
	upgrades_by_id = _index_by_id(upgrades_list)
	contracts_by_id = _index_by_id(contracts_list)

	routes_list = _expand_bidirectional_routes(routes_list)
	routes_by_id = _index_by_id(routes_list)

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
