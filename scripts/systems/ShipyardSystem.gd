class_name ShipyardSystem
extends RefCounted

func get_all_ships() -> Array:
	return GameData.ships_list

func get_purchase_candidates() -> Array:
	var results: Array = []
	for ship in GameData.ships_list:
		var ship_id: String = str(ship.get("id", ""))
		if ship_id == GameState.ship_id:
			continue
		results.append(ship)
	return results

func can_buy_ship(ship_id: String) -> Dictionary:
	var ship: Dictionary = GameData.get_ship(ship_id)
	if ship.is_empty():
		return {"success": false, "message": "Ship not found."}
	if ship_id == GameState.ship_id:
		return {"success": false, "message": "Already using that ship."}

	var price: int = int(ship.get("base_price", 0))
	if GameState.money < price:
		return {"success": false, "message": "Not enough money."}

	var new_capacity: int = int(ship.get("cargo_capacity", 0))
	var current_cargo: int = GameState.get_current_cargo_used()
	if current_cargo > new_capacity:
		return {"success": false, "message": "Current cargo exceeds that ship's capacity."}

	return {"success": true, "message": "Can buy.", "price": price}

func buy_ship(ship_id: String) -> Dictionary:
	var can_buy: Dictionary = can_buy_ship(ship_id)
	if not bool(can_buy.get("success", false)):
		return can_buy

	var ship: Dictionary = GameData.get_ship(ship_id)
	var price: int = int(ship.get("base_price", 0))
	GameState.money -= price
	GameState.ship_id = ship_id
	GameState.ship_durability = GameState.get_effective_max_durability()
	GameState.pending_status_message = "Purchased %s for %d coins." % [ship.get("name", ship_id), price]

	return {
		"success": true,
		"message": GameState.pending_status_message,
		"ship_id": ship_id,
		"price": price,
	}

func build_ship_summary(ship: Dictionary) -> String:
	return "%s  Cost:%d  Cargo:%d  Durability:%d  Speed:%.2f  Supply Eff:%.2f" % [
		ship.get("name", "Ship"),
		int(ship.get("base_price", 0)),
		int(ship.get("cargo_capacity", 0)),
		int(ship.get("max_durability", 0)),
		float(ship.get("speed", 1.0)),
		float(ship.get("supply_efficiency", 1.0)),
	]
