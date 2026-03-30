extends Control

var travel_system := TravelSystem.new()
var contract_system := ContractSystem.new()
var selected_route_id: String = ""

@onready var current_port_label = $VBoxContainer/HeaderPanel/VBoxContainer/CurrentPortLabel
@onready var ship_status_label = $VBoxContainer/HeaderPanel/VBoxContainer/ShipStatusLabel
@onready var selected_route_label = $VBoxContainer/FooterPanel/VBoxContainer/SelectedRouteLabel
@onready var status_label = $VBoxContainer/FooterPanel/VBoxContainer/StatusLabel
@onready var routes_list = $VBoxContainer/RoutesScroll/VBoxContainer/RoutesList

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/ButtonRow/TravelButton.pressed.connect(_on_travel_pressed)
	$VBoxContainer/FooterPanel/VBoxContainer/ButtonRow/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port := GameData.get_port(GameState.current_port_id)
	current_port_label.text = "Current Port: %s" % port.get("name", GameState.current_port_id)
	ship_status_label.text = "Supplies: %d   Durability: %d" % [GameState.supplies, GameState.ship_durability]

	for child in routes_list.get_children():
		child.queue_free()

	var active_contracts := contract_system.get_active_contracts()
	var routes := travel_system.get_routes_from_current_port()
	for route in routes:
		var route_id: String = str(route.get("id", ""))
		var row_button := Button.new()
		row_button.custom_minimum_size = Vector2(0, 56)
		var destination := GameData.get_port(route.get("to", ""))
		var supply_cost := travel_system.get_supply_cost(route)
		var is_selected := route_id == selected_route_id
		var prefix := "[Selected] " if is_selected else ""
		var risk_level := _risk_label(float(route.get("risk", 0.0)))
		var contract_hint := _contract_route_hint(str(route.get("to", "")), active_contracts)
		row_button.text = "%s%s  Dist:%s  %s  Supply:%d%s" % [
			prefix,
			destination.get("name", route.get("to", "")),
			str(route.get("distance", 0)),
			risk_level,
			supply_cost,
			contract_hint
		]
		row_button.pressed.connect(func(): _select_route(route_id))
		routes_list.add_child(row_button)

	_update_selected_route_label()

func _risk_label(risk: float) -> String:
	if risk < 0.25:
		return "Risk:Low"
	if risk < 0.5:
		return "Risk:Med"
	return "Risk:High"

func _contract_route_hint(destination_port_id: String, active_contracts: Array) -> String:
	for active in active_contracts:
		var contract: Dictionary = active.get("contract", {})
		if str(contract.get("target_port", "")) == destination_port_id:
			return "  [Contract]"
	return ""

func _select_route(route_id: String) -> void:
	selected_route_id = route_id
	status_label.text = ""
	refresh_ui()

func _update_selected_route_label() -> void:
	if selected_route_id.is_empty():
		selected_route_label.text = "Selected Route: none"
		return
	var route := GameData.get_route(selected_route_id)
	var destination := GameData.get_port(route.get("to", ""))
	selected_route_label.text = "Selected Route: %s (Distance %s, Risk %.2f, Supply %d)" % [
		destination.get("name", route.get("to", "")),
		str(route.get("distance", 0)),
		float(route.get("risk", 0.0)),
		travel_system.get_supply_cost(route)
	]

func _on_travel_pressed() -> void:
	if selected_route_id.is_empty():
		status_label.text = "Select a route before traveling."
		return
	var result: Dictionary = travel_system.travel(selected_route_id)
	if not result.get("success", false):
		status_label.text = str(result.get("message", "Travel failed."))
		return
	if result.get("event_triggered", false):
		var payload := result.get("event_payload", {}).duplicate(true)
		payload["arrival_summary"] = result.get("arrival_summary", "")
		ScreenRouter.show_event_popup(payload)
	else:
		ScreenRouter.show_port_screen()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
