class_name EventSystem
extends RefCounted

func roll_event(route_risk: float) -> Dictionary:
	if randf() >= route_risk:
		return {"triggered": false}
	var eligible: Array = get_eligible_events(route_risk)
	if eligible.is_empty():
		return {"triggered": false}
	var event_data: Dictionary = choose_weighted_event(eligible)
	if str(event_data.get("type", "")) == "pirates":
		return create_pirate_encounter(event_data, route_risk)
	var applied: Dictionary = apply_event(event_data)
	applied["triggered"] = true
	return applied

func get_eligible_events(route_risk: float) -> Array:
	var eligible: Array = []
	for event_data in GameData.events_list:
		if float(event_data.get("min_risk", 0.0)) <= route_risk:
			eligible.append(event_data)
	return eligible

func choose_weighted_event(events: Array) -> Dictionary:
	var total_weight: float = 0.0
	for event_data in events:
		total_weight += float(event_data.get("weight", 1.0))
	var roll: float = randf() * total_weight
	var running: float = 0.0
	for event_data in events:
		running += float(event_data.get("weight", 1.0))
		if roll <= running:
			return event_data
	return events.back()

func apply_event(event_data: Dictionary) -> Dictionary:
	var effects: Dictionary = _adjust_effects_for_officers(event_data.get("effects", {}), str(event_data.get("type", "")))
	GameState.apply_event_effects(effects)
	return {
		"event_id": event_data.get("id", ""),
		"name": event_data.get("name", "Unknown Event"),
		"text": event_data.get("text", ""),
		"outcome_text": _build_outcome_text(effects),
		"effects": effects,
	}

func create_pirate_encounter(event_data: Dictionary, route_risk: float) -> Dictionary:
	var pirate_power: int = 5 + int(round(route_risk * 10.0))
	if str(event_data.get("id", "")) == "pirates_raid":
		pirate_power += 3
	return {
		"event_id": event_data.get("id", ""),
		"name": event_data.get("name", "Pirates"),
		"text": "%s\n\nYour officers shout over the surf. Choose how to respond." % str(event_data.get("text", "")),
		"event_type": "pirates",
		"triggered": true,
		"unresolved": true,
		"pirate_power": pirate_power,
		"choice_options": [
			{"id": "flee", "label": "Flee"},
			{"id": "fight", "label": "Fight"},
			{"id": "intimidate", "label": "Intimidate"},
			{"id": "surrender", "label": "Surrender Cargo"}
		]
	}

func resolve_event_choice(payload: Dictionary, choice_id: String) -> Dictionary:
	if str(payload.get("event_type", "")) == "pirates":
		return _resolve_pirate_choice(payload, choice_id)
	payload["unresolved"] = false
	return payload

