extends Node

const RECENT_TRIP_LIMIT := 12
const RECENT_MORALE_LIMIT := 24
const GAME_SECONDS_PER_DAY := 86400.0
const REAL_SECONDS_PER_GAME_DAY := 900.0
const GAME_SECONDS_PER_REAL_SECOND := GAME_SECONDS_PER_DAY / REAL_SECONDS_PER_GAME_DAY
const START_OF_DAY_SECONDS := 8.0 * 3600.0
const WEATHER_ROLLOVER_HOUR := 2.0
const WEATHER_SUNNY := "sunny"
const WEATHER_RAINY := "rainy"
const WEATHER_STORM := "severe_storm"

var current_port_id: String = ""
var money: int = 0
var ship_id: String = ""
var ship_durability: int = 0
var supplies: int = 0
var cargo: Dictionary = {}
var owned_upgrades: Array[String] = []
var day_count: int = 1
var active_contracts: Array = []
var completed_contract_ids: Array[String] = []
var pending_status_message: String = ""

var reserve_ship_ids: Array[String] = []
var crew_count: int = 0
var officer_assignments: Dictionary = {}
var trust_rating: int = 0
var infamy_rating: int = 0
var tavern_candidates_by_port: Dictionary = {}
var market_trade_log: Array = []
var office_member: bool = false
var office_storage_by_port: Dictionary = {}
var morale: int = 0
var game_time_seconds: float = START_OF_DAY_SECONDS
var current_weather: String = WEATHER_SUNNY
var weather_cycle_index: int = 0
var known_port_ids: Array[String] = []
var ship_task_last_day: Dictionary = {}
var next_trip_chart_discount: float = 0.0

var recent_trip_reports: Array = []
var morale_history: Array[int] = []
var debug_contract_success_count: int = 0
var debug_contract_expiry_count: int = 0
var debug_contract_income_total: int = 0
var debug_event_income_total: int = 0

func _process(delta: float) -> void:
	advance_game_time_seconds(delta * GAME_SECONDS_PER_REAL_SECOND)

func new_game() -> void:
	current_port_id = "aurelia"
	money = 0
	ship_id = "rowboat"
	owned_upgrades = []
	ship_durability = get_effective_max_durability()
	supplies = 0
	cargo = {}
	day_count = 1
	active_contracts = []
	completed_contract_ids = []
	pending_status_message = ""
	reserve_ship_ids = []
	crew_count = 0
	officer_assignments = {}
	trust_rating = 0
	infamy_rating = 0
	tavern_candidates_by_port = {}
	market_trade_log = []
	office_member = false
	office_storage_by_port = {}
	morale = 0
	game_time_seconds = START_OF_DAY_SECONDS
	weather_cycle_index = _get_weather_cycle_index()
	_roll_weather_for_cycle(weather_cycle_index)
	known_port_ids = ["aurelia"]
	ship_task_last_day = {}
	next_trip_chart_discount = 0.0
	recent_trip_reports = []
	morale_history = []
	debug_contract_success_count = 0
	debug_contract_expiry_count = 0
	debug_contract_income_total = 0
	debug_event_income_total = 0
	_record_morale_snapshot()
	_sync_day_count_from_time()

func to_dict() -> Dictionary:
	return {
		"current_port_id": current_port_id,
		"money": money,
		"ship_id": ship_id,
		"ship_durability": ship_durability,
		"supplies": supplies,
		"cargo": cargo,
		"owned_upgrades": owned_upgrades,
		"day_count": day_count,
		"active_contracts": active_contracts,
		"completed_contract_ids": completed_contract_ids,
		"reserve_ship_ids": reserve_ship_ids,
		"crew_count": crew_count,
		"officer_assignments": officer_assignments,
		"trust_rating": trust_rating,
		"infamy_rating": infamy_rating,
		"tavern_candidates_by_port": tavern_candidates_by_port,
		"market_trade_log": market_trade_log,
		"office_member": office_member,
		"office_storage_by_port": office_storage_by_port,
		"morale": morale,
		"game_time_seconds": game_time_seconds,
		"current_weather": current_weather,
		"weather_cycle_index": weather_cycle_index,
		"known_port_ids": known_port_ids,
		"ship_task_last_day": ship_task_last_day,
		"next_trip_chart_discount": next_trip_chart_discount,
		"recent_trip_reports": recent_trip_reports,
		"morale_history": morale_history,
		"debug_contract_success_count": debug_contract_success_count,
		"debug_contract_expiry_count": debug_contract_expiry_count,
		"debug_contract_income_total": debug_contract_income_total,
		"debug_event_income_total": debug_event_income_total,
	}

