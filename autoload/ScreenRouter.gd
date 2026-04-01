extends Node

var screen_root: Node = null

const OPENING_SCENE := preload("res://scenes/opening/OpeningShore.tscn")
const PORT_SCREEN := preload("res://scenes/port/PortScreen.tscn")
const MARKET_SCREEN := preload("res://scenes/market/MarketScreen.tscn")
const MARKET_LOG_SCREEN := preload("res://scenes/market/MarketLogScreen.tscn")
const TRAVEL_SCREEN := preload("res://scenes/travel/TravelScreen.tscn")
const EVENT_POPUP := preload("res://scenes/events/EventPopup.tscn")
const UPGRADE_PANEL := preload("res://scenes/upgrades/UpgradePanel.tscn")
const CONTRACT_SCREEN := preload("res://scenes/contracts/ContractScreen.tscn")
const REPAIR_SCREEN := preload("res://scenes/repair/RepairScreen.tscn")
const SHIPYARD_SCREEN := preload("res://scenes/shipyard/ShipyardScreen.tscn")
const TAVERN_SCREEN := preload("res://scenes/tavern/TavernScreen.tscn")
const CHANDLERY_SCREEN := preload("res://scenes/chandlery/ChandleryScreen.tscn")
const OFFICE_SCREEN := preload("res://scenes/office/OfficeStorageScreen.tscn")

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

func show_opening_scene() -> void:
	_show_scene(OPENING_SCENE)
func show_port_screen() -> void:
	_show_scene(PORT_SCREEN)
func show_market_screen() -> void:
	_show_scene(MARKET_SCREEN)
func show_market_log_screen() -> void:
	_show_scene(MARKET_LOG_SCREEN)
func show_travel_screen() -> void:
	_show_scene(TRAVEL_SCREEN)
func show_upgrade_panel() -> void:
	_show_scene(UPGRADE_PANEL)
func show_contract_screen() -> void:
	_show_scene(CONTRACT_SCREEN)
func show_repair_screen() -> void:
	_show_scene(REPAIR_SCREEN)
func show_shipyard_screen() -> void:
	_show_scene(SHIPYARD_SCREEN)
func show_tavern_screen() -> void:
	_show_scene(TAVERN_SCREEN)
func show_chandlery_screen() -> void:
	_show_scene(CHANDLERY_SCREEN)
func show_office_screen() -> void:
	_show_scene(OFFICE_SCREEN)
func show_event_popup(payload: Dictionary) -> void:
	var popup := _show_scene(EVENT_POPUP)
	if popup.has_method("set_payload"):
		popup.set_payload(payload)
