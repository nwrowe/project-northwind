extends Control

var shipboard_system := ShipBoardSystem.new()

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var ship_summary_label = $VBoxContainer/StatusPanel/VBoxContainer/ShipSummaryLabel
@onready var supplies_label = $VBoxContainer/StatusPanel/VBoxContainer/SuppliesLabel
@onready var cargo_label = $VBoxContainer/StatusPanel/VBoxContainer/CargoLabel
@onready var known_world_label = $VBoxContainer/MapPanel/VBoxContainer/KnownWorldLabel
@onready var task_list = $VBoxContainer/TaskScroll/VBoxContainer/TaskList
@onready var station_list = $VBoxContainer/StationsPanel/VBoxContainer/StationList
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var ship: Dictionary = GameState.get_ship_def()
	header_label.text = "Your Ship - %s" % str(ship.get("name", GameState.ship_id))
	ship_summary_label.text = "%s | Time %s | Durability %d / %d | Crew %d/%d | Officers %d/%d" % [
		str(ship.get("name", GameState.ship_id)),
		GameState.get_day_and_time_string(),
		GameState.ship_durability,
		GameState.get_effective_max_durability(),
		GameState.crew_count,
		GameState.get_effective_crew_capacity(),
		GameState.get_active_officer_count(),
		GameState.get_effective_officer_slots(),
	]
	supplies_label.text = "Supply Hold: %d | Next-trip chart bonus: %d%%" % [GameState.supplies, int(round(GameState.next_trip_chart_discount * 100.0))]
	cargo_label.text = "Cargo Hold: %d / %d used | Morale %d | Firepower %d | Armor %d" % [
		GameState.get_current_cargo_used(),
		GameState.get_effective_cargo_capacity(),
		GameState.morale,
		GameState.get_effective_firepower(),
		GameState.get_effective_hull_armor(),
	]
	known_world_label.text = shipboard_system.get_known_world_summary()
	_refresh_tasks()
	_refresh_stations()

func _refresh_tasks() -> void:
	for child in task_list.get_children():
		child.queue_free()
	for card in shipboard_system.get_task_cards():
		_add_task_row(card)

func _add_task_row(card: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var outer := HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(outer)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(info_box)

	var title := Label.new()
	title.text = str(card.get("name", "Task"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_child(title)

	var detail := Label.new()
	detail.text = "%s\n%s" % [str(card.get("description", "")), str(card.get("note", ""))]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_child(detail)

	var button := Button.new()
	button.text = "Do Task"
	button.custom_minimum_size = Vector2(120, 52)
	button.disabled = not bool(card.get("enabled", false))
	if not bool(card.get("unlocked", true)):
		button.text = "Locked"
		button.tooltip_text = "This ship does not support that station yet."
	elif button.disabled:
		button.tooltip_text = "Unavailable right now."
	button.pressed.connect(_on_task_pressed.bind(str(card.get("id", ""))))
	outer.add_child(button)

	task_list.add_child(panel)

func _refresh_stations() -> void:
	for child in station_list.get_children():
		child.queue_free()
	for station in shipboard_system.get_station_descriptions():
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "%s: %s%s" % [
			str(station.get("name", "Station")),
			str(station.get("description", "")),
			"" if bool(station.get("unlocked", false)) else " (locked on this ship)",
		]
		station_list.add_child(label)

func _on_task_pressed(task_id: String) -> void:
	var result: Dictionary = shipboard_system.perform_task(task_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