func load_from_dict(data: Dictionary) -> void:
	current_port_id = data.get("current_port_id", "aurelia")
	money = int(data.get("money", 0))
	ship_id = data.get("ship_id", "rowboat")
	ship_durability = int(data.get("ship_durability", 100))
	supplies = int(data.get("supplies", 0))
	cargo = data.get("cargo", {})
	owned_upgrades = Array(data.get("owned_upgrades", []), TYPE_STRING, "", null)
	day_count = int(data.get("day_count", 1))
	active_contracts = _normalize_active_contracts(data.get("active_contracts", []))
	completed_contract_ids = Array(data.get("completed_contract_ids", []), TYPE_STRING, "", null)
	pending_status_message = ""
	reserve_ship_ids = Array(data.get("reserve_ship_ids", []), TYPE_STRING, "", null)
	crew_count = int(data.get("crew_count", 0))
	officer_assignments = data.get("officer_assignments", {})
	trust_rating = int(data.get("trust_rating", 0))
	infamy_rating = int(data.get("infamy_rating", 0))
	tavern_candidates_by_port = data.get("tavern_candidates_by_port", {})
	market_trade_log = data.get("market_trade_log", [])
	office_member = bool(data.get("office_member", false))
	office_storage_by_port = data.get("office_storage_by_port", {})
	morale = int(data.get("morale", 0))
	game_time_seconds = float(data.get("game_time_seconds", START_OF_DAY_SECONDS + max(0, day_count - 1) * GAME_SECONDS_PER_DAY))
	current_weather = str(data.get("current_weather", WEATHER_SUNNY))
	weather_cycle_index = int(data.get("weather_cycle_index", _get_weather_cycle_index()))
	known_port_ids = Array(data.get("known_port_ids", []), TYPE_STRING, "", null)
	ship_task_last_day = data.get("ship_task_last_day", {})
	next_trip_chart_discount = float(data.get("next_trip_chart_discount", 0.0))
	recent_trip_reports = data.get("recent_trip_reports", [])
	morale_history = Array(data.get("morale_history", []), TYPE_INT, "", null)
	debug_contract_success_count = int(data.get("debug_contract_success_count", 0))
	debug_contract_expiry_count = int(data.get("debug_contract_expiry_count", 0))
	debug_contract_income_total = int(data.get("debug_contract_income_total", 0))
	debug_event_income_total = int(data.get("debug_event_income_total", 0))
	if morale_history.is_empty():
		_record_morale_snapshot()
	_sync_day_count_from_time()
	crew_count = min(crew_count, get_effective_crew_capacity())
	if not current_ship_supports_personnel():
		officer_assignments = {}
	if known_port_ids.is_empty():
		known_port_ids = [current_port_id]
	if not current_port_id in known_port_ids:
		known_port_ids.append(current_port_id)
	if current_weather.is_empty():
		current_weather = WEATHER_SUNNY
	_update_weather_state()
	_normalize_morale()

