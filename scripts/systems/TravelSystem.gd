class_name TravelSystem
extends RefCounted

var event_system: EventSystem = EventSystem.new()
var contract_system: ContractSystem = ContractSystem.new()

func get_routes_from_current_port() -> Array:
	return GameData.get_routes_from(GameState.current_port_id)

func get_supply_cost(route: Dictionary) -> int:
	var distance: float = float(route.get("distance", 0))
	var efficiency: float = max(0.1, GameState.get_effective_supply_efficiency())
	return int(ceil(distance / efficiency))

func can_travel(route: Dictionary) -> bool:
	if route.is_empty():
		return false
	return GameState.supplies >= get_supply_cost(route) and GameState.ship_durability > 0

func travel(route_id: String) -> Dictionary:
	var route: Dictionary = GameData.get_route(route_id)
	if route.is_empty():
		return {"success": false, "message": "Route not found."}
	if not can_travel(route):
		return {"success": false, "message": "Not enough supplies or ship cannot travel."}

	var from_port: Dictionary = GameData.get_port(GameState.current_port_id)
	var supply_cost: int = get_supply_cost(route)
	GameState.supplies -= supply_cost
	GameState.day_count += int(route.get("distance", 1))
	GameState.current_port_id = route.get("to", GameState.current_port_id)
	var destination: Dictionary = GameData.get_port(GameState.current_port_id)

	var event_payload: Dictionary = event_system.roll_event(float(route.get("risk", 0.0)))
	var triggered: bool = bool(event_payload.get("triggered", false))
	var contract_result: Dictionary = contract_system.resolve_contracts_on_arrival()

	var arrival_summary: String = _build_arrival_summary(
		from_port.get("name", str(route.get("from", ""))),
		destination.get("name", str(route.get("to", ""))),
		supply_cost,
		triggered,
		contract_result
	)
	GameState.pending_status_message = arrival_summary

	return {
		"success": true,
		"destination_port_id": GameState.current_port_id,
		"supply_cost": supply_cost,
		"event_triggered": triggered,
		"event_payload": event_payload,
		"arrival_summary": arrival_summary,
		"contract_result": contract_result,
	}

func _build_arrival_summary(from_port_name: String, to_port_name: String, supply_cost: int, event_triggered: bool, contract_result: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Arrived: %s -> %s" % [from_port_name, to_port_name])
	lines.append("Supplies spent: %d" % supply_cost)
	lines.append("Event: %s" % ("Triggered" if event_triggered else "None"))

	var completed_messages: Array = contract_result.get("completed_messages", [])
	var expired_messages: Array = contract_result.get("expired_messages", [])
	var waiting_count: int = int(contract_result.get("destination_waiting_count", 0))

	if not completed_messages.is_empty():
		for msg in completed_messages:
			lines.append(str(msg))
	if not expired_messages.is_empty():
		for msg in expired_messages:
			lines.append(str(msg))
	if waiting_count > 0:
		lines.append("Contracts waiting on cargo at this port: %d" % waiting_count)

	return "\n".join(lines)
