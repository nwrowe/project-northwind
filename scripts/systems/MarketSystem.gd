class_name MarketSystem
extends RefCounted

const BUY_MARKUP := 1.10
const SELL_MULTIPLIER := 1.00

func get_base_market_value(port_id: String, good_id: String) -> int:
	var good: Dictionary = GameData.get_good(good_id)
	var port: Dictionary = GameData.get_port(port_id)
	if good.is_empty() or port.is_empty():
		return 0
	return int(round(float(good.get("base_price", 0)) * float(port.get("goods_modifiers", {}).get(good_id, 1.0))))

func get_buy_price(port_id: String, good_id: String) -> int:
	return int(ceil(get_base_market_value(port_id, good_id) * BUY_MARKUP))

func get_sell_price(port_id: String, good_id: String) -> int:
	return int(floor(get_base_market_value(port_id, good_id) * SELL_MULTIPLIER))

func get_max_buy_quantity(good_id: String) -> int:
	var price: int = get_buy_price(GameState.current_port_id, good_id)
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
	var price: int = get_buy_price(GameState.current_port_id, good_id)
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
	var price: int = get_sell_price(GameState.current_port_id, good_id)
	var total_value: int = price * qty
	GameState.money += total_value
	GameState.add_cargo(good_id, -qty)
	GameState.add_market_log_entry({"day": GameState.day_count, "type": "sell", "port_id": GameState.current_port_id, "good_id": good_id, "price": price, "quantity": qty})
	return {"success": true, "message": "Sold %d %s for %d." % [qty, GameData.get_good(good_id).get("name", good_id), total_value], "money": GameState.money, "cargo_used": GameState.get_current_cargo_used()}

func get_price_hint(good_id: String) -> String:
	var current_sell: int = get_sell_price(GameState.current_port_id, good_id)
	var entries: Array = GameState.get_market_entries_for_good(good_id)
	if entries.is_empty():
		var base_price: int = get_base_market_value(GameState.current_port_id, good_id)
		if current_sell <= int(round(base_price * 0.9)):
			return "Weak sell market"
		if current_sell >= int(round(base_price * 1.1)):
			return "Strong sell market"
		return "Near baseline"
	var total_buy_spend: int = 0
	var total_buy_qty: int = 0
	for entry in entries:
		if str(entry.get("type", "")) == "buy":
			total_buy_spend += int(entry.get("price", 0)) * int(entry.get("quantity", 0))
			total_buy_qty += int(entry.get("quantity", 0))
	if total_buy_qty == 0:
		return "Use log book"
	var avg_buy: float = float(total_buy_spend) / float(total_buy_qty)
	if current_sell <= int(floor(avg_buy * 0.9)):
		return "Below your average buy"
	if current_sell >= int(ceil(avg_buy * 1.1)):
		return "Above your average buy"
	return "Near your average buy"
