class_name ChandlerySystem
extends RefCounted

func get_max_supplies() -> int:
	return 12

func get_unit_cost() -> int:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	return int(ceil(4.0 * float(port.get("supply_cost_modifier", 1.0))))

func get_missing_supplies() -> int:
	return max(0, get_max_supplies() - GameState.supplies)

func get_max_affordable_supplies() -> int:
	return min(get_missing_supplies(), int(GameState.money / max(1, get_unit_cost())))

func buy_supplies(amount: int) -> Dictionary:
	if amount <= 0:
		return {"success": false, "message": "Choose a positive amount."}
	if amount > get_missing_supplies():
		return {"success": false, "message": "That would exceed storage."}
	var cost: int = amount * get_unit_cost()
	if GameState.money < cost:
		return {"success": false, "message": "Not enough money for that many supplies."}
	GameState.money -= cost
	GameState.supplies += amount
	return {"success": true, "message": "Bought %d supplies for %d." % [amount, cost]}
