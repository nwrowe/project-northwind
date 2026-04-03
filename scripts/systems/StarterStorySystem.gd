class_name StarterStorySystem
extends RefCounted

const PORT_ID := "aurelia"
const SOURCE_PORT_ID := "varenna"
const STARTER_GOOD_ID := "grain"
const STARTER_QUANTITY := 2
const STARTER_ADVANCE_SUPPLIES := 3
const STARTER_PAYOUT := 58
const REPEAT_ADVANCE_SUPPLIES := 2
const REPEAT_PAYOUT := 52

const STAGE_INN_INTRO := "inn_intro_available"
const STAGE_JOB_OFFER := "inn_job_offer"
const STAGE_JOB_ACTIVE := "inn_job_active"
const STAGE_REPEATABLE := "inn_repeatable"

func is_relevant_port() -> bool:
	return GameState.current_port_id == PORT_ID

func has_active_inn_order() -> bool:
	return not GameState.inn_supply_order.is_empty()

func get_sleep_cost() -> int:
	if GameState.starter_bridge_out:
		return 0
	if GameState.free_inn_nights > 0:
		return 0
	return 2 + GameState.crew_count

func consume_sleep_payment() -> void:
	if GameState.starter_bridge_out:
		return
	if GameState.free_inn_nights > 0:
		GameState.free_inn_nights = max(0, GameState.free_inn_nights - 1)
		return
	GameState.money -= get_sleep_cost()

func get_tavern_story_view() -> Dictionary:
	if not is_relevant_port():
		return {"visible": false}

	if has_active_inn_order():
		var order: Dictionary = GameState.inn_supply_order
		var quantity: int = int(order.get("quantity", 0))
		var good_id: String = str(order.get("good_id", ""))
		var source_port: String = str(order.get("source_port", SOURCE_PORT_ID))
		var payout: int = int(order.get("payout", 0))
		var advance_money: int = int(order.get("advance_money", 0))
		var advance_supplies: int = int(order.get("advance_supplies", 0))
		var source_name: String = str(GameData.get_port(source_port).get("name", source_port))
		var good_name: String = str(GameData.get_good(good_id).get("name", good_id))
		if can_deliver_active_order():
			return {
				"visible": true,
				"title": "Lantern Cup Delivery",
				"text": "You made it back with %d %s. The innkeeper is waiting to unload the supplies and settle the promised pay." % [quantity, good_name],
				"action_text": "Deliver Supplies",
				"action_id": "deliver_inn_order",
			}
		return {
			"visible": true,
			"title": "Lantern Cup Supply Run",
			"text": "The inn still needs %d %s from %s. Last night's severe storm knocked out the bridge, so the rowboat crossing is the only fast way over. You were advanced %d gold and %d supplies to make the run possible. Payment on return will be %d gold." % [quantity, good_name, source_name, advance_money, advance_supplies, payout],
			"action_text": "",
			"action_id": "",
		}

	match GameState.inn_supply_story_stage:
		STAGE_INN_INTRO:
			return {
				"visible": true,
				"title": "A Bed for the Night",
				"text": "The storm that washed you ashore also knocked out the bridge to Varenna. Maris has already spoken to the Lantern Cup for you. The innkeeper offers you a room for free while the town sorts itself out after the damage.",
				"action_text": "Accept Free Room",
				"action_id": "accept_free_room",
			}
		STAGE_JOB_OFFER:
			return {
				"visible": true,
				"title": "A First Real Errand",
				"text": "With the bridge down, the inn's regular supply run from Varenna has failed. The innkeeper asks if the rowboat outside is yours. If you can cross over and fetch 2 Grain, the Lantern Cup will cover your costs, keep your room, and pay you on return.",
				"action_text": "Accept Supply Run",
				"action_id": "accept_supply_run",
			}
		STAGE_REPEATABLE:
			return {
				"visible": true,
				"title": "Lantern Cup Orders",
				"text": "Until the bridge is repaired, the Lantern Cup still needs small urgent runs from Varenna. Your room remains covered as long as you keep helping the inn stay stocked.",
				"action_text": "Ask for Another Run",
				"action_id": "accept_supply_run",
			}
		_:
			return {"visible": false}

func handle_tavern_story_action(action_id: String) -> Dictionary:
	match action_id:
		"accept_free_room":
			return _accept_free_room()
		"accept_supply_run":
			return _accept_supply_run()
		"deliver_inn_order":
			return _deliver_inn_order()
		_:
			return {"success": false, "message": "Nothing happens."}

