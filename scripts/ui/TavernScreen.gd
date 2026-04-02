extends Control

var tavern_system := TavernSystem.new()
var current_rumor_id: String = ""
var pending_round_action: String = ""
const RUMOR_ROUND_COST := 4
const NEW_FACES_COST := 6
const CREW_ROUND_COST_BASE := 8
const SLEEP_BASE_COST := 2

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
@onready var button_row = $VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/NewRumorButton.pressed.connect(_on_new_rumor_pressed)
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/NewFacesButton.pressed.connect(_on_new_faces_pressed)
	$VBoxContainer/FooterPanel/VBoxContainer/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	var crew_round_button := Button.new()
	crew_round_button.name = "CrewRoundButton"
	crew_round_button.text = "Buy Crew Round"
	crew_round_button.pressed.connect(_on_crew_round_pressed)
	button_row.add_child(crew_round_button)
	var sleep_button := Button.new()
	sleep_button.name = "SleepButton"
	sleep_button.text = "Sleep"
	sleep_button.pressed.connect(_on_sleep_pressed)
	button_row.add_child(sleep_button)
	var confirm_button := Button.new()
	confirm_button.name = "ConfirmRoundButton"
	confirm_button.text = "Confirm"
	confirm_button.visible = false
	confirm_button.pressed.connect(_on_confirm_round_pressed)
	button_row.add_child(confirm_button)
	var cancel_button := Button.new()
	cancel_button.name = "CancelRoundButton"
	cancel_button.text = "Cancel"
	cancel_button.visible = false
	cancel_button.pressed.connect(_on_cancel_round_pressed)
	button_row.add_child(cancel_button)
	refresh_ui()
	_show_new_rumor()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	header_label.text = "Tavern - %s" % port.get("name", "Port")
	intro_label.text = tavern_system.get_tavern_intro()
	keeper_label.text = "Host: %s" % tavern_system.get_tavernkeeper_name()
	officer_summary_label.text = "Officers: %s" % " | ".join(tavern_system.get_officer_summary_lines())
	crew_summary_label.text = "Crew: %d / %d | Money: %d | Morale: %d | Time: %s" % [GameState.crew_count, GameState.get_effective_crew_capacity(), GameState.money, GameState.morale, GameState.get_day_and_time_string()]
	_refresh_recruits()
	_update_button_states()

func _refresh_recruits() -> void:
	for child in recruit_list.get_children():
		child.queue_free()
	if not GameState.current_ship_supports_personnel():
		var blocked_label := Label.new()
		blocked_label.text = "This rowboat cannot take on crew or officers. If you want hands on deck, you will need to buy a larger ship first."
		blocked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blocked_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recruit_list.add_child(blocked_label)
		return
	for candidate in tavern_system.get_candidates_for_current_port():
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
	var stats: Array[String] = ["Sailing %d" % int(candidate.get("sailing", 0)), "Repair %d" % int(candidate.get("repair", 0)), "Fighting %d" % int(candidate.get("fighting", 0))]
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

func _hire_candidate(candidate_id: String) -> void:
	var result: Dictionary = tavern_system.hire_candidate(candidate_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _update_button_states() -> void:
	var supports_personnel: bool = GameState.current_ship_supports_personnel()
	button_row.get_node("NewFacesButton").disabled = not supports_personnel
	button_row.get_node("CrewRoundButton").disabled = not supports_personnel or GameState.crew_count <= 0
	button_row.get_node("SleepButton").tooltip_text = "Sleep until 06:00 next morning for %d gold." % _get_sleep_cost()
	if not supports_personnel:
		button_row.get_node("NewFacesButton").tooltip_text = "The rowboat cannot take on new crew or officers."
		button_row.get_node("CrewRoundButton").tooltip_text = "No crew can be assigned to the rowboat."
	else:
		button_row.get_node("NewFacesButton").tooltip_text = ""
		button_row.get_node("CrewRoundButton").tooltip_text = ""

func _on_new_rumor_pressed() -> void:
	_request_round("rumor")

func _on_new_faces_pressed() -> void:
	_request_round("faces")

func _on_crew_round_pressed() -> void:
	_request_round("crew")

func _on_sleep_pressed() -> void:
	_request_round("sleep")

func _request_round(action: String) -> void:
	if action != "rumor" and action != "sleep" and not GameState.current_ship_supports_personnel():
		info_label.text = "The rowboat cannot support crew or officers."
		return
	var cost: int = _get_round_cost(action)
	if GameState.money < cost:
		info_label.text = "Not enough gold to pay for that round."
		return
	pending_round_action = action
	if action == "crew":
		info_label.text = "Spend %d gold to lift crew morale?" % cost
	elif action == "sleep":
		info_label.text = "Spend %d gold to sleep until 06:00 tomorrow?" % cost
	else:
		info_label.text = "Spend %d gold to buy a round?" % cost
	button_row.get_node("ConfirmRoundButton").visible = true
	button_row.get_node("CancelRoundButton").visible = true

func _get_sleep_cost() -> int:
	return SLEEP_BASE_COST + GameState.crew_count

func _get_round_cost(action: String) -> int:
	if action == "rumor":
		return RUMOR_ROUND_COST
	if action == "faces":
		return NEW_FACES_COST
	if action == "sleep":
		return _get_sleep_cost()
	return CREW_ROUND_COST_BASE + int(ceil(float(GameState.crew_count) / 2.0))

func _on_confirm_round_pressed() -> void:
	if pending_round_action.is_empty():
		return
	var cost: int = _get_round_cost(pending_round_action)
	if GameState.money < cost:
		info_label.text = "Not enough gold to pay for that round."
		pending_round_action = ""
		return
	GameState.money -= cost
	if pending_round_action == "rumor":
		_show_new_rumor()
		info_label.text = "You buy a round and the room loosens a fresh rumor."
	elif pending_round_action == "faces":
		var result: Dictionary = tavern_system.reroll_candidates_for_current_port()
		info_label.text = "%s (-%d gold)" % [str(result.get("message", "")), cost]
	elif pending_round_action == "sleep":
		GameState.sleep_until_next_morning()
		GameState.recover_morale_in_port(6)
		info_label.text = "You sleep through the night and wake at 06:00, a little steadier. (-%d gold)" % cost
	else:
		GameState.recover_morale_in_port(12 + int(floor(float(GameState.get_effective_command_rating()) / 2.0)))
		info_label.text = "The crew relaxes, morale rises, and the tavern rings with song. (-%d gold)" % cost
	refresh_ui()
	pending_round_action = ""
	button_row.get_node("ConfirmRoundButton").visible = false
	button_row.get_node("CancelRoundButton").visible = false

func _on_cancel_round_pressed() -> void:
	pending_round_action = ""
	info_label.text = ""
	button_row.get_node("ConfirmRoundButton").visible = false
	button_row.get_node("CancelRoundButton").visible = false

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
