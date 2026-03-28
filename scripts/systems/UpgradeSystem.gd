class_name UpgradeSystem
extends RefCounted

func get_available_upgrades() -> Array:
	var results: Array = []
	for upgrade in GameData.upgrades_list:
		if not GameState.has_upgrade(upgrade.get("id", "")):
			results.append(upgrade)
	return results

func can_buy_upgrade(upgrade_id: String) -> bool:
	var upgrade := GameData.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return false
	if GameState.has_upgrade(upgrade_id):
		return false
	return GameState.money >= int(upgrade.get("cost", 0))

func buy_upgrade(upgrade_id: String) -> Dictionary:
	if not can_buy_upgrade(upgrade_id):
		return {"success": false, "message": "Cannot buy upgrade."}

	var upgrade := GameData.get_upgrade(upgrade_id)
	GameState.money -= int(upgrade.get("cost", 0))
	GameState.apply_upgrade(upgrade_id)

	return {
		"success": true,
		"message": "Purchased %s." % upgrade.get("name", upgrade_id),
	}
