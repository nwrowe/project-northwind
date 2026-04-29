extends Node

## Focused facade for ship, cargo, upgrade, and port-discovery state.
##
## GameState remains the backing store during this first refactor so existing save
## files and gameplay code keep working while new callers get a narrower API.

func get_current_port_id() -> String:
	return GameState.current_port_id

func set_current_port_id(port_id: String) -> void:
	GameState.current_port_id = port_id

func get_ship_id() -> String:
	return GameState.ship_id

func get_ship_def() -> Dictionary:
	return GameState.get_ship_def()

func set_ship_id(ship_id: String) -> void:
	GameState.ship_id = ship_id

func get_durability() -> int:
	return GameState.ship_durability

func set_durability(value: int) -> void:
	GameState.ship_durability = clamp(value, 0, get_effective_max_durability())

func get_supplies() -> int:
	return GameState.supplies

func set_supplies(value: int) -> void:
	GameState.supplies = max(0, value)

func spend_supplies(amount: int) -> bool:
	if amount <= 0:
		return true
	if GameState.supplies < amount:
		return false
	GameState.supplies -= amount
	return true

func get_cargo() -> Dictionary:
	return GameState.cargo

func add_cargo(good_id: String, quantity: int) -> void:
	GameState.add_cargo(good_id, quantity)

func get_cargo_used() -> int:
	return GameState.get_current_cargo_used()

func get_effective_cargo_capacity() -> int:
	return GameState.get_effective_cargo_capacity()

func get_effective_max_durability() -> int:
	return GameState.get_effective_max_durability()

func get_effective_supply_efficiency() -> float:
	return GameState.get_effective_supply_efficiency()

func get_effective_speed() -> float:
	return GameState.get_effective_speed()

func get_effective_firepower() -> int:
	return GameState.get_effective_firepower()

func get_effective_hull_armor() -> int:
	return GameState.get_effective_hull_armor()

func get_effective_evasion() -> int:
	return GameState.get_effective_evasion()

func get_effective_intimidation() -> int:
	return GameState.get_effective_intimidation()

func get_effective_boarding_strength() -> int:
	return GameState.get_effective_boarding_strength()

func current_ship_supports_personnel() -> bool:
	return GameState.current_ship_supports_personnel()

func current_ship_can_install_upgrades() -> bool:
	return GameState.current_ship_can_install_upgrades()

func has_upgrade(upgrade_id: String) -> bool:
	return GameState.has_upgrade(upgrade_id)

func apply_upgrade(upgrade_id: String) -> void:
	GameState.apply_upgrade(upgrade_id)

func discover_port(port_id: String) -> void:
	GameState.discover_port(port_id)

func has_known_port(port_id: String) -> bool:
	return GameState.has_known_port(port_id)

func get_known_port_ids() -> Array[String]:
	return GameState.known_port_ids
