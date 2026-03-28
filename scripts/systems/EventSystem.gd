class_name EventSystem
extends RefCounted

func roll_event(route_risk: float) -> Dictionary:
	if randf() >= route_risk:
		return {"triggered": false}

	var eligible := get_eligible_events(route_risk)
	if eligible.is_empty():
		return {"triggered": false}

	var event_data := choose_weighted_event(eligible)
	var applied := apply_event(event_data)
	applied["triggered"] = true
	return applied

func get_eligible_events(route_risk: float) -> Array:
	var eligible: Array = []
	for event_data in GameData.events_list:
		if float(event_data.get("min_risk", 0.0)) <= route_risk:
			eligible.append(event_data)
	return eligible

func choose_weighted_event(events: Array) -> Dictionary:
	var total_weight := 0.0
	for event_data in events:
		total_weight += float(event_data.get("weight", 1.0))

	var roll := randf() * total_weight
	var running := 0.0
	for event_data in events:
		running += float(event_data.get("weight", 1.0))
		if roll <= running:
			return event_data

	return events.back()

func apply_event(event_data: Dictionary) -> Dictionary:
	var effects: Dictionary = event_data.get("effects", {})
	GameState.apply_event_effects(effects)

	var outcome_parts: Array[String] = []
	var durability_loss := int(effects.get("durability_loss", 0))
	var supply_loss := int(effects.get("supply_loss", 0))
	var money_loss := int(effects.get("money_loss", 0))
	var cargo_loss_percent := float(effects.get("cargo_loss_percent", 0.0))

	if durability_loss != 0:
		outcome_parts.append("Durability %s%d" % ["-" if durability_loss > 0 else "+", abs(durability_loss)])
	if supply_loss != 0:
		outcome_parts.append("Supplies %s%d" % ["-" if supply_loss > 0 else "+", abs(supply_loss)])
	if money_loss != 0:
		outcome_parts.append("Money -%d" % money_loss)
	if cargo_loss_percent > 0.0:
		outcome_parts.append("Cargo loss %d%%" % int(round(cargo_loss_percent * 100.0)))

	return {
		"event_id": event_data.get("id", ""),
		"name": event_data.get("name", "Unknown Event"),
		"text": event_data.get("text", ""),
		"outcome_text": ", ".join(outcome_parts),
		"effects": effects,
	}
