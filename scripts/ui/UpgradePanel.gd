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
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var outer := HBoxContainer.new()
		outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(outer)

		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer.add_child(info_box)

		var label := Label.new()
		label.text = "%s  Cost:%d" % [upgrade.get("name", "Upgrade"), int(upgrade.get("cost", 0))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_box.add_child(label)

		var detail := Label.new()
		detail.text = _build_effect_summary(upgrade.get("effects", {}))
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.add_child(detail)

		var button := Button.new()
		button.text = "Buy"
		button.custom_minimum_size = Vector2(120, 52)
		var upgrade_id: String = str(upgrade.get("id", ""))
		button.pressed.connect(func(): _buy_upgrade(upgrade_id))
		outer.add_child(button)

		upgrade_list.add_child(card)

func _build_effect_summary(effects: Dictionary) -> String:
	var parts: Array[String] = []
	if int(effects.get("cargo_capacity_bonus", 0)) != 0:
		parts.append("Cargo %+d" % int(effects.get("cargo_capacity_bonus", 0)))
	if int(effects.get("max_durability_bonus", 0)) != 0:
		parts.append("Durability %+d" % int(effects.get("max_durability_bonus", 0)))
	if float(effects.get("speed_bonus", 0.0)) != 0.0:
		parts.append("Speed %+0.2f" % float(effects.get("speed_bonus", 0.0)))
	if float(effects.get("supply_efficiency_bonus", 0.0)) != 0.0:
		parts.append("Supply Eff %+0.2f" % float(effects.get("supply_efficiency_bonus", 0.0)))
	if int(effects.get("firepower_bonus", 0)) != 0:
		parts.append("Firepower %+d" % int(effects.get("firepower_bonus", 0)))
	if int(effects.get("hull_armor_bonus", 0)) != 0:
		parts.append("Armor %+d" % int(effects.get("hull_armor_bonus", 0)))
	if int(effects.get("evasion_bonus", 0)) != 0:
		parts.append("Evasion %+d" % int(effects.get("evasion_bonus", 0)))
	if int(effects.get("intimidation_bonus", 0)) != 0:
		parts.append("Intimidation %+d" % int(effects.get("intimidation_bonus", 0)))
	if int(effects.get("crew_capacity_bonus", 0)) != 0:
		parts.append("Crew %+d" % int(effects.get("crew_capacity_bonus", 0)))
	if int(effects.get("officer_slots_bonus", 0)) != 0:
		parts.append("Officer Slots %+d" % int(effects.get("officer_slots_bonus", 0)))
	if int(effects.get("boarding_strength_bonus", 0)) != 0:
		parts.append("Boarding %+d" % int(effects.get("boarding_strength_bonus", 0)))
	if parts.is_empty():
		return "No mechanical effect listed."
	return ", ".join(parts)

func _buy_upgrade(upgrade_id: String) -> void:
	var result := upgrade_system.buy_upgrade(upgrade_id)
	info_label.text = result.get("message", "")
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
