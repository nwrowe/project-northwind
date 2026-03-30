extends Control

var contract_system := ContractSystem.new()

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var available_list = $VBoxContainer/AvailableScroll/VBoxContainer/AvailableList
@onready var active_list = $VBoxContainer/ActiveScroll/VBoxContainer/ActiveList
@onready var info_label = $VBoxContainer/FooterPanel/HBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port := GameData.get_port(GameState.current_port_id)
	var completable := contract_system.get_completable_contracts_for_current_port().size()
	header_label.text = "Contracts - %s (Active:%d  Ready:%d)" % [
		port.get("name", "Port"),
		GameState.active_contracts.size(),
		completable,
	]

	for child in available_list.get_children():
		child.queue_free()
	for child in active_list.get_children():
		child.queue_free()

	var available_contracts := contract_system.get_available_contracts_for_current_port()
	if available_contracts.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No available contracts here."
		available_list.add_child(empty_label)
	else:
		for contract in available_contracts:
			_add_available_contract_row(available_list, contract)

	var active_contracts := contract_system.get_active_contracts()
	if active_contracts.is_empty():
		var active_empty := Label.new()
		active_empty.text = "No active contracts yet."
		active_list.add_child(active_empty)
	else:
		for active in active_contracts:
			_add_active_contract_row(active_list, active)

func _add_available_contract_row(target_list: VBoxContainer, contract: Dictionary) -> void:
	var row := VBoxContainer.new()
	var contract_id: String = str(contract.get("id", ""))
	var good_id: String = str(contract.get("good_id", ""))
	var target_port_id: String = str(contract.get("target_port", ""))
	var good := GameData.get_good(good_id)
	var target_port := GameData.get_port(target_port_id)

	var title := Label.new()
	title.text = "%s x%d -> %s  Reward:%d" % [
		good.get("name", good_id),
		int(contract.get("quantity", 0)),
		target_port.get("name", target_port_id),
		int(contract.get("reward", 0))
	]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(title)

	var sub := Label.new()
	sub.text = "Deadline: %d days   ID: %s" % [int(contract.get("deadline_days", 0)), contract_id]
	row.add_child(sub)

	var accept_button := Button.new()
	accept_button.text = "Accept"
	accept_button.custom_minimum_size = Vector2(0, 52)
	accept_button.pressed.connect(func(): _accept_contract(contract_id))
	row.add_child(accept_button)

	target_list.add_child(row)

func _add_active_contract_row(target_list: VBoxContainer, active: Dictionary) -> void:
	var row := VBoxContainer.new()
	var contract: Dictionary = active.get("contract", {})
	var contract_id: String = str(active.get("contract_id", ""))
	var good_id: String = str(contract.get("good_id", ""))
	var quantity := int(contract.get("quantity", 0))
	var reward := int(contract.get("reward", 0))
	var cargo_have := int(active.get("cargo_have", 0))
	var days_remaining := int(active.get("days_remaining", 0))

	var title := Label.new()
	title.text = "%s  Reward:%d" % [str(active.get("summary", contract_id)), reward]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(title)

	var status_parts: Array[String] = []
	status_parts.append("Cargo %d/%d" % [cargo_have, quantity])
	status_parts.append("Days left %d" % days_remaining)
	if bool(active.get("at_destination", false)):
		status_parts.append("At destination")
	var status := Label.new()
	status.text = " | ".join(status_parts)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(status)

	if bool(active.get("is_completable", false)):
		var complete_button := Button.new()
		complete_button.text = "Complete (+%d)" % reward
		complete_button.custom_minimum_size = Vector2(0, 52)
		complete_button.pressed.connect(func(): _complete_contract(contract_id))
		row.add_child(complete_button)
	elif bool(active.get("at_destination", false)) and cargo_have < quantity:
		var hint := Label.new()
		hint.text = "Need %d more %s to complete." % [quantity - cargo_have, GameData.get_good(good_id).get("name", good_id)]
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(hint)

	target_list.add_child(row)

func _accept_contract(contract_id: String) -> void:
	var result: Dictionary = contract_system.accept_contract(contract_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _complete_contract(contract_id: String) -> void:
	var result: Dictionary = contract_system.complete_contract(contract_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
