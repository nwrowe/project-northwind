extends Control

var event_system: EventSystem = EventSystem.new()
var payload: Dictionary = {}

@onready var event_name_label = $CenterContainer/PanelContainer/VBoxContainer/EventNameLabel
@onready var event_text_label = $CenterContainer/PanelContainer/VBoxContainer/EventTextLabel
@onready var outcome_label = $CenterContainer/PanelContainer/VBoxContainer/OutcomeLabel
@onready var choice_container = $CenterContainer/PanelContainer/VBoxContainer/ChoiceContainer
@onready var continue_button = $CenterContainer/PanelContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	refresh_ui()

func set_payload(new_payload: Dictionary) -> void:
	payload = new_payload
	if is_node_ready():
		refresh_ui()

func refresh_ui() -> void:
	event_name_label.text = str(payload.get("name", "Event"))
	event_text_label.text = str(payload.get("text", ""))
	var details: Array[String] = []
	var outcome: String = str(payload.get("outcome_text", ""))
	if not outcome.is_empty():
		details.append(outcome)
	var arrival: String = str(payload.get("arrival_summary", ""))
	if not arrival.is_empty():
		details.append(arrival)
	outcome_label.text = "\n".join(details)
	_refresh_choice_buttons()
	continue_button.visible = not bool(payload.get("unresolved", false))

func _refresh_choice_buttons() -> void:
	for child in choice_container.get_children():
		child.queue_free()
	if not bool(payload.get("unresolved", false)):
		choice_container.visible = false
		return
	choice_container.visible = true
	var options: Array = payload.get("choice_options", [])
	for option in options:
		var button := Button.new()
		button.text = str(option.get("label", "Choose"))
		button.custom_minimum_size = Vector2(0, 52)
		var choice_id: String = str(option.get("id", ""))
		button.pressed.connect(func(): _on_choice_pressed(choice_id))
		choice_container.add_child(button)

func _on_choice_pressed(choice_id: String) -> void:
	payload = event_system.resolve_event_choice(payload, choice_id)
	refresh_ui()

func _on_continue_pressed() -> void:
	ScreenRouter.show_port_screen()
