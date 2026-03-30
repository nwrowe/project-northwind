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
	header_label.text = "Contracts - %s" % port.get("name", "Port")

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
			_add_contract_row(available_list, contract, true)

	var active_contracts := contract_system.get_active_contracts()
	if active_contracts.is_empty():
		var active_empty := Label.new()
		active_empty.text = "No active contracts yet."
		active_list.add_child(active_empty)
	else:
		for contract in active_contracts:
			_add_contract_row(active_list, contract, false)

func _add_contract_row(target_list: VBoxContainer, contract: Dictionary, allow_accept: bool) -> void:
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

	if allow_accept:
		var accept_button := Button.new()
		accept_button.text = "Accept"
		accept_button.pressed.connect(func(): _accept_contract(contract_id))
		row.add_child(accept_button)

	target_list.add_child(row)

func _accept_contract(contract_id: String) -> void:
	var result: Dictionary = contract_system.accept_contract(contract_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
