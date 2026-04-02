extends Control

var contract_system := ContractSystem.new()
var climate_system := ClimateSystem.new()

const SAVE_SLOT_DIALOG_SCENE := preload("res://scenes/ui/SaveSlotDialog.tscn")
const HOME_PORT_ID := "aurelia"
const BUSINESS_OPEN_HOUR := 6
const BUSINESS_CLOSE_HOUR := 22

const PORT_FLAVOR = {
	"aurelia": {"overview": "Aurelia is a calm starter harbor where traders swap staples and gossip under sun-faded awnings.", "npc": "Maris the Dock Clerk keeps ledgers on every captain and always knows which routes are safest this week."},
	"varenna": {"overview": "Varenna is a cloth-heavy commercial stop with tight lanes, fast deals, and merchants who watch every coin.", "npc": "Ida the Factor brokers textile contracts and quietly tips regular captains about shortages inland."},
	"cyr_port": {"overview": "Cyr Port feels hotter, louder, and richer, with spice traffic and higher-risk ships crowding the quay.", "npc": "Captain Sorell retired here and now trades route rumors for stories and a respectable fee."},
	"marsa_quay": {"overview": "Marsa Quay is practical and busy, full of grain, oil, and workers who value reliability over flash.", "npc": "Quartermaster Toma runs the chandlery and remembers every captain who paid on time."},
	"thalos": {"overview": "Thalos is wealthier and more demanding, where luxury cargo sells well and mistakes cost more.", "npc": "Archivist Nera in the harbor office favors captains who finish contracts before the ink dries."}
}

var save_slot_dialog
var balance_debug_visible: bool = false
var dockside_work_button: Button

@onready var port_name_label = $VBoxContainer/HeaderPanel/VBoxContainer/PortNameLabel
@onready var day_money_label = $VBoxContainer/HeaderPanel/VBoxContainer/DayMoneyLabel
@onready var ship_label = $VBoxContainer/StatusPanel/VBoxContainer/ShipLabel
@onready var durability_label = $VBoxContainer/StatusPanel/VBoxContainer/DurabilityLabel
@onready var supplies_label = $VBoxContainer/StatusPanel/VBoxContainer/SuppliesLabel
@onready var cargo_label = $VBoxContainer/StatusPanel/VBoxContainer/CargoLabel
@onready var local_flavor_label = $VBoxContainer/TownPanel/VBoxContainer/LocalFlavorLabel
@onready var npc_label = $VBoxContainer/TownPanel/VBoxContainer/NpcLabel
@onready var climate_label = $VBoxContainer/TownPanel/VBoxContainer/ClimateLabel
@onready var gathering_label = $VBoxContainer/TownPanel/VBoxContainer/GatheringLabel
@onready var refining_label = $VBoxContainer/TownPanel/VBoxContainer/RefiningLabel
@onready var cargo_summary_label = $VBoxContainer/SummaryPanel/VBoxContainer/CargoSummaryLabel
@onready var contract_summary_label = $VBoxContainer/SummaryPanel/VBoxContainer/ContractSummaryLabel
@onready var action_status_label = $VBoxContainer/SummaryPanel/VBoxContainer/ActionStatusLabel
@onready var balance_debug_panel = $VBoxContainer/BalanceDebugPanel
@onready var balance_debug_label = $VBoxContainer/BalanceDebugPanel/VBoxContainer/ScrollContainer/BalanceDebugLabel
@onready var balance_debug_toggle_button = $VBoxContainer/FooterPanel/HBoxContainer/BalanceDebugButton
@onready var market_button = $VBoxContainer/ServicePanel/GridContainer/MarketButton
@onready var contracts_button = $VBoxContainer/ServicePanel/GridContainer/ContractsButton
@onready var tavern_button = $VBoxContainer/ServicePanel/GridContainer/TavernButton
@onready var office_button = $VBoxContainer/ServicePanel/GridContainer/OfficeButton
@onready var shipyard_button = $VBoxContainer/ServicePanel/GridContainer/ShipyardButton
@onready var repair_button = $VBoxContainer/ServicePanel/GridContainer/RepairButton
@onready var resupply_button = $VBoxContainer/ServicePanel/GridContainer/ResupplyButton
@onready var upgrade_button = $VBoxContainer/ServicePanel/GridContainer/UpgradeButton
@onready var travel_button = $VBoxContainer/ServicePanel/GridContainer/TravelButton
@onready var service_grid = $VBoxContainer/ServicePanel/GridContainer
@onready var new_game_confirm_dialog = $NewGameConfirmDialog

