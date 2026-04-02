class_name TravelSystem
extends RefCounted

var event_system: EventSystem = EventSystem.new()
var contract_system: ContractSystem = ContractSystem.new()

func get_routes_from_current_port() -> Array:
	return GameData.get_routes_from(GameState.current_port_id)

func get_supply_cost(route: Dictionary) -> int:
	var distance: float = float(route.get("distance", 0))
	var efficiency: float = max(0.1, GameState.get_effective_supply_efficiency())
	var base_cost: int = int(ceil(distance / efficiency))
	var discounted: int = int(ceil(float(base_cost) * (1.0 - GameState.get_travel_supply_discount())))
	return max(1, discounted)

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

	return _advance_trip(route, get_supply_cost(route))

func _advance_trip(route: Dictionary, supply_cost: int) -> Dictionary:
	var from_port_id: String = GameState.current_port_id
	var from_port: Dictionary = GameData.get_port(from_port_id)
	var start_money: int = GameState.money
	var start_morale: int = GameState.morale

	GameState.supplies -= supply_cost
	var trip_costs: Dictionary = GameState.process_trip_costs()
	GameState.day_count += int(route.get("distance", 1))
	GameState.current_port_id = str(route.get("to", GameState.current_port_id))
	var destination_port_id: String = GameState.current_port_id
	var destination: Dictionary = GameData.get_port(destination_port_id)

	var destination_port_id: String = GameState.current_port_id
	var destination: Dictionary = GameData.get_port(destination_port_id)
	var event_payload: Dictionary = event_system.roll_event(float(route.get("risk", 0.0)))
	var triggered: bool = bool(event_payload.get("triggered", false))
	var contract_result: Dictionary = contract_system.resolve_contracts_on_arrival()

	GameState.record_trip_report({
		"day": GameState.day_count,
		"route_id": str(route.get("id", "")),
		"from_port_id": from_port_id,
		"from_port_name": str(from_port.get("name", from_port_id)),
		"to_port_id": destination_port_id,
		"to_port_name": str(destination.get("name", destination_port_id)),
		"money_before": start_money,
		"money_after": GameState.money,
		"money_delta": GameState.money - start_money,
		"morale_before": start_morale,
		"morale_after": GameState.morale,
		"upkeep_paid": int(trip_costs.get("paid", 0)),
	})

	var arrival_summary: String = _build_arrival_summary(
		from_port.get("name", from_port_id),
		destination.get("name", destination_port_id),
		supply_cost,
		trip_costs,
		triggered,
		contract_result
	)
	GameState.pending_status_message = arrival_summary

	return {
		"success": true,
		"from_port_id": from_port_id,
		"destination_port_id": destination_port_id,
		"route_id": str(route.get("id", "")),
		"route_distance": int(route.get("distance", 1)),
		"supply_cost": supply_cost,
		"trip_costs": trip_costs,
		"event_triggered": triggered,
		"event_payload": event_payload,
		"arrival_summary": arrival_summary,
		"contract_result": contract_result,
	}

func _build_arrival_summary(from_port_name: String, to_port_name: String, supply_cost: int, trip_costs: Dictionary, event_triggered: bool, contract_result: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Arrived: %s -> %s" % [from_port_name, to_port_name])
	lines.append("Supplies spent: %d" % supply_cost)
	if GameState.get_travel_supply_discount() > 0.0:
		lines.append("Navigator saved %.0f%% of normal travel supplies" % (GameState.get_travel_supply_discount() * 100.0))
	lines.append("Crew wages %d | Officer wages %d | Ship upkeep %d" % [int(trip_costs.get("crew_wages", 0)), int(trip_costs.get("officer_wages", 0)), int(trip_costs.get("ship_upkeep", 0))])
	if int(trip_costs.get("unpaid", 0)) > 0:
		lines.append("Unpaid upkeep: %d | Morale %d" % [int(trip_costs.get("unpaid", 0)), GameState.morale])
	else:
		lines.append("Upkeep paid in full | Morale %d" % GameState.morale)
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
