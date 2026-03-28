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
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "%s  Buy:%d Sell:%d Owned:%d" % [
			good.get("name", good_id),
			market_system.get_local_price(GameState.current_port_id, good_id),
			market_system.get_local_price(GameState.current_port_id, good_id),
			int(GameState.cargo.get(good_id, 0))
		]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var buy_button := Button.new()
		buy_button.text = "Buy 1"
		buy_button.pressed.connect(func(): _buy_one(good_id))

		var sell_button := Button.new()
		sell_button.text = "Sell 1"
		sell_button.pressed.connect(func(): _sell_one(good_id))

		row.add_child(name_label)
		row.add_child(buy_button)
		row.add_child(sell_button)
		goods_list.add_child(row)

func _buy_one(good_id: String) -> void:
	var result := market_system.buy(good_id, 1)
	info_label.text = result.get("message", "")
	refresh_ui()

func _sell_one(good_id: String) -> void:
	var result := market_system.sell(good_id, 1)
	info_label.text = result.get("message", "")
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
