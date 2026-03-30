extends Control

@onready var port_name_label = $VBoxContainer/HeaderPanel/VBoxContainer/PortNameLabel
@onready var day_money_label = $VBoxContainer/HeaderPanel/VBoxContainer/DayMoneyLabel
@onready var ship_label = $VBoxContainer/StatusPanel/VBoxContainer/ShipLabel
@onready var durability_label = $VBoxContainer/StatusPanel/VBoxContainer/DurabilityLabel
@onready var supplies_label = $VBoxContainer/StatusPanel/VBoxContainer/SuppliesLabel
@onready var cargo_label = $VBoxContainer/StatusPanel/VBoxContainer/CargoLabel
@onready var cargo_summary_label = $VBoxContainer/SummaryPanel/VBoxContainer/CargoSummaryLabel
@onready var contract_summary_label = $VBoxContainer/SummaryPanel/VBoxContainer/ContractSummaryLabel
@onready var action_status_label = $VBoxContainer/SummaryPanel/VBoxContainer/ActionStatusLabel

func _ready() -> void:
	$VBoxContainer/ActionsPanel/VBoxContainer/MarketButton.pressed.connect(_on_market_pressed)
	$VBoxContainer/ActionsPanel/VBoxContainer/TravelButton.pressed.connect(_on_travel_pressed)
	$VBoxContainer/ActionsPanel/VBoxContainer/ContractsButton.pressed.connect(_on_contracts_pressed)
	$VBoxContainer/ActionsPanel/VBoxContainer/RepairButton.pressed.connect(_on_repair_pressed)
	$VBoxContainer/ActionsPanel/VBoxContainer/ResupplyButton.pressed.connect(_on_resupply_pressed)
	$VBoxContainer/ActionsPanel/VBoxContainer/UpgradeButton.pressed.connect(_on_upgrade_pressed)
	$VBoxContainer/ActionsPanel/VBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
	$VBoxContainer/ActionsPanel/VBoxContainer/LoadButton.pressed.connect(_on_load_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port := GameData.get_port(GameState.current_port_id)
	var ship := GameState.get_ship_def()
	port_name_label.text = port.get("name", "Unknown Port")
	day_money_label.text = "Day %d   Money: %d" % [GameState.day_count, GameState.money]
	ship_label.text = "Ship: %s" % ship.get("name", "Unknown Ship")
	durability_label.text = "Durability: %d / %d" % [GameState.ship_durability, GameState.get_effective_max_durability()]
	supplies_label.text = "Supplies: %d" % GameState.supplies
	cargo_label.text = "Cargo: %d / %d" % [GameState.get_current_cargo_used(), GameState.get_effective_cargo_capacity()]
	cargo_summary_label.text = "Cargo: %s" % _build_cargo_summary()
	contract_summary_label.text = "Contracts: %d available | %d active" % [GameData.get_contracts_for_port(GameState.current_port_id).size(), GameState.active_contracts.size()]

func _build_cargo_summary() -> String:
	if GameState.cargo.is_empty():
		return "Empty"
	var parts: Array[String] = []
	for good_id in GameState.cargo.keys():
		parts.append("%s x%d" % [GameData.get_good(good_id).get("name", good_id), int(GameState.cargo[good_id])])
	return ", ".join(parts)

func _set_status(message: String) -> void:
	action_status_label.text = message

func _on_market_pressed() -> void:
	ScreenRouter.show_market_screen()

func _on_travel_pressed() -> void:
	ScreenRouter.show_travel_screen()

func _on_contracts_pressed() -> void:
	ScreenRouter.show_contract_screen()

func _on_repair_pressed() -> void:
	var port := GameData.get_port(GameState.current_port_id)
	var missing := GameState.get_effective_max_durability() - GameState.ship_durability
	if missing <= 0:
		_set_status("Ship is already fully repaired.")
		return
	var modifier := float(port.get("repair_cost_modifier", 1.0))
	var cost := int(ceil(missing * 1.5 * modifier))
	if GameState.money >= cost:
		GameState.money -= cost
		GameState.ship_durability = GameState.get_effective_max_durability()
		_set_status("Ship repaired for %d." % cost)
	else:
		_set_status("Not enough money to repair.")
	refresh_ui()

func _on_resupply_pressed() -> void:
	var port := GameData.get_port(GameState.current_port_id)
	var max_supplies := 12
	var missing := max_supplies - GameState.supplies
	if missing <= 0:
		_set_status("Supplies are already full.")
		return
	var unit_cost := int(ceil(4.0 * float(port.get("supply_cost_modifier", 1.0))))
	var affordable := int(min(missing, GameState.money / max(1, unit_cost)))
	if affordable > 0:
		GameState.money -= affordable * unit_cost
		GameState.supplies += affordable
		_set_status("Bought %d supplies for %d." % [affordable, affordable * unit_cost])
	else:
		_set_status("Not enough money to resupply.")
	refresh_ui()

func _on_upgrade_pressed() -> void:
	ScreenRouter.show_upgrade_panel()

func _on_save_pressed() -> void:
	var result: Dictionary = SaveManager.save_game()
	_set_status(str(result.get("message", "Save complete.")))

func _on_load_pressed() -> void:
	var result: Dictionary = SaveManager.load_game()
	_set_status(str(result.get("message", "Load complete.")))
	refresh_ui()
