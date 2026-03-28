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
	outcome_label.text = payload.get("outcome_text", "")

func _on_continue_pressed() -> void:
	ScreenRouter.show_port_screen()
