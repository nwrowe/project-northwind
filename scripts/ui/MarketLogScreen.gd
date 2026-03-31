extends Control

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var entry_list = $VBoxContainer/EntriesScroll/VBoxContainer/EntryList

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	header_label.text = "Market Log Book"
	for child in entry_list.get_children():
		child.queue_free()
	var entries: Array = GameState.market_trade_log.duplicate()
	entries.reverse()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "No trade entries yet."
		entry_list.add_child(empty)
		return
	for entry in entries:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "Day %d | %s | %s x%d @ %d | %s" % [int(entry.get("day", 0)), str(entry.get("type", "")).capitalize(), GameData.get_good(str(entry.get("good_id", ""))).get("name", str(entry.get("good_id", ""))), int(entry.get("quantity", 0)), int(entry.get("price", 0)), GameData.get_port(str(entry.get("port_id", ""))).get("name", str(entry.get("port_id", "")))]
		entry_list.add_child(label)

func _on_back_pressed() -> void:
	ScreenRouter.show_market_screen()
