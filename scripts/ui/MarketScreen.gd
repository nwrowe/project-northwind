extends Control

var market_system := MarketSystem.new()

@onready var port_name_label = $VBoxContainer/HeaderPanel/VBoxContainer/PortNameLabel
@onready var money_cargo_label = $VBoxContainer/HeaderPanel/VBoxContainer/MoneyCargoLabel
@onready var goods_list = $VBoxContainer/GoodsScroll/VBoxContainer/GoodsList
@onready var info_label = $VBoxContainer/FooterPanel/HBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port := GameData.get_port(GameState.current_port_id)
	port_name_label.text = port.get("name", "Market")
	money_cargo_label.text = "Money: %d   Cargo: %d / %d" % [
		GameState.money,
		GameState.get_current_cargo_used(),
		GameState.get_effective_cargo_capacity()
	]

	for child in goods_list.get_children():
		child.queue_free()

	for good in GameData.goods_list:
		var good_id: String = str(good.get("id", ""))
		var row := VBoxContainer.new()
		var price := market_system.get_local_price(GameState.current_port_id, good_id)
		var owned := int(GameState.cargo.get(good_id, 0))
		var max_buy := market_system.get_max_buy_quantity(good_id)

		var name_label := Label.new()
		name_label.text = "%s  Price:%d  Owned:%d  Max buy:%d" % [
			good.get("name", good_id),
			price,
			owned,
			max_buy,
		]
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(name_label)

		var button_row := HBoxContainer.new()
		button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button_row)

		button_row.add_child(_create_action_button("Buy 1", func(): _buy_qty(good_id, 1)))
		button_row.add_child(_create_action_button("Buy 5", func(): _buy_qty(good_id, 5)))
		button_row.add_child(_create_action_button("Buy Max", func(): _buy_max(good_id)))
		button_row.add_child(_create_action_button("Sell 1", func(): _sell_qty(good_id, 1)))
		button_row.add_child(_create_action_button("Sell 5", func(): _sell_qty(good_id, 5)))
		button_row.add_child(_create_action_button("Sell All", func(): _sell_all(good_id)))
		goods_list.add_child(row)

func _create_action_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(90, 52)
	button.pressed.connect(callback)
	return button

func _buy_qty(good_id: String, qty: int) -> void:
	var result := market_system.buy(good_id, qty)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _buy_max(good_id: String) -> void:
	var max_buy := market_system.get_max_buy_quantity(good_id)
	if max_buy <= 0:
		info_label.text = "Cannot buy more %s." % GameData.get_good(good_id).get("name", good_id)
		return
	_buy_qty(good_id, max_buy)

func _sell_qty(good_id: String, qty: int) -> void:
	var result := market_system.sell(good_id, qty)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _sell_all(good_id: String) -> void:
	var owned := int(GameState.cargo.get(good_id, 0))
	if owned <= 0:
		info_label.text = "No %s to sell." % GameData.get_good(good_id).get("name", good_id)
		return
	_sell_qty(good_id, owned)

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
