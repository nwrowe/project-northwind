class_name RepairSystem
extends RefCounted

func get_current_port() -> Dictionary:
	return GameData.get_port(GameState.current_port_id)

func get_missing_durability() -> int:
	return max(0, GameState.get_effective_max_durability() - GameState.ship_durability)

func get_repair_rate() -> float:
	var port: Dictionary = get_current_port()
	var base_rate: float = 1.5 * float(port.get("repair_cost_modifier", 1.0))
	return max(0.5, base_rate * (1.0 - GameState.get_repair_discount()))

func get_repair_cost(points: int) -> int:
	if points <= 0:
		return 0
	return int(ceil(points * get_repair_rate()))

func get_full_repair_cost() -> int:
	return get_repair_cost(get_missing_durability())

func get_max_affordable_repair_points() -> int:
	var missing: int = get_missing_durability()
	if missing <= 0:
		return 0
	var affordable: int = 0
	for points in range(1, missing + 1):
		if get_repair_cost(points) <= GameState.money:
			affordable = points
		else:
			break
	return affordable

func can_repair(points: int) -> bool:
	if points <= 0:
		return false
	if points > get_missing_durability():
		return false
	return GameState.money >= get_repair_cost(points)

func repair(points: int) -> Dictionary:
	var missing: int = get_missing_durability()
	if missing <= 0:
		return {"success": false, "message": "Ship is already fully repaired."}
	if points <= 0:
		return {"success": false, "message": "Choose a positive repair amount."}
	points = min(points, missing)
	var cost: int = get_repair_cost(points)
	if GameState.money < cost:
		return {"success": false, "message": "Not enough money to repair %d durability." % points}
	GameState.money -= cost
	GameState.ship_durability = min(GameState.get_effective_max_durability(), GameState.ship_durability + points)
	var message: String = "Repaired %d durability for %d coins." % [points, cost]
	if GameState.get_repair_discount() > 0.0:
		message += " Carpenter efficiencies reduced repair cost by %.0f%%." % (GameState.get_repair_discount() * 100.0)
	return {"success": true, "message": message, "points": points, "cost": cost}

func repair_full() -> Dictionary:
	return repair(get_missing_durability())

func repair_max_affordable() -> Dictionary:
	var points: int = get_max_affordable_repair_points()
	if points <= 0:
		return {"success": false, "message": "Cannot afford any repair right now."}
	return repair(points)