func _normalize_active_contracts(raw_contracts: Array) -> Array:
	var normalized: Array = []
	for entry in raw_contracts:
		if entry is String:
			var contract_id: String = str(entry)
			var contract: Dictionary = GameData.contracts_by_id.get(contract_id, {})
			if contract.is_empty():
				continue
			var deadline_days: int = int(contract.get("deadline_days", 0))
			normalized.append({"contract_id": contract_id, "accepted_day": day_count, "deadline_day": day_count + deadline_days, "status": "active", "delivery_bonus": 0})
		elif entry is Dictionary:
			var contract_id_dict: String = str(entry.get("contract_id", ""))
			if contract_id_dict.is_empty() or GameData.contracts_by_id.get(contract_id_dict, {}).is_empty():
				continue
			var fallback_deadline: int = day_count + int(GameData.contracts_by_id[contract_id_dict].get("deadline_days", 0))
			normalized.append({
				"contract_id": contract_id_dict,
				"accepted_day": int(entry.get("accepted_day", day_count)),
				"deadline_day": int(entry.get("deadline_day", fallback_deadline)),
				"status": str(entry.get("status", "active")),
				"delivery_bonus": int(entry.get("delivery_bonus", 0)),
			})
	return normalized

func advance_game_time_seconds(seconds: float) -> void:
	if seconds <= 0.0:
		return
	game_time_seconds += seconds
	_sync_day_count_from_time()
	_update_weather_state()

func advance_game_time_days(days: float) -> void:
	if days <= 0.0:
		return
	advance_game_time_seconds(days * GAME_SECONDS_PER_DAY)

func set_game_time_seconds(total_seconds: float) -> void:
	game_time_seconds = max(0.0, total_seconds)
	_sync_day_count_from_time()
	_update_weather_state()

func sleep_until_next_morning() -> void:
	var current_day_index: int = int(floor(game_time_seconds / GAME_SECONDS_PER_DAY))
	var next_morning_seconds: float = (current_day_index + 1) * GAME_SECONDS_PER_DAY + 6.0 * 3600.0
	set_game_time_seconds(next_morning_seconds)

func _sync_day_count_from_time() -> void:
	day_count = 1 + int(floor(game_time_seconds / GAME_SECONDS_PER_DAY))

func _get_weather_cycle_index() -> int:
	return int(floor((game_time_seconds - WEATHER_ROLLOVER_HOUR * 3600.0) / GAME_SECONDS_PER_DAY))

func _update_weather_state() -> void:
	var cycle_index: int = _get_weather_cycle_index()
	if cycle_index != weather_cycle_index:
		weather_cycle_index = cycle_index
		_roll_weather_for_cycle(weather_cycle_index)

func _roll_weather_for_cycle(_cycle_index: int) -> void:
	var roll: float = randf()
	if roll < 0.02:
		current_weather = WEATHER_STORM
	elif roll < 0.20:
		current_weather = WEATHER_RAINY
	else:
		current_weather = WEATHER_SUNNY

func get_time_of_day_seconds() -> int:
	return int(fposmod(game_time_seconds, GAME_SECONDS_PER_DAY))

func get_clock_string() -> String:
	var seconds_of_day: int = get_time_of_day_seconds()
	var hours: int = int(seconds_of_day / 3600)
	var minutes: int = int((seconds_of_day % 3600) / 60)
	return "%02d:%02d" % [hours, minutes]

func get_day_and_time_string() -> String:
	return "Day %d | %s" % [day_count, get_clock_string()]

func get_weather_display_name() -> String:
	match current_weather:
		WEATHER_RAINY:
			return "Rainy"
		WEATHER_STORM:
			return "Severe Storm"
		_:
			return "Sunny"

func is_rainy_weather() -> bool:
	return current_weather == WEATHER_RAINY

func is_severe_storm_weather() -> bool:
	return current_weather == WEATHER_STORM

func get_ship_def() -> Dictionary:
	return GameData.get_ship(ship_id)

func current_ship_supports_personnel() -> bool:
	return bool(get_ship_def().get("supports_personnel", true))

func current_ship_can_install_upgrades() -> bool:
	return bool(get_ship_def().get("can_install_upgrades", true))

