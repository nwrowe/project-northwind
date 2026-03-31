class_name MarketSystem
extends RefCounted

func get_local_price(port_id: String, good_id: String) -> int:
	var good: Dictionary = GameData.get_good(good_id)
	var port: Dictionary = GameData.get_port(port_id)
	if good.is_empty() or port.is_empty():
		return 0
	return int(round(float(good.get("base_price", 0)) * float(port.get("goods_modifiers", {}).get(good_id, 1.0))))

func get_max_buy_quantity(good_id: String) -> int:
	var price: int = get_local_price(GameState.current_port_id, good_id)
	if price <= 0:
		return 0
	var affordable_by_money: int = int(GameState.money / price)
	var cargo_size: int = int(max(1, int(GameData.get_good(good_id).get("cargo_size", 1))))
	var free_space: int = GameState.get_effective_cargo_capacity() - GameState.get_current_cargo_used()
	var affordable_by_cargo: int = int(free_space / cargo_size)
	return max(0, min(affordable_by_money, affordable_by_cargo))

func can_buy(good_id: String, qty: int) -> bool:
	return qty > 0 and qty <= get_max_buy_quantity(good_id)

func buy(good_id: String, qty: int) -> Dictionary:
	if not can_buy(good_id, qty):
		return {"success": false, "message": "Cannot buy that quantity."}
	var price: int = get_local_price(GameState.current_port_id, good_id)
	var total_cost: int = price * qty
	GameState.money -= total_cost
	GameState.add_cargo(good_id, qty)
	GameState.add_market_log_entry({"day": GameState.day_count, "type": "buy", "port_id": GameState.current_port_id, "good_id": good_id, "price": price, "quantity": qty})
	return {"success": true, "message": "Bought %d %s for %d." % [qty, GameData.get_good(good_id).get("name", good_id), total_cost], "money": GameState.money, "cargo_used": GameState.get_current_cargo_used()}

func can_sell(good_id: String, qty: int) -> bool:
	return qty > 0 and int(GameState.cargo.get(good_id, 0)) >= qty

func sell(good_id: String, qty: int) -> Dictionary:
	if not can_sell(good_id, qty):
		return {"success": false, "message": "Cannot sell that quantity."}
	var price: int = get_local_price(GameState.current_port_id, good_id)
	var total_value: int = price * qty
	GameState.money += total_value
	GameState.add_cargo(good_id, -qty)
	GameState.add_market_log_entry({"day": GameState.day_count, "type": "sell", "port_id": GameState.current_port_id, "good_id": good_id, "price": price, "quantity": qty})
	return {"success": true, "message": "Sold %d %s for %d." % [qty, GameData.get_good(good_id).get("name", good_id), total_value], "money": GameState.money, "cargo_used": GameState.get_current_cargo_used()}

func get_price_hint(good_id: String) -> String:
	var current_price: int = get_local_price(GameState.current_port_id, good_id)
	var entries: Array = GameState.get_market_entries_for_good(good_id)
	if entries.is_empty():
		var base_price: int = int(GameData.get_good(good_id).get("base_price", current_price))
		if current_price <= int(round(base_price * 0.9)):
			return "Good local buy"
		if current_price >= int(round(base_price * 1.1)):
			return "Strong local sell"
		return "Near baseline"
	var total_buy_price: int = 0
	var buy_count: int = 0
	for entry in entries:
		if str(entry.get("type", "")) == "buy":
			total_buy_price += int(entry.get("price", 0))
			buy_count += 1
	if buy_count == 0:
		return "Use log book"
	var avg_buy: float = float(total_buy_price) / float(buy_count)
	if current_price <= int(floor(avg_buy * 0.9)):
		return "Cheaper than your average buy"
	if current_price >= int(ceil(avg_buy * 1.1)):
		return "Higher than your average buy"
	return "Near your average buy"
