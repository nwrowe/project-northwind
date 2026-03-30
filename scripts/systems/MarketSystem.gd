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

func get_max_buy_quantity(good_id: String) -> int:
	var price := get_local_price(GameState.current_port_id, good_id)
	if price <= 0:
		return 0
	var affordable_by_money := int(GameState.money / price)

	var good: Dictionary = GameData.get_good(good_id)
	var cargo_size := int(max(1, int(good.get("cargo_size", 1))))
	var free_space := GameState.get_effective_cargo_capacity() - GameState.get_current_cargo_used()
	var affordable_by_cargo := int(free_space / cargo_size)
	return max(0, min(affordable_by_money, affordable_by_cargo))

func can_buy(good_id: String, qty: int) -> bool:
	if qty <= 0:
		return false
	return qty <= get_max_buy_quantity(good_id)

func buy(good_id: String, qty: int) -> Dictionary:
	if not can_buy(good_id, qty):
		return {"success": false, "message": "Cannot buy that quantity."}

	var price := get_local_price(GameState.current_port_id, good_id)
	var total_cost := price * qty
	GameState.money -= total_cost
	GameState.add_cargo(good_id, qty)

	return {
		"success": true,
		"message": "Bought %d %s for %d." % [qty, GameData.get_good(good_id).get("name", good_id), total_cost],
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
		"message": "Sold %d %s for %d." % [qty, GameData.get_good(good_id).get("name", good_id), total_value],
		"money": GameState.money,
		"cargo_used": GameState.get_current_cargo_used(),
	}
