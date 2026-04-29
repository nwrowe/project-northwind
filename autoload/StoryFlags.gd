extends Node

## Focused facade for story progression flags and port-specific persistent state.
##
## GameState remains the backing store during this first split so save compatibility
## is preserved while story systems can migrate to this narrower API.

func is_office_member() -> bool:
	return GameState.office_member

func set_office_member(value: bool) -> void:
	GameState.office_member = value

func get_office_storage(port_id: String) -> Dictionary:
	return GameState.get_office_storage(port_id)

func set_office_storage(port_id: String, storage: Dictionary) -> void:
	GameState.set_office_storage(port_id, storage)

func get_tavern_candidates_by_port() -> Dictionary:
	return GameState.tavern_candidates_by_port

func get_tavern_candidates(port_id: String) -> Array:
	return GameState.tavern_candidates_by_port.get(port_id, [])

func set_tavern_candidates(port_id: String, candidates: Array) -> void:
	GameState.tavern_candidates_by_port[port_id] = candidates

func get_pending_status_message() -> String:
	return GameState.pending_status_message

func set_pending_status_message(message: String) -> void:
	GameState.pending_status_message = message

func clear_pending_status_message() -> void:
	GameState.pending_status_message = ""

func get_free_inn_nights() -> int:
	return GameState.free_inn_nights

func set_free_inn_nights(value: int) -> void:
	GameState.free_inn_nights = max(0, value)

func get_inn_supply_story_stage() -> String:
	return GameState.inn_supply_story_stage

func set_inn_supply_story_stage(stage: String) -> void:
	GameState.inn_supply_story_stage = stage

func get_inn_supply_order() -> Dictionary:
	return GameState.inn_supply_order

func set_inn_supply_order(order: Dictionary) -> void:
	GameState.inn_supply_order = order

func get_inn_supply_runs_completed() -> int:
	return GameState.inn_supply_runs_completed

func set_inn_supply_runs_completed(value: int) -> void:
	GameState.inn_supply_runs_completed = max(0, value)

func is_starter_bridge_out() -> bool:
	return GameState.starter_bridge_out

func set_starter_bridge_out(value: bool) -> void:
	GameState.starter_bridge_out = value

func resolve_starter_bridge_repair() -> void:
	GameState.resolve_starter_bridge_repair()

func get_ship_task_last_day() -> Dictionary:
	return GameState.ship_task_last_day

func set_ship_task_last_day(task_id: String, day: int) -> void:
	GameState.ship_task_last_day[task_id] = day

func get_next_trip_chart_discount() -> float:
	return GameState.next_trip_chart_discount

func set_next_trip_chart_discount(discount: float) -> void:
	GameState.next_trip_chart_discount = max(0.0, discount)