func _resolve_pirate_choice(payload: Dictionary, choice_id: String) -> Dictionary:
	var pirate_power: int = int(payload.get("pirate_power", 5))
	var effects: Dictionary = {}
	var outcome_text: String = ""
	var trust_delta: int = 0
	var infamy_delta: int = 0
	var roll_bonus: int = randi() % 4
	if choice_id == "flee":
		var flee_score: int = GameState.get_effective_evasion() + GameState.get_effective_navigation_rating()
		if flee_score + roll_bonus >= pirate_power + 6:
			effects = {"durability_loss": 0, "supply_loss": 1, "money_loss": 0, "cargo_loss_percent": 0.0}
			outcome_text = "Your navigator threads the ship through danger and you slip away with only extra supply usage."
		else:
			effects = {"durability_loss": max(4, pirate_power), "supply_loss": 1, "money_loss": 8 + pirate_power, "cargo_loss_percent": 0.05}
			outcome_text = "The pirates catch your stern during the escape and force losses before breaking off."
	elif choice_id == "fight":
		var offense: int = GameState.get_effective_firepower() + GameState.get_effective_boarding_strength() + GameState.get_effective_gunnery_rating() + int(GameState.crew_count / 2)
		var defense: int = GameState.get_effective_hull_armor() + GameState.get_effective_repair_rating()
		if offense + defense + roll_bonus >= pirate_power + 8:
			effects = {"durability_loss": max(1, int(pirate_power / 3)), "supply_loss": 0, "money_loss": -(8 + pirate_power), "cargo_loss_percent": 0.0}
			outcome_text = "Your gunnery drives the raiders off and your crew hauls captured loot aboard."
			trust_delta = 1
			infamy_delta = 1
		else:
			effects = {"durability_loss": pirate_power + 6, "supply_loss": 1, "money_loss": 10 + pirate_power, "cargo_loss_percent": 0.10}
			outcome_text = "The exchange turns ugly. You survive, but the pirates leave splintered hulls and lighter purses behind."
			infamy_delta = 1
	elif choice_id == "intimidate":
		var intimidate_score: int = GameState.get_effective_intimidation() + GameState.get_effective_command_rating() + int(GameState.infamy_rating / 2)
		if intimidate_score + roll_bonus >= pirate_power + 7:
			effects = {"durability_loss": 0, "supply_loss": 0, "money_loss": 0, "cargo_loss_percent": 0.0}
			outcome_text = "Your ship looks dangerous enough that the raiders decide to look for easier prey."
			trust_delta = -1
			infamy_delta = 2
		else:
			effects = {"durability_loss": 4 + int(pirate_power / 2), "supply_loss": 0, "money_loss": 6 + pirate_power, "cargo_loss_percent": 0.0}
			outcome_text = "The bluff fails. The raiders test your resolve and exact a price before retreating."
			infamy_delta = 1
		else:
			effects = {"durability_loss": 0, "supply_loss": 0, "money_loss": 8 + pirate_power, "cargo_loss_percent": 0.05}
			outcome_text = "You throw cargo and coin overboard to buy safe passage."
	var adjusted_effects: Dictionary = _adjust_effects_for_officers(effects, "pirates")
	GameState.apply_event_effects(adjusted_effects)
	GameState.change_reputation(trust_delta, infamy_delta)
	payload["unresolved"] = false
	payload["effects"] = adjusted_effects
	payload["outcome_text"] = "%s\n%s" % [_build_outcome_text(adjusted_effects), outcome_text]
	return payload

func _adjust_effects_for_officers(raw_effects: Dictionary, event_type: String) -> Dictionary:
	var effects: Dictionary = raw_effects.duplicate(true)
	var durability_loss: int = int(effects.get("durability_loss", 0))
	var supply_loss: int = int(effects.get("supply_loss", 0))
	var money_loss: int = int(effects.get("money_loss", 0))
	if durability_loss > 0:
		durability_loss = max(0, durability_loss - int(GameState.get_effective_repair_rating() / 4))
	if supply_loss > 0:
		supply_loss = max(0, supply_loss - int(GameState.get_effective_navigation_rating() / 6))
	if money_loss > 0 and event_type == "pirates":
		money_loss = max(0, money_loss - int(GameState.get_effective_command_rating() / 3))
	effects["durability_loss"] = durability_loss
	effects["supply_loss"] = supply_loss
	effects["money_loss"] = money_loss
	return effects

func _build_outcome_text(effects: Dictionary) -> String:
	var outcome_parts: Array[String] = []
	var durability_loss: int = int(effects.get("durability_loss", 0))
	var supply_loss: int = int(effects.get("supply_loss", 0))
	var money_loss: int = int(effects.get("money_loss", 0))
	var cargo_loss_percent: float = float(effects.get("cargo_loss_percent", 0.0))
	if durability_loss != 0:
		outcome_parts.append("Durability %s%d" % ["-" if durability_loss > 0 else "+", abs(durability_loss)])
	if supply_loss != 0:
		outcome_parts.append("Supplies %s%d" % ["-" if supply_loss > 0 else "+", abs(supply_loss)])
	if money_loss != 0:
		if money_loss > 0:
			outcome_parts.append("Money -%d" % money_loss)
		else:
			outcome_parts.append("Money +%d" % abs(money_loss))
	if cargo_loss_percent > 0.0:
		outcome_parts.append("Cargo loss %d%%" % int(round(cargo_loss_percent * 100.0)))
	if outcome_parts.is_empty():
		return "No immediate losses."
	return ", ".join(outcome_parts)
