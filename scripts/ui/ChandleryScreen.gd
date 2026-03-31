extends Control

var chandlery_system := ChandlerySystem.new()

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var status_label = $VBoxContainer/StatusPanel/VBoxContainer/StatusLabel
@onready var price_label = $VBoxContainer/StatusPanel/VBoxContainer/PriceLabel
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/OptionsPanel/VBoxContainer/Buy1Button.pressed.connect(func(): _buy_amount(1))
	$VBoxContainer/OptionsPanel/VBoxContainer/Buy3Button.pressed.connect(func(): _buy_amount(3))
	$VBoxContainer/OptionsPanel/VBoxContainer/BuyMaxButton.pressed.connect(_buy_max)
	$VBoxContainer/FooterPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	header_label.text = "Chandlery - %s" % port.get("name", "Port")
	status_label.text = "Supplies: %d / %d | Missing: %d | Money: %d" % [GameState.supplies, chandlery_system.get_max_supplies(), chandlery_system.get_missing_supplies(), GameState.money]
	price_label.text = "Unit cost: %d | Max affordable: %d" % [chandlery_system.get_unit_cost(), chandlery_system.get_max_affordable_supplies()]
	$VBoxContainer/OptionsPanel/VBoxContainer/Buy1Button.disabled = chandlery_system.get_max_affordable_supplies() < 1
	$VBoxContainer/OptionsPanel/VBoxContainer/Buy3Button.disabled = chandlery_system.get_max_affordable_supplies() < 3
	$VBoxContainer/OptionsPanel/VBoxContainer/BuyMaxButton.disabled = chandlery_system.get_max_affordable_supplies() < 1

func _buy_amount(amount: int) -> void:
	var result: Dictionary = chandlery_system.buy_supplies(amount)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _buy_max() -> void:
	_buy_amount(chandlery_system.get_max_affordable_supplies())

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
