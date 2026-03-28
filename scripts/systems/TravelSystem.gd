class_name TravelSystem
extends RefCounted

var event_system := EventSystem.new()

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
	var route := GameData.get_route(route_id)
	if route.is_empty():
		return {"success": false, "message": "Route not found."}
	if not can_travel(route):
		return {"success": false, "message": "Not enough supplies or ship cannot travel."}

	var supply_cost := get_supply_cost(route)
	GameState.supplies -= supply_cost
	GameState.day_count += int(route.get("distance", 1))
	GameState.current_port_id = route.get("to", GameState.current_port_id)

	var event_payload := event_system.roll_event(float(route.get("risk", 0.0)))
	var triggered := bool(event_payload.get("triggered", false))

	return {
		"success": true,
		"destination_port_id": GameState.current_port_id,
		"supply_cost": supply_cost,
		"event_triggered": triggered,
		"event_payload": event_payload,
	}
