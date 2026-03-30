extends Control

var repair_system := RepairSystem.new()

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var durability_label = $VBoxContainer/StatusPanel/VBoxContainer/DurabilityLabel
@onready var rate_label = $VBoxContainer/StatusPanel/VBoxContainer/RateLabel
@onready var full_cost_label = $VBoxContainer/StatusPanel/VBoxContainer/FullCostLabel
@onready var affordable_label = $VBoxContainer/StatusPanel/VBoxContainer/AffordableLabel
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/OptionsPanel/VBoxContainer/Repair1Button.pressed.connect(func(): _repair_points(1))
	$VBoxContainer/OptionsPanel/VBoxContainer/Repair5Button.pressed.connect(func(): _repair_points(5))
	$VBoxContainer/OptionsPanel/VBoxContainer/Repair10Button.pressed.connect(func(): _repair_points(10))
	$VBoxContainer/OptionsPanel/VBoxContainer/RepairAffordableButton.pressed.connect(_repair_affordable)
	$VBoxContainer/OptionsPanel/VBoxContainer/RepairFullButton.pressed.connect(_repair_full)
	$VBoxContainer/FooterPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var port: Dictionary = GameData.get_port(GameState.current_port_id)
	var missing: int = repair_system.get_missing_durability()
	var full_cost: int = repair_system.get_full_repair_cost()
	var affordable_points: int = repair_system.get_max_affordable_repair_points()
	header_label.text = "Repair - %s" % port.get("name", "Port")
	durability_label.text = "Durability: %d / %d  (Missing %d)" % [
		GameState.ship_durability,
		GameState.get_effective_max_durability(),
		missing,
	]
	rate_label.text = "Repair rate: %.2f coins per durability" % repair_system.get_repair_rate()
	full_cost_label.text = "Full repair cost: %d" % full_cost
	affordable_label.text = "Money: %d  |  Max affordable repair: %d" % [GameState.money, affordable_points]

	$VBoxContainer/OptionsPanel/VBoxContainer/Repair1Button.disabled = not repair_system.can_repair(1)
	$VBoxContainer/OptionsPanel/VBoxContainer/Repair5Button.disabled = not repair_system.can_repair(min(5, max(1, missing)))
	$VBoxContainer/OptionsPanel/VBoxContainer/Repair10Button.disabled = not repair_system.can_repair(min(10, max(1, missing)))
	$VBoxContainer/OptionsPanel/VBoxContainer/RepairAffordableButton.disabled = affordable_points <= 0
	$VBoxContainer/OptionsPanel/VBoxContainer/RepairFullButton.disabled = missing <= 0 or GameState.money < full_cost

	if missing <= 0:
		info_label.text = "Ship is already fully repaired."

func _repair_points(points: int) -> void:
	var result: Dictionary = repair_system.repair(points)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _repair_affordable() -> void:
	var result: Dictionary = repair_system.repair_max_affordable()
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _repair_full() -> void:
	var result: Dictionary = repair_system.repair_full()
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
