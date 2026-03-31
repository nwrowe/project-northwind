class_name OfficeStorageSystem
extends RefCounted

const MEMBERSHIP_COST := 80

func is_member() -> bool:
	return GameState.office_member

func join_office() -> Dictionary:
	if GameState.office_member:
		return {"success": false, "message": "You already have office membership."}
	if GameState.money < MEMBERSHIP_COST:
		return {"success": false, "message": "Not enough money for membership."}
	GameState.money -= MEMBERSHIP_COST
	GameState.office_member = true
	return {"success": true, "message": "Joined the harbor office for %d gold. Storage access is now available." % MEMBERSHIP_COST}

func get_current_storage() -> Dictionary:
	return GameState.get_office_storage(GameState.current_port_id).duplicate(true)

func _set_current_storage(storage: Dictionary) -> void:
	GameState.set_office_storage(GameState.current_port_id, storage)

func store(good_id: String, qty: int) -> Dictionary:
	if not GameState.office_member:
		return {"success": false, "message": "Membership is required for storage."}
	if qty <= 0 or int(GameState.cargo.get(good_id, 0)) < qty:
		return {"success": false, "message": "Not enough cargo to store."}
	var storage: Dictionary = get_current_storage()
	storage[good_id] = int(storage.get(good_id, 0)) + qty
	_set_current_storage(storage)
	GameState.add_cargo(good_id, -qty)
	return {"success": true, "message": "Stored %d %s in the office warehouse." % [qty, GameData.get_good(good_id).get("name", good_id)]}

func retrieve(good_id: String, qty: int) -> Dictionary:
	if not GameState.office_member:
		return {"success": false, "message": "Membership is required for storage."}
	var storage: Dictionary = get_current_storage()
	var stored_qty: int = int(storage.get(good_id, 0))
	if qty <= 0 or stored_qty < qty:
		return {"success": false, "message": "Not enough stored cargo to retrieve."}
	var cargo_size: int = int(GameData.get_good(good_id).get("cargo_size", 1))
	var free_space: int = GameState.get_effective_cargo_capacity() - GameState.get_current_cargo_used()
	if qty * cargo_size > free_space:
		return {"success": false, "message": "Not enough cargo space on your ship."}
	storage[good_id] = stored_qty - qty
	if int(storage[good_id]) <= 0:
		storage.erase(good_id)
	_set_current_storage(storage)
	GameState.add_cargo(good_id, qty)
	return {"success": true, "message": "Retrieved %d %s from the office warehouse." % [qty, GameData.get_good(good_id).get("name", good_id)]}