func discover_port(port_id: String) -> void:
	if port_id.is_empty():
		return
	if not port_id in known_port_ids:
		known_port_ids.append(port_id)

func has_known_port(port_id: String) -> bool:
	return port_id in known_port_ids

func _get_upgrade_bonus_int(key: String) -> int:
	var bonus: int = 0
	for upgrade_id in owned_upgrades:
		var upgrade: Dictionary = GameData.get_upgrade(upgrade_id)
		var effects: Dictionary = upgrade.get("effects", {})
		bonus += int(effects.get(key, 0))
	return bonus

func _get_upgrade_bonus_float(key: String) -> float:
	var bonus: float = 0.0
	for upgrade_id in owned_upgrades:
		var upgrade: Dictionary = GameData.get_upgrade(upgrade_id)
		var effects: Dictionary = upgrade.get("effects", {})
		bonus += float(effects.get(key, 0.0))
	return bonus

func get_effective_cargo_capacity() -> int:
	return max(0, int(get_ship_def().get("cargo_capacity", 0)) + _get_upgrade_bonus_int("cargo_capacity_bonus"))
func get_effective_max_durability() -> int:
	return max(1, int(get_ship_def().get("max_durability", 0)) + _get_upgrade_bonus_int("max_durability_bonus"))
func get_effective_supply_efficiency() -> float:
	return max(0.1, float(get_ship_def().get("supply_efficiency", 1.0)) + _get_upgrade_bonus_float("supply_efficiency_bonus"))
func get_effective_speed() -> float:
	return max(0.1, float(get_ship_def().get("speed", 1.0)) + _get_upgrade_bonus_float("speed_bonus"))
func get_effective_firepower() -> int:
	return max(0, int(get_ship_def().get("firepower", 0)) + _get_upgrade_bonus_int("firepower_bonus"))
func get_effective_hull_armor() -> int:
	return max(0, int(get_ship_def().get("hull_armor", 0)) + _get_upgrade_bonus_int("hull_armor_bonus"))
func get_effective_evasion() -> int:
	return max(0, int(get_ship_def().get("evasion", 0)) + _get_upgrade_bonus_int("evasion_bonus"))
func get_effective_intimidation() -> int:
	return max(0, int(get_ship_def().get("intimidation", 0)) + _get_upgrade_bonus_int("intimidation_bonus"))
func get_effective_crew_capacity() -> int:
	return max(0, int(get_ship_def().get("crew_capacity", 0)) + _get_upgrade_bonus_int("crew_capacity_bonus"))
func get_effective_officer_slots() -> int:
	return max(0, int(get_ship_def().get("officer_slots", 0)) + _get_upgrade_bonus_int("officer_slots_bonus"))
func get_effective_boarding_strength() -> int:
	return max(0, int(get_ship_def().get("boarding_strength", 0)) + _get_upgrade_bonus_int("boarding_strength_bonus"))

func get_current_cargo_used() -> int:
	var total: int = 0
	for good_id in cargo.keys():
		total += int(cargo[good_id]) * int(GameData.get_good(str(good_id)).get("cargo_size", 1))
	return total

func get_active_officer_count() -> int:
	return officer_assignments.size()
func get_officer(role: String) -> Dictionary:
	return officer_assignments.get(role, {})
func get_role_stat(role: String, stat_name: String) -> int:
	var officer: Dictionary = get_officer(role)
	if officer.is_empty():
		return 0
	return int(officer.get(stat_name, 0))
func get_morale_bonus() -> int:
	if crew_count <= 0:
		return 0
	return clamp(int(floor(float(morale - 50) / 10.0)), -4, 5)
func get_effective_navigation_rating() -> int:
	return get_role_stat("navigator", "navigation") + get_role_stat("captain", "leadership") + int(round(get_effective_speed() * 2.0))
func get_effective_repair_rating() -> int:
	return get_role_stat("carpenter", "repair") + get_role_stat("captain", "leadership")
func get_effective_gunnery_rating() -> int:
	return get_role_stat("gunner", "fighting") + get_role_stat("captain", "leadership")
