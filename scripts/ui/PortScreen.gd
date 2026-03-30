extends Control

var contract_system := ContractSystem.new()

const PORT_FLAVOR := {
	"aurelia": {
		"overview": "Aurelia is a calm starter harbor where traders swap staples and gossip under sun-faded awnings.",
		"npc": "Maris the Dock Clerk keeps ledgers on every captain and always knows which routes are safest this week.",
	},
	"varenna": {
		"overview": "Varenna is a cloth-heavy commercial stop with tight lanes, fast deals, and merchants who watch every coin.",
		"npc": "Ida the Factor brokers textile contracts and quietly tips regular captains about shortages inland.",
	},
	"cyr_port": {
		"overview": "Cyr Port feels hotter, louder, and richer, with spice traffic and higher-risk ships crowding the quay.",
		"npc": "Captain Sorell retired here and now trades route rumors for stories and a respectable fee.",
	},
	"marsa_quay": {
		"overview": "Marsa Quay is practical and busy, full of grain, oil, and workers who value reliability over flash.",
		"npc": "Quartermaster Toma runs the chandlery and remembers every captain who paid on time.",
	},
	"thalos": {
		"overview": "Thalos is wealthier and more demanding, where luxury cargo sells well and mistakes cost more.",
		"npc": "Archivist Nera in the harbor office favors captains who finish contracts before the ink dries.",
	},
}

@onready var port_name_label = $VBoxContainer/HeaderPanel/VBoxContainer/PortNameLabel
@onready var day_money_label = $VBoxContainer/HeaderPanel/VBoxContainer/DayMoneyLabel
@onready var ship_label = $VBoxContainer/StatusPanel/VBoxContainer/ShipLabel
@onready var durability_label = $VBoxContainer/StatusPanel/VBoxContainer/DurabilityLabel
@onready var supplies_label = $VBoxContainer/StatusPanel/VBoxContainer/SuppliesLabel
@onready var cargo_label = $VBoxContainer/StatusPanel/VBoxContainer/CargoLabel
@onready var local_flavor_label = $VBoxContainer/TownPanel/VBoxContainer/LocalFlavorLabel
@onready var npc_label = $VBoxContainer/TownPanel/VBoxContainer/NpcLabel
@onready var cargo_summary_label = $VBoxContainer/SummaryPanel/VBoxContainer/CargoSummaryLabel
@onready var contract_summary_label = $VBoxContainer/SummaryPanel/VBoxContainer/ContractSummaryLabel
@onready var action_status_label = $VBoxContainer/SummaryPanel/VBoxContainer/ActionStatusLabel

func _ready() -> void:
	$VBoxContainer/ServicePanel/GridContainer/MarketButton.pressed.connect(_on_market_pressed)
	$VBoxContainer/ServicePanel/GridContainer/ContractsButton.pressed.connect(_on_contracts_pressed)
	$VBoxContainer/ServicePanel/GridContainer/TavernButton.pressed.connect(_on_tavern_pressed)
	$VBoxContainer/ServicePanel/GridContainer/ShipyardButton.pressed.connect(_on_shipyard_pressed)
	$VBoxContainer/ServicePanel/GridContainer/RepairButton.pressed.connect(_on_repair_pressed)
	$VBoxContainer/ServicePanel/GridContainer/ResupplyButton.pressed.connect(_on_resupply_pressed)
	$VBoxContainer/ServicePanel/GridContainer/UpgradeButton.pressed.connect(_on_upgrade_pressed)
	$VBoxContainer/ServicePanel/GridContainer/TravelButton.pressed.connect(_on_travel_pressed)
	$VBoxContainer/FooterPanel/HBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
	$VBoxContainer/FooterPanel/HBoxContainer/LoadButton.pressed.connect(_on_load_pressed)
	refresh_ui()
	if not GameState.pending_status_message.is_empty():
		_set_status(GameState.pending_status_message)
		GameState.pending_status_message = ""

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	var ship: Dictionary = GameState.get_ship_def()
	var flavor: Dictionary = PORT_FLAVOR.get(GameState.current_port_id, {
		"overview": "This harbor is busy with local traders, dockhands, and captains watching the tides.",
		"npc": "Someone near the docks always seems to know where the next opportunity is hiding.",
	})

	port_name_label.text = "%s Port Hub" % port.get("name", "Unknown Port")
	day_money_label.text = "Day %d   Money: %d   Completed: %d" % [GameState.day_count, GameState.money, GameState.completed_contract_ids.size()]
	ship_label.text = "Ship: %s" % ship.get("name", "Unknown Ship")
	durability_label.text = "Durability: %d / %d" % [GameState.ship_durability, GameState.get_effective_max_durability()]
	supplies_label.text = "Supplies: %d" % GameState.supplies
	cargo_label.text = "Cargo: %d / %d" % [GameState.get_current_cargo_used(), GameState.get_effective_cargo_capacity()]
	local_flavor_label.text = str(flavor.get("overview", ""))
	npc_label.text = str(flavor.get("npc", ""))
	cargo_summary_label.text = "Cargo: %s" % _build_cargo_summary()
	contract_summary_label.text = _build_contract_summary()

func _build_cargo_summary() -> String:
	if GameState.cargo.is_empty():
		return "Empty"
	var parts: Array[String] = []
	for good_id in GameState.cargo.keys():
		parts.append("%s x%d" % [GameData.get_good(good_id).get("name", good_id), int(GameState.cargo[good_id])])
	return ", ".join(parts)

func _build_contract_summary() -> String:
	var available: int = contract_system.get_available_contracts_for_current_port().size()
	var active: Array = contract_system.get_active_contracts()
	var completable: int = contract_system.get_completable_contracts_for_current_port().size()
	if active.is_empty():
		return "Harbormaster: %d contracts available | No active jobs" % available
	var nearest_deadline: int = 9999
	for entry in active:
		nearest_deadline = min(nearest_deadline, int(entry.get("days_remaining", 9999)))
	var urgency := ""
	if nearest_deadline <= 1:
		urgency = " | Deadline urgent"
	return "Harbormaster: %d contracts available | %d active | %d ready now%s" % [available, active.size(), completable, urgency]

func _set_status(message: String) -> void:
	action_status_label.text = message

func _on_market_pressed() -> void:
	ScreenRouter.show_market_screen()

func _on_travel_pressed() -> void:
	ScreenRouter.show_travel_screen()

func _on_contracts_pressed() -> void:
	ScreenRouter.show_contract_screen()

func _on_tavern_pressed() -> void:
	ScreenRouter.show_tavern_screen()

func _on_shipyard_pressed() -> void:
	ScreenRouter.show_shipyard_screen()

func _on_repair_pressed() -> void:
	ScreenRouter.show_repair_screen()

func _on_resupply_pressed() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	var max_supplies: int = 12
	var missing: int = max_supplies - GameState.supplies
	if missing <= 0:
		_set_status("Quartermaster: your stores are already full.")
		return
	var unit_cost: int = int(ceil(4.0 * float(port.get("supply_cost_modifier", 1.0))))
	var affordable: int = int(min(missing, GameState.money / max(1, unit_cost)))
	if affordable > 0:
		GameState.money -= affordable * unit_cost
		GameState.supplies += affordable
		_set_status("Quartermaster Toma sells you %d supplies for %d coins." % [affordable, affordable * unit_cost])
	else:
		_set_status("Quartermaster: not enough money to resupply.")
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
