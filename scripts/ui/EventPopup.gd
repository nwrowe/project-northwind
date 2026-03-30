extends Control

@onready var event_name_label = $CenterContainer/PanelContainer/VBoxContainer/EventNameLabel
@onready var event_text_label = $CenterContainer/PanelContainer/VBoxContainer/EventTextLabel
@onready var outcome_label = $CenterContainer/PanelContainer/VBoxContainer/OutcomeLabel

var payload: Dictionary = {}

func _ready() -> void:
	$CenterContainer/PanelContainer/VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	refresh_ui()

func set_payload(new_payload: Dictionary) -> void:
	payload = new_payload
	if is_node_ready():
		refresh_ui()

func refresh_ui() -> void:
	event_name_label.text = payload.get("name", "Event")
	event_text_label.text = payload.get("text", "")
	var details: Array[String] = []
	var outcome := str(payload.get("outcome_text", ""))
	if not outcome.is_empty():
		details.append(outcome)
	var arrival := str(payload.get("arrival_summary", ""))
	if not arrival.is_empty():
		details.append(arrival)
	outcome_label.text = "\n".join(details)

func _on_continue_pressed() -> void:
	ScreenRouter.show_port_screen()
