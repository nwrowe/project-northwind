extends Control

var travel_system := TravelSystem.new()
var selected_route_id: String = ""

@onready var current_port_label = $VBoxContainer/HeaderPanel/VBoxContainer/CurrentPortLabel
@onready var ship_status_label = $VBoxContainer/HeaderPanel/VBoxContainer/ShipStatusLabel
@onready var routes_list = $VBoxContainer/RoutesScroll/VBoxContainer/RoutesList

func _ready() -> void:
	$VBoxContainer/FooterPanel/HBoxContainer/TravelButton.pressed.connect(_on_travel_pressed)
	$VBoxContainer/FooterPanel/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port := GameData.get_port(GameState.current_port_id)
	current_port_label.text = "Current Port: %s" % port.get("name", GameState.current_port_id)
	ship_status_label.text = "Supplies: %d   Durability: %d" % [GameState.supplies, GameState.ship_durability]

	for child in routes_list.get_children():
		child.queue_free()

	var routes := travel_system.get_routes_from_current_port()
	selected_route_id = ""
	for route in routes:
		var row_button := Button.new()
		var destination := GameData.get_port(route.get("to", ""))
		var supply_cost := travel_system.get_supply_cost(route)
		row_button.text = "%s  Dist:%s  Risk:%.2f  Supply:%d" % [
			destination.get("name", route.get("to", "")),
			str(route.get("distance", 0)),
			float(route.get("risk", 0.0)),
			supply_cost
		]
		row_button.pressed.connect(func(): _select_route(route.get("id", "")))
		routes_list.add_child(row_button)

func _select_route(route_id: String) -> void:
	selected_route_id = route_id

func _on_travel_pressed() -> void:
	if selected_route_id.is_empty():
		return
	var result := travel_system.travel(selected_route_id)
	if not result.get("success", false):
		return
	if result.get("event_triggered", false):
		ScreenRouter.show_event_popup(result.get("event_payload", {}))
	else:
		ScreenRouter.show_port_screen()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
