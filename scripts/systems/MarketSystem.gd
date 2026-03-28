class_name MarketSystem
extends RefCounted

func get_local_price(port_id: String, good_id: String) -> int:
	var good := GameData.get_good(good_id)
	var port := GameData.get_port(port_id)
	if good.is_empty() or port.is_empty():
		return 0

	var base_price := float(good.get("base_price", 0))
	var modifiers: Dictionary = port.get("goods_modifiers", {})
	var port_modifier := float(modifiers.get(good_id, 1.0))
	return int(round(base_price * port_modifier))

func can_buy(good_id: String, qty: int) -> bool:
	if qty <= 0:
		return false
	var price := get_local_price(GameState.current_port_id, good_id)
	var total_cost := price * qty
	if GameState.money < total_cost:
		return false

	var good := GameData.get_good(good_id)
	var cargo_size := int(good.get("cargo_size", 1))
	var added_space := cargo_size * qty
	return GameState.get_current_cargo_used() + added_space <= GameState.get_effective_cargo_capacity()

func buy(good_id: String, qty: int) -> Dictionary:
	if not can_buy(good_id, qty):
		return {"success": false, "message": "Cannot buy that quantity."}

	var price := get_local_price(GameState.current_port_id, good_id)
	var total_cost := price * qty
	GameState.money -= total_cost
	GameState.add_cargo(good_id, qty)

	return {
		"success": true,
		"message": "Bought %d %s." % [qty, GameData.get_good(good_id).get("name", good_id)],
		"money": GameState.money,
		"cargo_used": GameState.get_current_cargo_used(),
	}

func can_sell(good_id: String, qty: int) -> bool:
	if qty <= 0:
		return false
	return int(GameState.cargo.get(good_id, 0)) >= qty

func sell(good_id: String, qty: int) -> Dictionary:
	if not can_sell(good_id, qty):
		return {"success": false, "message": "Cannot sell that quantity."}

	var price := get_local_price(GameState.current_port_id, good_id)
	var total_value := price * qty
	GameState.money += total_value
	GameState.add_cargo(good_id, -qty)

	return {
		"success": true,
		"message": "Sold %d %s." % [qty, GameData.get_good(good_id).get("name", good_id)],
		"money": GameState.money,
		"cargo_used": GameState.get_current_cargo_used(),
	}
