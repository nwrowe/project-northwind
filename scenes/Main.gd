extends Control

@onready var screen_root = $SafeArea/ScreenRoot

func _ready() -> void:
	randomize()
	GameData.load_all_data()
	ScreenRouter.set_root(screen_root)

	if SaveManager.has_save():
		var result := SaveManager.load_game()
		if not result.get("success", false):
			GameState.new_game()
	else:
		GameState.new_game()

	ScreenRouter.show_port_screen()