func get_effective_command_rating() -> int:
	return get_role_stat("captain", "leadership") + get_role_stat("captain", "sailing")
func get_crew_discipline() -> int:
	return get_effective_command_rating() + int(ceil(float(crew_count) / 3.0)) + get_morale_bonus()
func get_travel_supply_discount() -> float:
	var discount: float = float(get_role_stat("navigator", "navigation")) * 0.03 + float(get_role_stat("captain", "leadership")) * 0.01 + next_trip_chart_discount
	return min(0.45, discount)
func get_repair_discount() -> float:
	var discount: float = float(get_role_stat("carpenter", "repair")) * 0.04 + float(get_role_stat("captain", "leadership")) * 0.015
	return min(0.35, discount)
func get_contract_bonus_multiplier() -> float:
	var bonus: float = 1.0 + float(get_role_stat("captain", "leadership")) * 0.04 + float(max(0, trust_rating)) * 0.005
	return min(1.35, bonus)
func get_passive_intimidation_bonus() -> int:
	return int(floor(float(get_role_stat("gunner", "fighting") + get_role_stat("captain", "leadership")) / 2.0)) + max(0, get_morale_bonus())

func get_crew_wages_due() -> int:
	return max(0, crew_count)
func get_officer_wages_due() -> int:
	return get_active_officer_count() * 4
func get_ship_upkeep_due() -> int:
	var ship: Dictionary = get_ship_def()
	if bool(ship.get("free_upkeep", false)):
		return 0
	var base_upkeep: int = int(ship.get("firepower", 0)) / 3 + int(ship.get("hull_armor", 0)) / 3 + int(ship.get("cargo_capacity", 0)) / 20
	var modified_upkeep: int = int(ceil(float(base_upkeep) * float(ship.get("upkeep_modifier", 1.0))))
	return max(2, modified_upkeep)
func get_total_upkeep_due() -> int:
	return get_crew_wages_due() + get_officer_wages_due() + get_ship_upkeep_due()
func change_morale(delta: int) -> void:
	if crew_count <= 0:
		morale = 0
		_record_morale_snapshot()
		return
	morale = clamp(morale + delta, 0, 100)
	_record_morale_snapshot()
func process_trip_costs() -> Dictionary:
	var crew_wages: int = get_crew_wages_due()
	var officer_wages: int = get_officer_wages_due()
	var upkeep: int = get_ship_upkeep_due()
	var total_due: int = crew_wages + officer_wages + upkeep
	var paid: int = min(money, total_due)
	money -= paid
	var unpaid: int = total_due - paid
	var morale_change: int = 0
	if crew_count > 0:
		morale_change = 1
		if unpaid > 0:
			morale_change = -min(20, 5 + unpaid / 2 - int(get_effective_command_rating() / 3))
	change_morale(morale_change)
	return {
		"crew_wages": crew_wages,
		"officer_wages": officer_wages,
		"ship_upkeep": upkeep,
		"total_due": total_due,
		"paid": paid,
		"unpaid": unpaid,
		"morale_change": morale_change,
	}
func recover_morale_in_port(amount: int) -> void:
	change_morale(amount)
func apply_crew_loss(loss: int) -> int:
	if loss <= 0:
		return 0
	var previous: int = crew_count
	crew_count = max(0, crew_count - loss)
	change_morale(-loss * 2)
	return previous - crew_count

func record_trip_report(report: Dictionary) -> void:
	recent_trip_reports.append(report)
	if recent_trip_reports.size() > RECENT_TRIP_LIMIT:
		recent_trip_reports = recent_trip_reports.slice(recent_trip_reports.size() - RECENT_TRIP_LIMIT, recent_trip_reports.size())

func record_contract_completed(payout_total: int) -> void:
	debug_contract_success_count += 1
	debug_contract_income_total += max(0, payout_total)

func record_contract_expired() -> void:
	debug_contract_expiry_count += 1

