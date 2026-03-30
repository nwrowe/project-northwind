class_name ContractSystem
extends RefCounted

func get_available_contracts_for_current_port() -> Array:
	var results: Array = []
	for contract in GameData.get_contracts_for_port(GameState.current_port_id):
		var contract_id: String = str(contract.get("id", ""))
		if not contract_id in GameState.active_contracts:
			results.append(contract)
	return results

func accept_contract(contract_id: String) -> Dictionary:
	if contract_id in GameState.active_contracts:
		return {"success": false, "message": "Contract already accepted."}

	if GameData.contracts_by_id.get(contract_id, {}).is_empty():
		return {"success": false, "message": "Contract not found."}

	GameState.active_contracts.append(contract_id)
	return {"success": true, "message": "Accepted contract."}

func get_active_contracts() -> Array:
	var results: Array = []
	for contract_id in GameState.active_contracts:
		var contract: Dictionary = GameData.contracts_by_id.get(contract_id, {})
		if not contract.is_empty():
			results.append(contract)
	return results
