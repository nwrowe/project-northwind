extends Control

signal save_requested(slot_id: String, display_name: String)
signal load_requested(slot_id: String)
signal cancelled

enum DialogMode {
	SAVE,
	LOAD,
}

var current_mode: int = DialogMode.SAVE
var slot_cache: Array = []

@onready var scrim: ColorRect = $Scrim
@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var help_label: Label = $CenterContainer/Panel/VBoxContainer/HelpLabel
@onready var slot_list: ItemList = $CenterContainer/Panel/VBoxContainer/BodyHBox/SlotList
@onready var details_label: Label = $CenterContainer/Panel/VBoxContainer/BodyHBox/RightColumn/DetailsLabel
@onready var name_row: HBoxContainer = $CenterContainer/Panel/VBoxContainer/BodyHBox/RightColumn/NameRow
@onready var name_edit: LineEdit = $CenterContainer/Panel/VBoxContainer/BodyHBox/RightColumn/NameRow/NameEdit
@onready var confirm_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonRow/ConfirmButton
@onready var cancel_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonRow/CancelButton

func _ready() -> void:
	visible = false
	slot_list.item_selected.connect(_on_slot_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	scrim.gui_input.connect(_on_scrim_gui_input)

func open_for_save() -> void:
	current_mode = DialogMode.SAVE
	_open_dialog()

func open_for_load() -> void:
	current_mode = DialogMode.LOAD
	_open_dialog()

func close_dialog() -> void:
	visible = false

func _open_dialog() -> void:
	_refresh_slots()
	_apply_mode()
	visible = true

	if slot_cache.is_empty():
		return

	var preferred_index := _find_preferred_index()
	slot_list.select(preferred_index)
	_on_slot_selected(preferred_index)
	name_edit.grab_focus()

func _refresh_slots() -> void:
	slot_cache = SaveManager.list_slots()
	slot_list.clear()

	for slot in slot_cache:
		var line := "%s" % str(slot.get("slot_label", "Slot"))
		if bool(slot.get("has_save", false)):
			line += " — %s | Day %d | %s | %d gold" % [
				str(slot.get("display_name", "")),
				int(slot.get("day_count", 1)),
				str(slot.get("port_name", "Unknown Port")),
				int(slot.get("money", 0)),
			]
		else:
			line += " — Empty"
		slot_list.add_item(line)

func _apply_mode() -> void:
	if current_mode == DialogMode.SAVE:
		title_label.text = "Save Game"
		help_label.text = "Choose a slot. You can optionally name this save."
		name_row.visible = true
		name_edit.editable = true
		confirm_button.text = "Save"
	else:
		title_label.text = "Load Game"
		help_label.text = "Choose an existing save slot to load."
		name_row.visible = false
		name_edit.editable = false
		confirm_button.text = "Load"

func _find_preferred_index() -> int:
	if current_mode == DialogMode.SAVE:
		for i in range(slot_cache.size()):
			if not bool(slot_cache[i].get("has_save", false)):
				return i
		return 0

	var best_index := 0
	var best_time := -1
	for i in range(slot_cache.size()):
		if not bool(slot_cache[i].get("has_save", false)):
			continue
		var saved_at := int(slot_cache[i].get("saved_at_unix", 0))
		if saved_at > best_time:
			best_time = saved_at
			best_index = i
	return best_index

func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= slot_cache.size():
		return

	var slot: Dictionary = slot_cache[index]
	var has_save := bool(slot.get("has_save", false))

	if has_save:
		details_label.text = "Name: %s\nDay: %d\nPort: %s\nGold: %d" % [
			str(slot.get("display_name", "")),
			int(slot.get("day_count", 1)),
			str(slot.get("port_name", "Unknown Port")),
			int(slot.get("money", 0)),
		]
		name_edit.text = str(slot.get("display_name", ""))
	else:
		details_label.text = "This slot is empty."
		name_edit.text = ""

	if current_mode == DialogMode.LOAD:
		confirm_button.disabled = not has_save
	else:
		confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	var selected: PackedInt32Array = slot_list.get_selected_items()
	if selected.is_empty():
		return

	var index := selected[0]
	if index < 0 or index >= slot_cache.size():
		return

	var slot: Dictionary = slot_cache[index]
	var slot_id := str(slot.get("slot_id", ""))

	if current_mode == DialogMode.SAVE:
		save_requested.emit(slot_id, name_edit.text.strip_edges())
	else:
		if not bool(slot.get("has_save", false)):
			return
		load_requested.emit(slot_id)

func _on_cancel_pressed() -> void:
	visible = false
	cancelled.emit()

func _on_scrim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not panel.get_global_rect().has_point(get_global_mouse_position()):
			_on_cancel_pressed()
