class_name AureliaBootstrapSystem
extends RefCounted

const HOME_PORT_ID := "aurelia"
const SUPPLY_CAP := 12

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func can_access() -> bool:
	return GameState.current_port_id == HOME_PORT_ID

func get_jobs() -> Array:
	var jobs: Array = []
	jobs.append(_job_dict(
		"haul_crates",
		"Haul Fish Crates",
		"Carry wet fish crates from the old dock to the market sheds.",
		2,
		4,
		0,
		"Steady pay. No equipment required."
	))
	jobs.append(_job_dict(
		"mend_nets",
		"Mend Torn Nets",
		"Sit with the fishers and patch salt-stiff nets for the morning boats.",
		3,
		5,
		0,
		"Slow work, but the pay is reliable."
	))
	if GameState.ship_id == "rowboat":
		jobs.append(_job_dict(
			"harbor_run",
			"Run Harbor Messages",
			"Use the rowboat to shuttle notes and parcels between the quay and outlying moorings.",
			4,
			6,
			1,
			"Best-paying rowboat work in Aurelia."
		))
	if _is_tide_window():
		jobs.append(_job_dict(
			"beachcomb",
			"Beachcomb the Tide Line",
			"Search the shoals for driftwood, shellfish, and anything the sea gives back.",
			2,
			3,
			1,
			"Only worthwhile around the changing tide."
		))
	return jobs

func get_goal_summary() -> String:
	var next_route_cost: int = _get_cheapest_route_supply_cost()
	var chandlery_cost: int = _get_supply_unit_cost()
	var ship_price: int = _get_coastal_sloop_price()
	var lines: Array[String] = []
	lines.append("Aurelia is too small for contracts or office work, so you survive by odd jobs.")
	if next_route_cost > 0:
		lines.append("Leaving port soon: %d supply needed for the cheapest route (%d gold at the chandlery)." % [next_route_cost, next_route_cost * chandlery_cost])
	lines.append("Longer-term goal: save %d gold for a Coastal Sloop." % ship_price)
	return "\n".join(lines)

func do_job(job_id: String) -> Dictionary:
	if not can_access():
		return {"success": false, "message": "Dockside work is only available in Aurelia."}

	match job_id:
		"haul_crates":
			return _apply_job_result(2, 4, 0, 0, "You spend the shift hauling crates and earn 4 gold.")
		"mend_nets":
			return _apply_job_result(3, 5, 0, 0, "You patch nets until your fingers ache and earn 5 gold.")
		"harbor_run":
			if GameState.ship_id != "rowboat":
				return {"success": false, "message": "That job is only offered to someone still rowing the harbor by hand."}
			return _apply_job_result(4, 6, 1, 1, "You row messages across the harbor and come back with 6 gold and a ration of supplies.")
		"beachcomb":
			if not _is_tide_window():
				return {"success": false, "message": "The tide is wrong for worthwhile beachcombing right now."}
				
			var found_gold: int = rng.randi_range(1, 3)
			var found_supply: int = 1 if rng.randf() < 0.55 else 0
			var message := "You comb the tide line and scrape together %d gold" % found_gold
			if found_supply > 0:
				message += " plus a usable bundle of provisions."
			else:
				message += "."
			return _apply_job_result(2, found_gold, found_supply, 0, message)
		_:
			return {"success": false, "message": "That job is no longer available."}

func _apply_job_result(hours: int, gold: int, supplies: int, trust: int, message: String) -> Dictionary:
	GameState.advance_game_time_seconds(float(hours) * 3600.0)
	GameState.money += gold
	if supplies > 0:
		GameState.supplies = min(SUPPLY_CAP, GameState.supplies + supplies)
	if trust != 0:
		GameState.change_reputation(trust, 0)
	GameState.pending_status_message = message
	return {
		"success": true,
		"message": message,
		"hours": hours,
		"gold": gold,
		"supplies": supplies,
		"trust": trust,
	}

func _job_dict(id: String, name: String, description: String, hours: int, gold: int, supplies: int, note: String) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"hours": hours,
		"gold": gold,
		"supplies": supplies,
		"note": note,
	}

func _get_cheapest_route_supply_cost() -> int:
	var travel_system := TravelSystem.new()
	var cheapest := 999999
	for route in GameData.get_routes_from(GameState.current_port_id):
		cheapest = min(cheapest, travel_system.get_supply_cost(route))
	return 0 if cheapest == 999999 else cheapest

func _get_supply_unit_cost() -> int:
	var chandlery := ChandlerySystem.new()
	return chandlery.get_unit_cost()

func _get_coastal_sloop_price() -> int:
	return int(GameData.get_ship("coastal_sloop").get("base_price", 120))

func _is_tide_window() -> bool:
	var seconds_of_day: int = GameState.get_time_of_day_seconds()
	var hour: int = int(seconds_of_day / 3600)
	return (hour >= 5 and hour <= 10) or (hour >= 16 and hour <= 20)
