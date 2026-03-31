class_name ContractSystem
extends RefCounted

func get_available_contracts_for_current_port() -> Array:
	var results: Array = []
	for contract in GameData.get_contracts_for_port(GameState.current_port_id):
		var contract_id: String = str(contract.get("id", ""))
		if contract_id in GameState.completed_contract_ids:
			continue
		if _find_active_entry(contract_id).is_empty():
			results.append(contract)
	return results

func accept_contract(contract_id: String) -> Dictionary:
	if not _find_active_entry(contract_id).is_empty():
		return {"success": false, "message": "Contract already accepted."}
	if contract_id in GameState.completed_contract_ids:
		return {"success": false, "message": "Contract already completed."}
	var contract: Dictionary = GameData.contracts_by_id.get(contract_id, {})
	if contract.is_empty():
		return {"success": false, "message": "Contract not found."}
	var minimum_days: int = get_minimum_days_for_contract(contract)
	var requested_days: int = int(contract.get("deadline_days", 0))
	var actual_days: int = max(requested_days, minimum_days + 2)
	GameState.active_contracts.append({"contract_id": contract_id, "accepted_day": GameState.day_count, "deadline_day": GameState.day_count + actual_days, "status": "active"})
	return {"success": true, "message": "Accepted contract. Deliver within %d days (est. sail %d)." % [actual_days, minimum_days]}

func get_active_contracts() -> Array:
	var results: Array = []
	for entry in GameState.active_contracts:
		if entry is Dictionary:
			var contract_id: String = str(entry.get("contract_id", ""))
			var contract: Dictionary = GameData.contracts_by_id.get(contract_id, {})
			if not contract.is_empty():
				results.append(_build_contract_view(entry, contract))
	return results

func get_completable_contracts_for_current_port() -> Array:
	var results: Array = []
	for view in get_active_contracts():
		if bool(view.get("is_completable", false)):
			results.append(view)
	return results

func get_minimum_days_for_contract(contract: Dictionary) -> int:
	return _estimate_route_days(str(contract.get("source_port", "")), str(contract.get("target_port", "")))

func complete_contract(contract_id: String) -> Dictionary:
	var active_index: int = _find_active_index(contract_id)
	if active_index < 0:
		return {"success": false, "message": "Contract is not active."}
	var view: Dictionary = _get_contract_view_for_index(active_index)
	if view.is_empty() or not bool(view.get("is_completable", false)):
		return {"success": false, "message": "Requirements not met at this port."}
	var contract: Dictionary = view.get("contract", {})
	var good_id: String = str(contract.get("good_id", ""))
	var quantity: int = int(contract.get("quantity", 0))
	var reward: int = int(contract.get("reward", 0))
	GameState.add_cargo(good_id, -quantity)
	GameState.money += reward
	GameState.active_contracts.remove_at(active_index)
	if not contract_id in GameState.completed_contract_ids:
		GameState.completed_contract_ids.append(contract_id)
	return {"success": true, "message": "Contract complete! +%d coins for delivering %d %s." % [reward, quantity, GameData.get_good(good_id).get("name", good_id)], "reward": reward, "contract_id": contract_id}

func resolve_contracts_on_arrival() -> Dictionary:
	var completed_messages: Array[String] = []
	var expired_messages: Array[String] = []
	var completable_count: int = 0
	var contract_ids: Array[String] = []
	for entry in GameState.active_contracts:
		if entry is Dictionary:
			contract_ids.append(str(entry.get("contract_id", "")))
	for contract_id in contract_ids:
		var view: Dictionary = _get_contract_view(contract_id)
		if view.is_empty():
			continue
		if bool(view.get("is_expired", false)):
			_expire_contract(contract_id)
			expired_messages.append("Expired: %s" % view.get("summary", contract_id))
		elif bool(view.get("is_completable", false)):
			var result: Dictionary = complete_contract(contract_id)
			if bool(result.get("success", false)):
				completed_messages.append(str(result.get("message", "Contract completed.")))
		elif bool(view.get("at_destination", false)):
			completable_count += 1
	return {"completed_messages": completed_messages, "expired_messages": expired_messages, "destination_waiting_count": completable_count}

func _get_contract_view(contract_id: String) -> Dictionary:
	var index: int = _find_active_index(contract_id)
	if index < 0:
		return {}
	return _get_contract_view_for_index(index)

func _get_contract_view_for_index(index: int) -> Dictionary:
	if index < 0 or index >= GameState.active_contracts.size():
		return {}
	var entry: Dictionary = GameState.active_contracts[index]
	var contract: Dictionary = GameData.contracts_by_id.get(str(entry.get("contract_id", "")), {})
	if contract.is_empty():
		return {}
	return _build_contract_view(entry, contract)

func _build_contract_view(entry: Dictionary, contract: Dictionary) -> Dictionary:
	var good_id: String = str(contract.get("good_id", ""))
	var quantity: int = int(contract.get("quantity", 0))
	var deadline_day: int = int(entry.get("deadline_day", GameState.day_count))
	var cargo_have: int = int(GameState.cargo.get(good_id, 0))
	var at_destination: bool = str(contract.get("target_port", "")) == GameState.current_port_id
	var target_port: Dictionary = GameData.get_port(str(contract.get("target_port", "")))
	var source_port: String = str(contract.get("source_port", ""))
	var estimated_days: int = get_minimum_days_for_contract(contract)
	return {
		"contract_id": str(entry.get("contract_id", "")),
		"contract": contract,
		"accepted_day": int(entry.get("accepted_day", GameState.day_count)),
		"deadline_day": deadline_day,
		"days_remaining": deadline_day - GameState.day_count,
		"cargo_have": cargo_have,
		"at_destination": at_destination,
		"is_expired": GameState.day_count > deadline_day,
		"is_completable": at_destination and GameState.day_count <= deadline_day and cargo_have >= quantity,
		"estimated_days": estimated_days,
		"summary": "%s x%d -> %s" % [GameData.get_good(good_id).get("name", good_id), quantity, target_port.get("name", str(contract.get("target_port", "")))],
		"source_port_name": GameData.get_port(source_port).get("name", source_port)
	}

func _estimate_route_days(start_port_id: String, target_port_id: String) -> int:
	if start_port_id == target_port_id:
		return 0
	var frontier: Array = [{"port_id": start_port_id, "days": 0}]
	var best_days: Dictionary = {start_port_id: 0}
	while not frontier.is_empty():
		var node: Dictionary = frontier.pop_front()
		var port_id: String = str(node.get("port_id", ""))
		var days: int = int(node.get("days", 0))
		if port_id == target_port_id:
			return days
		for route in GameData.get_routes_from(port_id):
			var next_port: String = str(route.get("to", ""))
			var next_days: int = days + int(route.get("distance", 1))
			if not best_days.has(next_port) or next_days < int(best_days[next_port]):
				best_days[next_port] = next_days
				frontier.append({"port_id": next_port, "days": next_days})
	return 99

func _expire_contract(contract_id: String) -> void:
	var index: int = _find_active_index(contract_id)
	if index >= 0:
		GameState.active_contracts.remove_at(index)

func _find_active_index(contract_id: String) -> int:
	for i in range(GameState.active_contracts.size()):
		var entry: Variant = GameState.active_contracts[i]
		if entry is Dictionary and str((entry as Dictionary).get("contract_id", "")) == contract_id:
			return i
	return -1

func _find_active_entry(contract_id: String) -> Dictionary:
	var index: int = _find_active_index(contract_id)
	if index < 0:
		return {}
	return GameState.active_contracts[index]
