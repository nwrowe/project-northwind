extends Control

var office_system := OfficeStorageSystem.new()

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var status_label = $VBoxContainer/StatusPanel/VBoxContainer/StatusLabel
@onready var membership_label = $VBoxContainer/StatusPanel/VBoxContainer/MembershipLabel
@onready var cargo_list = $VBoxContainer/CargoScroll/VBoxContainer/CargoList
@onready var storage_list = $VBoxContainer/StorageScroll/VBoxContainer/StorageList
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	header_label.text = "Harbor Office - %s" % port.get("name", "Port")
	status_label.text = "Money: %d | Ship cargo: %d / %d" % [GameState.money, GameState.get_current_cargo_used(), GameState.get_effective_cargo_capacity()]
	membership_label.text = "Membership: %s" % ("Active" if GameState.office_member else "Not joined (%d gold)" % OfficeStorageSystem.MEMBERSHIP_COST)
	for child in cargo_list.get_children():
		child.queue_free()
	for child in storage_list.get_children():
		child.queue_free()
	if not GameState.office_member:
		var join_button := Button.new()
		join_button.text = "Join Harbor Office"
		join_button.custom_minimum_size = Vector2(0, 52)
		join_button.pressed.connect(_on_join_pressed)
		cargo_list.add_child(join_button)
		return
	if GameState.cargo.is_empty():
		var empty_ship := Label.new()
		empty_ship.text = "No ship cargo to store."
		cargo_list.add_child(empty_ship)
	else:
		for good_id in GameState.cargo.keys():
			_add_cargo_row(str(good_id), int(GameState.cargo[good_id]))
	var storage: Dictionary = office_system.get_current_storage()
	if storage.is_empty():
		var empty_store := Label.new()
		empty_store.text = "No stored cargo at this port."
		storage_list.add_child(empty_store)
	else:
		for good_id in storage.keys():
			_add_storage_row(str(good_id), int(storage[good_id]))

func _make_card() -> Array:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var outer := HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(outer)
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(info_box)
	return [card, outer, info_box]

func _add_cargo_row(good_id: String, qty: int) -> void:
	var built := _make_card()
	var card: PanelContainer = built[0]
	var outer: HBoxContainer = built[1]
	var info_box: VBoxContainer = built[2]
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s x%d" % [GameData.get_good(good_id).get("name", good_id), qty]
	info_box.add_child(label)
	var store1 := Button.new()
	store1.text = "Store 1"
	store1.custom_minimum_size = Vector2(100, 52)
	store1.pressed.connect(func(): _store_amount(good_id, 1))
	outer.add_child(store1)
	var storeall := Button.new()
	storeall.text = "Store All"
	storeall.custom_minimum_size = Vector2(100, 52)
	storeall.pressed.connect(func(): _store_amount(good_id, qty))
	outer.add_child(storeall)
	cargo_list.add_child(card)

func _add_storage_row(good_id: String, qty: int) -> void:
	var built := _make_card()
	var card: PanelContainer = built[0]
	var outer: HBoxContainer = built[1]
	var info_box: VBoxContainer = built[2]
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s x%d" % [GameData.get_good(good_id).get("name", good_id), qty]
	info_box.add_child(label)
	var take1 := Button.new()
	take1.text = "Take 1"
	take1.custom_minimum_size = Vector2(100, 52)
	take1.pressed.connect(func(): _retrieve_amount(good_id, 1))
	outer.add_child(take1)
	var takeall := Button.new()
	takeall.text = "Take All"
	takeall.custom_minimum_size = Vector2(100, 52)
	takeall.pressed.connect(func(): _retrieve_amount(good_id, qty))
	outer.add_child(takeall)
	storage_list.add_child(card)

func _on_join_pressed() -> void:
	var result: Dictionary = office_system.join_office()
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _store_amount(good_id: String, qty: int) -> void:
	var result: Dictionary = office_system.store(good_id, qty)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _retrieve_amount(good_id: String, qty: int) -> void:
	var result: Dictionary = office_system.retrieve(good_id, qty)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
