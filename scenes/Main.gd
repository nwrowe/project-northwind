extends Control

@onready var screen_root = $SafeArea/ScreenRoot

func _ready() -> void:
	randomize()
	if not GameData.load_all_data():
		push_error(GameData.get_validation_report())
		get_tree().quit(1)
		return

	ScreenRouter.set_root(screen_root)

	if SaveManager.has_any_save():
		var result: Dictionary = SaveManager.load_latest_game()
		if not result.get("success", false):
			GameState.new_game()
			ScreenRouter.show_opening_scene()
			return
		ScreenRouter.show_port_screen()
		return

	GameState.new_game()
	ScreenRouter.show_opening_scene()
