extends Control

var shipyard_system := ShipyardSystem.new()

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var current_ship_label = $VBoxContainer/CurrentShipPanel/VBoxContainer/CurrentShipLabel
@onready var cargo_status_label = $VBoxContainer/CurrentShipPanel/VBoxContainer/CargoStatusLabel
@onready var ship_list = $VBoxContainer/ShipScroll/VBoxContainer/ShipList
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var current_ship: Dictionary = GameState.get_ship_def()
	header_label.text = "Shipyard"
	current_ship_label.text = "Current Ship: %s" % shipyard_system.build_ship_summary(current_ship)
	cargo_status_label.text = "Money: %d  |  Cargo used: %d / %d" % [
		GameState.money,
		GameState.get_current_cargo_used(),
		GameState.get_effective_cargo_capacity(),
	]

	for child in ship_list.get_children():
		child.queue_free()

	var candidates: Array = shipyard_system.get_purchase_candidates()
	if candidates.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No additional ships available."
		ship_list.add_child(empty_label)
		return

	for ship in candidates:
		_add_ship_row(ship)

func _add_ship_row(ship: Dictionary) -> void:
	var row := VBoxContainer.new()
	var ship_id: String = str(ship.get("id", ""))

	var label := Label.new()
	label.text = shipyard_system.build_ship_summary(ship)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	var compare_label := Label.new()
	compare_label.text = _build_compare_text(ship)
	compare_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(compare_label)

	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(0, 52)
	var can_buy: Dictionary = shipyard_system.can_buy_ship(ship_id)
	buy_button.disabled = not bool(can_buy.get("success", false))
	if buy_button.disabled:
		buy_button.tooltip_text = str(can_buy.get("message", "Cannot buy."))
	buy_button.pressed.connect(func(): _buy_ship(ship_id))
	row.add_child(buy_button)

	ship_list.add_child(row)

func _build_compare_text(ship: Dictionary) -> String:
	var current_ship: Dictionary = GameState.get_ship_def()
	return "Cargo %+d | Durability %+d | Speed %+0.2f | Supply Eff %+0.2f" % [
		int(ship.get("cargo_capacity", 0)) - int(current_ship.get("cargo_capacity", 0)),
		int(ship.get("max_durability", 0)) - int(current_ship.get("max_durability", 0)),
		float(ship.get("speed", 1.0)) - float(current_ship.get("speed", 1.0)),
		float(ship.get("supply_efficiency", 1.0)) - float(current_ship.get("supply_efficiency", 1.0)),
	]

func _buy_ship(ship_id: String) -> void:
	var result: Dictionary = shipyard_system.buy_ship(ship_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
