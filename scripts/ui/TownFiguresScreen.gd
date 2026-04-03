extends Control

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var summary_label = $VBoxContainer/SummaryPanel/VBoxContainer/SummaryLabel
@onready var residents_list = $VBoxContainer/ResidentsPanel/VBoxContainer/ResidentsScroll/VBoxContainer/ResidentsList
@onready var notables_list = $VBoxContainer/NotablesPanel/VBoxContainer/NotablesScroll/VBoxContainer/NotablesList
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	var residents: Array = GameData.get_residents_for_port(GameState.current_port_id)
	var notables: Array = GameData.get_notable_npcs_for_port(GameState.current_port_id)
	header_label.text = "Town Figures - %s" % str(port.get("name", GameState.current_port_id))
	summary_label.text = "Residents: %d | Notable figures: %d\nBusiness residents are recurring local fixtures. Notable figures are named port personalities who can later anchor story lines." % [residents.size(), notables.size()]
	info_label.text = "This is a foundation screen. Schedules, movement, homes, and quests can layer onto these figures later."
	_refresh_group(residents_list, residents, false)
	_refresh_group(notables_list, notables, true)

func _refresh_group(list_node: VBoxContainer, entries: Array, include_story_fields: bool) -> void:
	for child in list_node.get_children():
		child.queue_free()
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No entries yet."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list_node.add_child(empty_label)
		return
	for entry in entries:
		list_node.add_child(_build_entry_card(entry, include_story_fields))

func _build_entry_card(entry: Dictionary, include_story_fields: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(box)

	var title := Label.new()
	title.text = "%s — %s" % [str(entry.get("display_name", "Unknown")), str(entry.get("title", ""))]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title)

	var desc := Label.new()
	desc.text = str(entry.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(desc)

	var meta := Label.new()
	var traits: Array = entry.get("traits", [])
	meta.text = "Role: %s | Location: %s | Traits: %s" % [str(entry.get("business_role", "")), str(entry.get("location_hint", "")), ", ".join(traits)]
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(meta)

	var style := Label.new()
	style.text = "Style: %s" % str(entry.get("style_note", ""))
	style.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	style.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(style)

	if include_story_fields:
		var home := Label.new()
		home.text = "Home: %s" % str(entry.get("home_name", "Unknown residence"))
		home.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(home)

		var hook := Label.new()
		hook.text = "Story hook: %s" % str(entry.get("story_hook", "No hook assigned yet."))
		hook.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(hook)

	return card

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