func get_balance_debug_report() -> String:
	var lines: Array[String] = []
	var trip_count: int = recent_trip_reports.size()
	lines.append("Recent trips tracked: %d" % trip_count)

	if trip_count == 0:
		lines.append("No completed trips yet.")
	else:
		var total_delta: int = 0
		var total_upkeep_paid: int = 0
		var total_morale_delta: int = 0
		var best_delta: int = -999999
		var worst_delta: int = 999999
		var positive_trips: int = 0
		for report in recent_trip_reports:
			var money_delta: int = int(report.get("money_delta", 0))
			total_delta += money_delta
			total_upkeep_paid += int(report.get("upkeep_paid", 0))
			total_morale_delta += int(report.get("morale_after", 0)) - int(report.get("morale_before", 0))
			best_delta = max(best_delta, money_delta)
			worst_delta = min(worst_delta, money_delta)
			if money_delta >= 0:
				positive_trips += 1
		var last_trip: Dictionary = recent_trip_reports.back()
		lines.append("Trip Δmoney avg %d | best %d | worst %d | positive %d/%d" % [int(round(float(total_delta) / float(trip_count))), best_delta, worst_delta, positive_trips, trip_count])
		lines.append("Last trip: %s -> %s | Δmoney %d | upkeep paid %d" % [str(last_trip.get("from_port_name", "?")), str(last_trip.get("to_port_name", "?")), int(last_trip.get("money_delta", 0)), int(last_trip.get("upkeep_paid", 0))])
		lines.append("Recent upkeep avg %d/trip | morale Δ avg %d/trip" % [int(round(float(total_upkeep_paid) / float(trip_count))), int(round(float(total_morale_delta) / float(trip_count)))])

	var trade_sell_income: int = 0
	var profit_by_good: Dictionary = {}
	for entry in market_trade_log:
		var entry_type: String = str(entry.get("type", ""))
		var good_id: String = str(entry.get("good_id", ""))
		var total_value: int = int(entry.get("price", 0)) * int(entry.get("quantity", 0))
		if entry_type == "buy":
			profit_by_good[good_id] = int(profit_by_good.get(good_id, 0)) - total_value
		elif entry_type == "sell":
			trade_sell_income += total_value
			profit_by_good[good_id] = int(profit_by_good.get(good_id, 0)) + total_value

	var total_income: int = trade_sell_income + debug_contract_income_total + debug_event_income_total
	var upkeep_paid_total: int = 0
	for report in recent_trip_reports:
		upkeep_paid_total += int(report.get("upkeep_paid", 0))
	var burden_text := "n/a"
	if total_income > 0:
		burden_text = "%d%%" % int(round((float(upkeep_paid_total) / float(total_income)) * 100.0))
	lines.append("Upkeep burden: recent paid %d vs total income %d (%s)" % [upkeep_paid_total, total_income, burden_text])
	lines.append("Contracts: %d completed | %d expired" % [debug_contract_success_count, debug_contract_expiry_count])

	if morale_history.is_empty():
		lines.append("Morale trend: current %d" % morale)
	else:
		var min_morale: int = morale_history[0]
		var max_morale: int = morale_history[0]
		var total_morale: int = 0
		for morale_value in morale_history:
			min_morale = min(min_morale, int(morale_value))
			max_morale = max(max_morale, int(morale_value))
			total_morale += int(morale_value)
		lines.append("Morale trend: current %d | avg %d | min %d | max %d" % [morale, int(round(float(total_morale) / float(morale_history.size()))), min_morale, max_morale])

	var good_entries: Array[Dictionary] = []
	for good_id in profit_by_good.keys():
		good_entries.append({"good_id": str(good_id), "profit": int(profit_by_good[good_id])})
	good_entries.sort_custom(_sort_good_entries_desc)
	if good_entries.is_empty():
		lines.append("Top goods: no realized trade data yet")
	else:
		var parts: Array[String] = []
		for i in range(min(3, good_entries.size())):
			var good_entry: Dictionary = good_entries[i]
			var good_name: String = str(GameData.get_good(str(good_entry.get("good_id", ""))).get("name", str(good_entry.get("good_id", ""))))
			var profit: int = int(good_entry.get("profit", 0))
			parts.append("%s %s%d" % [good_name, "+" if profit >= 0 else "", profit])
		lines.append("Top goods: %s" % ", ".join(parts))

	return "\n".join(lines)

