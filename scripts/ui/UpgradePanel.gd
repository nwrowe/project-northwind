extends Control

var upgrade_system := UpgradeSystem.new()

@onready var upgrade_list = $VBoxContainer/UpgradesScroll/VBoxContainer/UpgradeList
@onready var info_label = $VBoxContainer/FooterPanel/HBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	for child in upgrade_list.get_children():
		child.queue_free()

	for upgrade in upgrade_system.get_available_upgrades():
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s  Cost:%d" % [upgrade.get("name", "Upgrade"), int(upgrade.get("cost", 0))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var button := Button.new()
		button.text = "Buy"
		var upgrade_id := upgrade.get("id", "")
		button.pressed.connect(func(): _buy_upgrade(upgrade_id))

		row.add_child(label)
		row.add_child(button)
		upgrade_list.add_child(row)

func _buy_upgrade(upgrade_id: String) -> void:
	var result := upgrade_system.buy_upgrade(upgrade_id)
	info_label.text = result.get("message", "")
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