func get_market_story_hint() -> String:
	if not has_active_inn_order():
		return ""
	var order: Dictionary = GameState.inn_supply_order
	var source_port: String = str(order.get("source_port", SOURCE_PORT_ID))
	if GameState.current_port_id != source_port:
		return ""
	var quantity: int = int(order.get("quantity", 0))
	var good_id: String = str(order.get("good_id", ""))
	var good_name: String = str(GameData.get_good(good_id).get("name", good_id))
	return "Inn order: buy %d %s for the Lantern Cup in Aurelia while the bridge is out." % [quantity, good_name]

func can_deliver_active_order() -> bool:
	if not has_active_inn_order():
		return false
	var order: Dictionary = GameState.inn_supply_order
	var good_id: String = str(order.get("good_id", ""))
	var quantity: int = int(order.get("quantity", 0))
	return GameState.current_port_id == PORT_ID and int(GameState.cargo.get(good_id, 0)) >= quantity

func _accept_free_room() -> Dictionary:
	if GameState.inn_supply_story_stage != STAGE_INN_INTRO:
		return {"success": false, "message": "The room arrangement has already been made."}
	GameState.free_inn_nights = max(GameState.free_inn_nights, 1)
	GameState.inn_supply_story_stage = STAGE_JOB_OFFER
	return {"success": true, "message": "You are given a dry room upstairs for the night. Over soup and low voices, you learn the storm wrecked the bridge to Varenna and stranded the inn's normal food run."}

func _accept_supply_run() -> Dictionary:
	if has_active_inn_order():
		return {"success": false, "message": "You already have an active Lantern Cup supply run."}
	if GameState.inn_supply_story_stage != STAGE_JOB_OFFER and GameState.inn_supply_story_stage != STAGE_REPEATABLE:
		return {"success": false, "message": "The innkeeper has no supply job for you right now."}
	var first_run: bool = GameState.inn_supply_runs_completed == 0
	var order: Dictionary = _build_inn_order(first_run)
	GameState.inn_supply_order = order
	GameState.money += int(order.get("advance_money", 0))
	GameState.supplies += int(order.get("advance_supplies", 0))
	GameState.inn_supply_story_stage = STAGE_JOB_ACTIVE
	var source_name: String = str(GameData.get_port(str(order.get("source_port", SOURCE_PORT_ID))).get("name", SOURCE_PORT_ID))
	return {"success": true, "message": "The innkeeper gives you %d gold, adds %d supplies to your rowboat, and asks for %d Grain from %s. With the bridge gone, the rowboat is the fastest way to make the crossing." % [int(order.get("advance_money", 0)), int(order.get("advance_supplies", 0)), int(order.get("quantity", 0)), source_name]}

func _deliver_inn_order() -> Dictionary:
	if not can_deliver_active_order():
		return {"success": false, "message": "You do not yet have the supplies the inn requested."}
	var order: Dictionary = GameState.inn_supply_order
	var good_id: String = str(order.get("good_id", ""))
	var quantity: int = int(order.get("quantity", 0))
	var payout: int = int(order.get("payout", 0))
	GameState.add_cargo(good_id, -quantity)
	GameState.money += payout
	GameState.change_reputation(1, 0)
	GameState.inn_supply_order = {}
	GameState.inn_supply_runs_completed += 1
	GameState.inn_supply_story_stage = STAGE_REPEATABLE
	return {"success": true, "message": "The Lantern Cup takes the food at once. The innkeeper pays you %d gold and tells you the room is still yours while the bridge stays down and the inn keeps needing help." % payout}

func _build_inn_order(first_run: bool) -> Dictionary:
	var advance_money: int = _get_required_purchase_money(STARTER_GOOD_ID, STARTER_QUANTITY)
	return {
		"source_port": SOURCE_PORT_ID,
		"target_port": PORT_ID,
		"good_id": STARTER_GOOD_ID,
		"quantity": STARTER_QUANTITY,
		"advance_money": advance_money,
		"advance_supplies": STARTER_ADVANCE_SUPPLIES if first_run else REPEAT_ADVANCE_SUPPLIES,
		"payout": STARTER_PAYOUT if first_run else REPEAT_PAYOUT,
	}

func _get_required_purchase_money(good_id: String, quantity: int) -> int:
	var market_system := MarketSystem.new()
	return market_system.get_buy_price(SOURCE_PORT_ID, good_id) * quantity
