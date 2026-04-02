class_name ShipBoardSystem
extends RefCounted

const TASK_SLEEP := "sleep_aboard"
const TASK_RIGGING := "inspect_rigging"
const TASK_CHARTS := "review_charts"
const TASK_BRIEFING := "crew_briefing"
const TASK_GALLEY := "cook_hot_meal"

func can_access_ship_screen() -> bool:
	return GameState.current_ship_supports_personnel()

func get_station_flags() -> Dictionary:
	var ship: Dictionary = GameState.get_ship_def()
	var crew_capacity: int = int(ship.get("crew_capacity", 0))
	var firepower: int = int(ship.get("firepower", 0))
	return {
		"has_berth": can_access_ship_screen(),
		"has_map_table": can_access_ship_screen(),
		"has_supply_hold": true,
		"has_galley": crew_capacity >= 12,
		"has_water_system": crew_capacity >= 12,
		"has_combat_station": firepower > 0,
	}

func get_known_world_summary() -> String:
	var names: Array[String] = []
	for port_id in GameState.known_port_ids:
		var port_name: String = str(GameData.get_port(port_id).get("name", port_id))
		if port_id == GameState.current_port_id:
			names.append("%s (current)" % port_name)
		else:
			names.append(port_name)
	if names.is_empty():
		return "Only the waters around your current harbor are familiar to you."
	return "Known ports: %s" % ", ".join(names)

func get_task_cards() -> Array:
	var flags: Dictionary = get_station_flags()
	var cards: Array = []
	cards.append(_task_card(TASK_SLEEP, "Sleep Aboard", "Turn in aboard ship and wake at 06:00 the next morning.", true, true, "A steady, private rest aboard your own berth."))
	cards.append(_task_card(TASK_RIGGING, "Inspect Rigging", "Tighten lines and check wear to recover a little durability.", _task_available_today(TASK_RIGGING), true, "Once per day."))
	cards.append(_task_card(TASK_CHARTS, "Review Charts", "Study your route notes to gain a bonus to the next trip's supply efficiency.", _task_available_today(TASK_CHARTS), true, "Once per day. Grants a next-trip bonus."))
	cards.append(_task_card(TASK_BRIEFING, "Crew Briefing", "Set the tone for the ship and steady the crew before the next departure.", _task_available_today(TASK_BRIEFING) and GameState.crew_count > 0, GameState.crew_count > 0, "Requires crew. Once per day."))
	cards.append(_task_card(TASK_GALLEY, "Cook Hot Meal", "Use ship stores to raise morale with a proper meal below decks.", _task_available_today(TASK_GALLEY) and bool(flags.get("has_galley", false)) and GameState.supplies > 0 and GameState.crew_count > 0, bool(flags.get("has_galley", false)), "Requires galley, crew, and 1 supply."))
	return cards

func perform_task(task_id: String) -> Dictionary:
	match task_id:
		TASK_SLEEP:
			GameState.sleep_until_next_morning()
			if GameState.crew_count > 0:
				GameState.recover_morale_in_port(4)
			return {"success": true, "message": "You turn in aboard ship and wake at 06:00 ready for the new day."}
		TASK_RIGGING:
			if not _task_available_today(TASK_RIGGING):
				return {"success": false, "message": "You already worked the rigging today."}
			GameState.ship_task_last_day[TASK_RIGGING] = GameState.day_count
			GameState.advance_game_time_seconds(2.0 * 3600.0)
			GameState.ship_durability = min(GameState.get_effective_max_durability(), GameState.ship_durability + 4)
			return {"success": true, "message": "You spend the watch checking lines and fittings, recovering 4 durability."}
		TASK_CHARTS:
			if not _task_available_today(TASK_CHARTS):
				return {"success": false, "message": "You have already reviewed the charts today."}
			GameState.ship_task_last_day[TASK_CHARTS] = GameState.day_count
			GameState.advance_game_time_seconds(1.0 * 3600.0)
			GameState.next_trip_chart_discount = 0.12
			return {"success": true, "message": "You review your route notes and set a cleaner course. Your next trip will use fewer supplies."}
		TASK_BRIEFING:
			if GameState.crew_count <= 0:
				return {"success": false, "message": "There is no crew to brief."}
			if not _task_available_today(TASK_BRIEFING):
				return {"success": false, "message": "You have already briefed the crew today."}
			GameState.ship_task_last_day[TASK_BRIEFING] = GameState.day_count
			GameState.advance_game_time_seconds(1.0 * 3600.0)
			GameState.recover_morale_in_port(5)
			return {"success": true, "message": "A steady word with the crew lifts morale and sharpens discipline."}
		TASK_GALLEY:
			var flags: Dictionary = get_station_flags()
			if not bool(flags.get("has_galley", false)):
				return {"success": false, "message": "This ship does not yet have a galley worth cooking in."}
			if GameState.crew_count <= 0:
				return {"success": false, "message": "There is no crew aboard to cook for."}
			if GameState.supplies <= 0:
				return {"success": false, "message": "You do not have enough stores to cook a meal."}
			if not _task_available_today(TASK_GALLEY):
				return {"success": false, "message": "The galley has already been put to use today."}
			GameState.ship_task_last_day[TASK_GALLEY] = GameState.day_count
			GameState.advance_game_time_seconds(2.0 * 3600.0)
			GameState.supplies -= 1
			GameState.recover_morale_in_port(8)
			return {"success": true, "message": "A hot meal from the galley costs 1 supply but lifts the whole ship's spirits."}
		_:
			return {"success": false, "message": "That shipboard task is unavailable."}

func get_station_descriptions() -> Array:
	var flags: Dictionary = get_station_flags()
	var stations: Array = []
	stations.append(_station_entry("Berth", "Your private resting place aboard ship.", bool(flags.get("has_berth", false))))
	stations.append(_station_entry("Map Table", "A place to review known ports and routes.", bool(flags.get("has_map_table", false))))
	stations.append(_station_entry("Supply Hold", "Your shipboard stores and provisions.", bool(flags.get("has_supply_hold", false))))
	stations.append(_station_entry("Galley", "Cook meals and improve morale on larger ships.", bool(flags.get("has_galley", false))))
	stations.append(_station_entry("Water System", "Rain catchment and cask management for longer voyages.", bool(flags.get("has_water_system", false))))
	stations.append(_station_entry("Combat Station", "Access guns, boarding prep, and battle readiness.", bool(flags.get("has_combat_station", false))))
	return stations

func _task_available_today(task_id: String) -> bool:
	return int(GameState.ship_task_last_day.get(task_id, -9999)) != GameState.day_count

func _task_card(id: String, name: String, description: String, enabled: bool, unlocked: bool, note: String) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"enabled": enabled,
		"unlocked": unlocked,
		"note": note,
	}

func _station_entry(name: String, description: String, unlocked: bool) -> Dictionary:
	return {
		"name": name,
		"description": description,
		"unlocked": unlocked,
	}
