extends Node

## Focused facade for crew, officers, morale, and reputation.
##
## This delegates to GameState in the first refactor so behavior and save formats
## stay stable while future code can depend on a smaller service surface.

func get_crew_count() -> int:
	return GameState.crew_count

func set_crew_count(value: int) -> void:
	GameState.crew_count = clamp(value, 0, get_effective_crew_capacity())
	if GameState.crew_count <= 0:
		GameState.morale = 0

func get_effective_crew_capacity() -> int:
	return GameState.get_effective_crew_capacity()

func get_effective_officer_slots() -> int:
	return GameState.get_effective_officer_slots()

func get_active_officer_count() -> int:
	return GameState.get_active_officer_count()

func get_officer(role: String) -> Dictionary:
	return GameState.get_officer(role)

func get_officer_assignments() -> Dictionary:
	return GameState.officer_assignments

func assign_officer(role: String, officer: Dictionary) -> void:
	GameState.officer_assignments[role] = officer

func clear_officers() -> void:
	GameState.officer_assignments = {}

func get_morale() -> int:
	return GameState.morale

func change_morale(delta: int) -> void:
	GameState.change_morale(delta)

func recover_morale_in_port(amount: int) -> void:
	GameState.recover_morale_in_port(amount)

func get_morale_bonus() -> int:
	return GameState.get_morale_bonus()

func apply_crew_loss(loss: int) -> int:
	return GameState.apply_crew_loss(loss)

func get_effective_navigation_rating() -> int:
	return GameState.get_effective_navigation_rating()

func get_effective_repair_rating() -> int:
	return GameState.get_effective_repair_rating()

func get_effective_gunnery_rating() -> int:
	return GameState.get_effective_gunnery_rating()

func get_effective_command_rating() -> int:
	return GameState.get_effective_command_rating()

func get_crew_discipline() -> int:
	return GameState.get_crew_discipline()

func get_travel_supply_discount() -> float:
	return GameState.get_travel_supply_discount()

func get_repair_discount() -> float:
	return GameState.get_repair_discount()

func get_contract_bonus_multiplier() -> float:
	return GameState.get_contract_bonus_multiplier()

func get_passive_intimidation_bonus() -> int:
	return GameState.get_passive_intimidation_bonus()

func get_trust_rating() -> int:
	return GameState.trust_rating

func get_infamy_rating() -> int:
	return GameState.infamy_rating

func change_reputation(trust_delta: int, infamy_delta: int) -> void:
	GameState.change_reputation(trust_delta, infamy_delta)
