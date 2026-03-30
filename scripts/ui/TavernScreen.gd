extends Control

var tavern_system := TavernSystem.new()
var current_rumor_id: String = ""

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var intro_label = $VBoxContainer/IntroPanel/VBoxContainer/IntroLabel
@onready var keeper_label = $VBoxContainer/IntroPanel/VBoxContainer/KeeperLabel
@onready var officer_summary_label = $VBoxContainer/CrewPanel/VBoxContainer/OfficerSummaryLabel
@onready var crew_summary_label = $VBoxContainer/CrewPanel/VBoxContainer/CrewSummaryLabel
@onready var speaker_label = $VBoxContainer/RumorPanel/VBoxContainer/SpeakerLabel
@onready var rumor_title_label = $VBoxContainer/RumorPanel/VBoxContainer/RumorTitleLabel
@onready var rumor_text_label = $VBoxContainer/RumorPanel/VBoxContainer/RumorTextLabel
@onready var recruit_list = $VBoxContainer/RecruitScroll/VBoxContainer/RecruitList
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/NewRumorButton.pressed.connect(_on_new_rumor_pressed)
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/NewFacesButton.pressed.connect(_on_new_faces_pressed)
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()
	_show_new_rumor()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	header_label.text = "Tavern - %s" % port.get("name", "Port")
	intro_label.text = tavern_system.get_tavern_intro()
	keeper_label.text = "Host: %s" % tavern_system.get_tavernkeeper_name()
	officer_summary_label.text = "Officers: %s" % " | ".join(tavern_system.get_officer_summary_lines())
	crew_summary_label.text = "Crew: %d / %d | Money: %d" % [GameState.crew_count, GameState.get_effective_crew_capacity(), GameState.money]
	_refresh_recruits()

func _refresh_recruits() -> void:
	for child in recruit_list.get_children():
		child.queue_free()

	var candidates: Array = tavern_system.get_candidates_for_current_port()
	for candidate in candidates:
		_add_candidate_row(candidate)

func _add_candidate_row(candidate: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var outer := HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(outer)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(info_box)

	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.text = _candidate_title(candidate)
	info_box.add_child(title)

	var detail := Label.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.text = _candidate_detail(candidate)
	info_box.add_child(detail)

	var hire_button := Button.new()
	hire_button.text = "Hire"
	hire_button.custom_minimum_size = Vector2(120, 52)
	var candidate_id: String = str(candidate.get("id", ""))
	hire_button.pressed.connect(func(): _hire_candidate(candidate_id))
	outer.add_child(hire_button)

	recruit_list.add_child(card)

func _candidate_title(candidate: Dictionary) -> String:
	var role: String = str(candidate.get("role", ""))
	if role == "crew":
		return "%s | Crew bundle x%d | Cost %d" % [candidate.get("name", "Crew"), int(candidate.get("crew_amount", 0)), int(candidate.get("signing_cost", 0))]
	return "%s | %s | Cost %d | Trait: %s" % [candidate.get("name", "Officer"), role.capitalize(), int(candidate.get("signing_cost", 0)), candidate.get("trait", "plain")]

func _candidate_detail(candidate: Dictionary) -> String:
	var stats: Array[String] = [
		"Sailing %d" % int(candidate.get("sailing", 0)),
		"Repair %d" % int(candidate.get("repair", 0)),
		"Fighting %d" % int(candidate.get("fighting", 0)),
	]
	if candidate.get("type", "") == "officer":
		stats.append("Navigation %d" % int(candidate.get("navigation", 0)))
		stats.append("Leadership %d" % int(candidate.get("leadership", 0)))
	return ", ".join(stats)

func _show_new_rumor() -> void:
	var rumor: Dictionary = tavern_system.get_random_rumor(current_rumor_id)
	current_rumor_id = str(rumor.get("id", ""))
	speaker_label.text = "Heard from: %s" % rumor.get("speaker", tavern_system.get_tavernkeeper_name())
	rumor_title_label.text = str(rumor.get("title", "Rumor"))
	rumor_text_label.text = str(rumor.get("text", ""))
	info_label.text = "A fresh round loosens another useful story."

func _hire_candidate(candidate_id: String) -> void:
	var result: Dictionary = tavern_system.hire_candidate(candidate_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_new_rumor_pressed() -> void:
	_show_new_rumor()

func _on_new_faces_pressed() -> void:
	var result: Dictionary = tavern_system.reroll_candidates_for_current_port()
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
