extends Node

var screen_root: Node = null

const PORT_SCREEN := preload("res://scenes/port/PortScreen.tscn")
const MARKET_SCREEN := preload("res://scenes/market/MarketScreen.tscn")
const TRAVEL_SCREEN := preload("res://scenes/travel/TravelScreen.tscn")
const EVENT_POPUP := preload("res://scenes/events/EventPopup.tscn")
const UPGRADE_PANEL := preload("res://scenes/upgrades/UpgradePanel.tscn")
const CONTRACT_SCREEN := preload("res://scenes/contracts/ContractScreen.tscn")
const REPAIR_SCREEN := preload("res://scenes/repair/RepairScreen.tscn")

func set_root(node: Node) -> void:
	screen_root = node

func _clear_root() -> void:
	if screen_root == null:
		return
	for child in screen_root.get_children():
		child.queue_free()

func _show_scene(scene: PackedScene) -> Node:
	_clear_root()
	var instance := scene.instantiate()
	screen_root.add_child(instance)
	return instance

func show_port_screen() -> void:
	_show_scene(PORT_SCREEN)

func show_market_screen() -> void:
	_show_scene(MARKET_SCREEN)

func show_travel_screen() -> void:
	_show_scene(TRAVEL_SCREEN)

func show_upgrade_panel() -> void:
	_show_scene(UPGRADE_PANEL)

func show_contract_screen() -> void:
	_show_scene(CONTRACT_SCREEN)

func show_repair_screen() -> void:
	_show_scene(REPAIR_SCREEN)

func show_event_popup(payload: Dictionary) -> void:
	var popup := _show_scene(EVENT_POPUP)
	if popup.has_method("set_payload"):
		popup.set_payload(payload)