func _sort_good_entries_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("profit", 0)) > int(b.get("profit", 0))

func _record_morale_snapshot() -> void:
	morale_history.append(morale)
	if morale_history.size() > RECENT_MORALE_LIMIT:
		morale_history = morale_history.slice(morale_history.size() - RECENT_MORALE_LIMIT, morale_history.size())

func _normalize_morale() -> void:
	if crew_count <= 0:
		morale = 0

func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in owned_upgrades
func apply_upgrade(upgrade_id: String) -> void:
	if not has_upgrade(upgrade_id):
		owned_upgrades.append(upgrade_id)
		ship_durability = min(ship_durability, get_effective_max_durability())
		crew_count = min(crew_count, get_effective_crew_capacity())
		_normalize_morale()

func add_cargo(good_id: String, qty: int) -> void:
	cargo[good_id] = int(cargo.get(good_id, 0)) + qty
	if int(cargo[good_id]) <= 0:
		cargo.erase(good_id)

func add_market_log_entry(entry: Dictionary) -> void:
	for i in range(market_trade_log.size() - 1, -1, -1):
		var existing: Dictionary = market_trade_log[i]
		if int(existing.get("day", -1)) == int(entry.get("day", -2)) and str(existing.get("type", "")) == str(entry.get("type", "")) and str(existing.get("port_id", "")) == str(entry.get("port_id", "")) and str(existing.get("good_id", "")) == str(entry.get("good_id", "")) and int(existing.get("price", -1)) == int(entry.get("price", -2)):
			existing["quantity"] = int(existing.get("quantity", 0)) + int(entry.get("quantity", 0))
			market_trade_log[i] = existing
			return
	market_trade_log.append(entry)
	if market_trade_log.size() > 60:
		market_trade_log = market_trade_log.slice(market_trade_log.size() - 60, market_trade_log.size())

func get_market_entries_for_good(good_id: String) -> Array:
	var matches: Array = []
	for entry in market_trade_log:
		if str(entry.get("good_id", "")) == good_id:
			matches.append(entry)
	return matches

func get_office_storage(port_id: String) -> Dictionary:
	return office_storage_by_port.get(port_id, {})

func set_office_storage(port_id: String, storage: Dictionary) -> void:
	office_storage_by_port[port_id] = storage

func change_reputation(trust_delta: int, infamy_delta: int) -> void:
	trust_rating += trust_delta
	infamy_rating += infamy_delta

func apply_event_effects(effects: Dictionary) -> void:
	ship_durability = max(0, ship_durability - int(effects.get("durability_loss", 0)))
	supplies -= int(effects.get("supply_loss", 0))
	var money_loss: int = int(effects.get("money_loss", 0))
	if money_loss < 0:
		debug_event_income_total += abs(money_loss)
	money -= money_loss
	var crew_loss: int = int(effects.get("crew_loss", 0))
	if crew_loss > 0:
		apply_crew_loss(crew_loss)
	var cargo_loss_percent: float = float(effects.get("cargo_loss_percent", 0.0))
	if cargo_loss_percent > 0.0:
		for good_id in cargo.keys().duplicate():
			var good_id_str: String = str(good_id)
			var qty: int = int(cargo[good_id_str])
			var lost: int = int(floor(qty * cargo_loss_percent))
			cargo[good_id_str] = max(0, qty - lost)
			if int(cargo[good_id_str]) == 0:
				cargo.erase(good_id_str)
	supplies = max(0, supplies)
	money = max(0, money)
	_normalize_morale()
