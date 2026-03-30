extends Control

var tavern_system := TavernSystem.new()
var current_rumor_id: String = ""

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var intro_label = $VBoxContainer/IntroPanel/VBoxContainer/IntroLabel
@onready var keeper_label = $VBoxContainer/IntroPanel/VBoxContainer/KeeperLabel
@onready var speaker_label = $VBoxContainer/RumorPanel/VBoxContainer/SpeakerLabel
@onready var rumor_title_label = $VBoxContainer/RumorPanel/VBoxContainer/RumorTitleLabel
@onready var rumor_text_label = $VBoxContainer/RumorPanel/VBoxContainer/RumorTextLabel
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/NewRumorButton.pressed.connect(_on_new_rumor_pressed)
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()
	_show_new_rumor()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	header_label.text = "Tavern - %s" % port.get("name", "Port")
	intro_label.text = tavern_system.get_tavern_intro()
	keeper_label.text = "Host: %s" % tavern_system.get_tavernkeeper_name()

func _show_new_rumor() -> void:
	var rumor: Dictionary = tavern_system.get_random_rumor(current_rumor_id)
	current_rumor_id = str(rumor.get("id", ""))
	speaker_label.text = "Heard from: %s" % rumor.get("speaker", tavern_system.get_tavernkeeper_name())
	rumor_title_label.text = str(rumor.get("title", "Rumor"))
	rumor_text_label.text = str(rumor.get("text", ""))
	info_label.text = "A fresh round loosens another useful story."

func _on_new_rumor_pressed() -> void:
	_show_new_rumor()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