func _ready() -> void:
	market_button.pressed.connect(_on_market_pressed)
	contracts_button.pressed.connect(_on_contracts_pressed)
	tavern_button.pressed.connect(_on_tavern_pressed)
	office_button.pressed.connect(_on_office_pressed)
	shipyard_button.pressed.connect(_on_shipyard_pressed)
	repair_button.pressed.connect(_on_repair_pressed)
	resupply_button.pressed.connect(_on_resupply_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	travel_button.pressed.connect(_on_travel_pressed)
	$VBoxContainer/FooterPanel/HBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
	$VBoxContainer/FooterPanel/HBoxContainer/LoadButton.pressed.connect(_on_load_pressed)
	$VBoxContainer/FooterPanel/HBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/FooterPanel/HBoxContainer/BalanceDebugButton.pressed.connect(_on_balance_debug_pressed)
	new_game_confirm_dialog.confirmed.connect(_on_new_game_confirmed)
	_ensure_dockside_work_button()

	save_slot_dialog = SAVE_SLOT_DIALOG_SCENE.instantiate()
	add_child(save_slot_dialog)
	save_slot_dialog.save_requested.connect(_on_save_slot_requested)
	save_slot_dialog.load_requested.connect(_on_load_slot_requested)
	save_slot_dialog.delete_requested.connect(_on_delete_slot_requested)
	_sync_balance_debug_visibility()
	refresh_ui()

	if not GameState.pending_status_message.is_empty():
		action_status_label.text = GameState.pending_status_message
		GameState.pending_status_message = ""

func _process(_delta: float) -> void:
	_refresh_header_summary()
	if balance_debug_visible:
		balance_debug_label.text = GameState.get_balance_debug_report()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	var ship: Dictionary = GameData.get_ship(GameState.ship_id)
	var flavor: Dictionary = PORT_FLAVOR.get(GameState.current_port_id, {"overview": "This harbor is busy with local traders, dockhands, and captains watching the tides.", "npc": "Someone near the docks always seems to know where the next opportunity is hiding."})
	var is_home_port: bool = GameState.current_port_id == HOME_PORT_ID
	var after_hours: bool = _is_after_hours()
	port_name_label.text = "%s Port Hub" % port.get("name", "Unknown Port")
	ship_label.text = "Ship: %s | Crew %d/%d | Officers %d slots" % [ship.get("name", "Unknown Ship"), GameState.crew_count, GameState.get_effective_crew_capacity(), GameState.get_effective_officer_slots()]
	durability_label.text = "Durability: %d / %d | Armor %d | Firepower %d" % [GameState.ship_durability, GameState.get_effective_max_durability(), GameState.get_effective_hull_armor(), GameState.get_effective_firepower()]
	supplies_label.text = "Supplies: %d | Speed %.2f | Evasion %d | Wages due %d" % [GameState.supplies, GameState.get_effective_speed(), GameState.get_effective_evasion(), GameState.get_crew_wages_due() + GameState.get_officer_wages_due()]
	cargo_label.text = "Cargo: %d / %d | Intimidation %d | Boarding %d | Upkeep %d" % [GameState.get_current_cargo_used(), GameState.get_effective_cargo_capacity(), GameState.get_effective_intimidation(), GameState.get_effective_boarding_strength(), GameState.get_ship_upkeep_due()]
	local_flavor_label.text = str(flavor.get("overview", ""))
	npc_label.text = str(flavor.get("npc", ""))
	climate_label.text = "Climate: %s" % climate_system.get_climate_name_for_current_port()
	gathering_label.text = "Wild resources: %s" % climate_system.get_gathering_summary_for_current_port()
	refining_label.text = "Refining specialties: %s" % climate_system.get_refining_summary_for_current_port()
	cargo_summary_label.text = "Cargo: %s" % ("Empty" if GameState.cargo.is_empty() else ", ".join(_cargo_parts()))
	contract_summary_label.text = _build_contract_summary()
	balance_debug_label.text = GameState.get_balance_debug_report()

	_apply_button_state(market_button, after_hours, "The market is closed until 06:00.")
	_apply_button_state(shipyard_button, after_hours, "The shipyard is closed until 06:00.")
	_apply_button_state(repair_button, after_hours, "The repair dock is closed until 06:00.")
	_apply_button_state(resupply_button, after_hours, "The chandlery is closed until 06:00.")
	_apply_button_state(dockside_work_button, after_hours, "Dockside work is only posted during daylight business hours.")

	upgrade_button.disabled = is_home_port or after_hours or not GameState.current_ship_can_install_upgrades()
	if is_home_port:
		upgrade_button.tooltip_text = "Aurelia is too small to support an outfitter."
	elif after_hours:
		upgrade_button.tooltip_text = "The outfitter is closed until 06:00."
	elif not GameState.current_ship_can_install_upgrades():
		upgrade_button.tooltip_text = "The rowboat cannot take ship upgrades."
	else:
		upgrade_button.tooltip_text = ""

	contracts_button.disabled = is_home_port or after_hours
	if is_home_port:
		contracts_button.tooltip_text = "Aurelia is too small to host a harbormaster."
	elif after_hours:
		contracts_button.tooltip_text = "The harbormaster closes for the night at 22:00."
	else:
		contracts_button.tooltip_text = ""

	office_button.disabled = is_home_port or after_hours
	if is_home_port:
		office_button.tooltip_text = "Aurelia has no harbor office."
	elif after_hours:
		office_button.tooltip_text = "The harbor office is closed until 06:00."
	else:
		office_button.tooltip_text = ""

	tavern_button.disabled = false
	tavern_button.tooltip_text = ""
	travel_button.disabled = false
	travel_button.tooltip_text = ""
	dockside_work_button.visible = is_home_port
	_refresh_header_summary()

func _apply_button_state(button: Button, disabled: bool, tooltip: String) -> void:
	button.disabled = disabled
	button.tooltip_text = tooltip if disabled else ""

func _ensure_dockside_work_button() -> void:
	dockside_work_button = Button.new()
	dockside_work_button.name = "DocksideWorkButton"
	dockside_work_button.text = "Dockside Work"
	dockside_work_button.custom_minimum_size = Vector2(0, 58)
	dockside_work_button.pressed.connect(_on_dockside_work_pressed)
	service_grid.add_child(dockside_work_button)

func _is_after_hours() -> bool:
	var seconds_of_day: int = GameState.get_time_of_day_seconds()
	var hour: int = int(seconds_of_day / 3600)
	return hour < BUSINESS_OPEN_HOUR or hour >= BUSINESS_CLOSE_HOUR

func _refresh_header_summary() -> void:
	day_money_label.text = "%s | Money %d | Trust %d | Infamy %d | Morale %d" % [GameState.get_day_and_time_string(), GameState.money, GameState.trust_rating, GameState.infamy_rating, GameState.morale]

func _cargo_parts() -> Array[String]:
	var parts: Array[String] = []
	for good_id in GameState.cargo.keys():
		parts.append("%s x%d" % [GameData.get_good(good_id).get("name", good_id), int(GameState.cargo[good_id])])
	return parts

func _build_contract_summary() -> String:
	var available: int = contract_system.get_available_contracts_for_current_port().size()
	var active: Array = contract_system.get_active_contracts()
	var completable: int = contract_system.get_completable_contracts_for_current_port().size()
	if GameState.current_port_id == HOME_PORT_ID:
		return "Aurelia is a small home port. Earn your first stake through dockside work."
	if active.is_empty():
		return "Harbormaster: %d contracts available | No active jobs | Total trip costs %d" % [available, GameState.get_total_upkeep_due()]
	var nearest_deadline: int = 9999
	for entry in active:
		nearest_deadline = min(nearest_deadline, int(entry.get("days_remaining", 9999)))
	var urgency := ""
	if nearest_deadline <= 1:
		urgency = " | Deadline urgent"
	return "Harbormaster: %d contracts available | %d active | %d ready now | Trip costs %d%s" % [available, active.size(), completable, GameState.get_total_upkeep_due(), urgency]

func _sync_balance_debug_visibility() -> void:
	balance_debug_panel.visible = balance_debug_visible
	balance_debug_toggle_button.text = "Hide Balance Debug" if balance_debug_visible else "Show Balance Debug"

func _on_balance_debug_pressed() -> void:
	balance_debug_visible = not balance_debug_visible
	_sync_balance_debug_visibility()
	if balance_debug_visible:
		balance_debug_label.text = GameState.get_balance_debug_report()

func _on_market_pressed() -> void:
	ScreenRouter.show_market_screen()
func _on_travel_pressed() -> void:
	ScreenRouter.show_travel_screen()
func _on_contracts_pressed() -> void:
	ScreenRouter.show_contract_screen()
func _on_tavern_pressed() -> void:
	ScreenRouter.show_tavern_screen()
func _on_office_pressed() -> void:
	ScreenRouter.show_office_screen()
func _on_shipyard_pressed() -> void:
	ScreenRouter.show_shipyard_screen()
func _on_repair_pressed() -> void:
	ScreenRouter.show_repair_screen()
func _on_resupply_pressed() -> void:
	ScreenRouter.show_chandlery_screen()
func _on_upgrade_pressed() -> void:
	ScreenRouter.show_upgrade_panel()
func _on_dockside_work_pressed() -> void:
	ScreenRouter.show_aurelia_bootstrap_screen()
func _on_save_pressed() -> void:
	save_slot_dialog.open_for_save()
func _on_load_pressed() -> void:
	save_slot_dialog.open_for_load()

func _on_save_slot_requested(slot_id: String, display_name: String) -> void:
	var result: Dictionary = SaveManager.save_game(slot_id, display_name)
	action_status_label.text = str(result.get("message", "Save complete."))
	save_slot_dialog.close_dialog()
	refresh_ui()

func _on_load_slot_requested(slot_id: String) -> void:
	var result: Dictionary = SaveManager.load_game(slot_id)
	action_status_label.text = str(result.get("message", "Load complete."))
	save_slot_dialog.close_dialog()
	if result.get("success", false):
		refresh_ui()

func _on_delete_slot_requested(slot_id: String) -> void:
	var result: Dictionary = SaveManager.delete_game(slot_id)
	action_status_label.text = str(result.get("message", "Delete complete."))
	if result.get("success", false):
		save_slot_dialog.refresh_slots()

func _on_new_game_pressed() -> void:
	new_game_confirm_dialog.popup_centered()

func _on_new_game_confirmed() -> void:
	GameState.new_game()
	ScreenRouter.show_opening_scene()
