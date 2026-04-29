extends Node

## Focused facade for money, market ledger, upkeep, and balance debug data.
##
## This service keeps GameState as the backing store in the first pass while giving
## economy-facing code a more focused API to migrate toward.

func get_money() -> int:
	return GameState.money

func set_money(value: int) -> void:
	GameState.money = value

func add_money(amount: int) -> void:
	GameState.money += amount

func can_afford(amount: int) -> bool:
	return GameState.money >= amount

func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true
	if GameState.money < amount:
		return false
	GameState.money -= amount
	return true

func get_market_trade_log() -> Array:
	return GameState.market_trade_log

func add_market_log_entry(entry: Dictionary) -> void:
	GameState.add_market_log_entry(entry)

func get_market_entries_for_good(good_id: String) -> Array:
	return GameState.get_market_entries_for_good(good_id)

func get_crew_wages_due() -> int:
	return GameState.get_crew_wages_due()

func get_officer_wages_due() -> int:
	return GameState.get_officer_wages_due()

func get_ship_upkeep_due() -> int:
	return GameState.get_ship_upkeep_due()

func get_total_upkeep_due() -> int:
	return GameState.get_total_upkeep_due()

func process_trip_costs() -> Dictionary:
	return GameState.process_trip_costs()

func record_trip_report(report: Dictionary) -> void:
	GameState.record_trip_report(report)

func record_contract_completed(payout_total: int) -> void:
	GameState.record_contract_completed(payout_total)

func record_contract_expired() -> void:
	GameState.record_contract_expired()

func get_balance_debug_report() -> String:
	return GameState.get_balance_debug_report()

func get_recent_trip_reports() -> Array:
	return GameState.recent_trip_reports

func get_contract_success_count() -> int:
	return GameState.debug_contract_success_count

func get_contract_expiry_count() -> int:
	return GameState.debug_contract_expiry_count
