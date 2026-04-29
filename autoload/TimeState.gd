extends Node

## Focused facade for game clock and weather state.
##
## This intentionally delegates to GameState for now so the refactor can land safely
## without changing save formats or gameplay behavior. Future passes can move the
## underlying fields here once callers have been migrated to this service.

func advance_seconds(seconds: float) -> void:
	GameState.advance_game_time_seconds(seconds)

func advance_days(days: float) -> void:
	GameState.advance_game_time_days(days)

func set_time_seconds(total_seconds: float) -> void:
	GameState.set_game_time_seconds(total_seconds)

func sleep_until_next_morning() -> void:
	GameState.sleep_until_next_morning()

func get_time_of_day_seconds() -> int:
	return GameState.get_time_of_day_seconds()

func get_clock_string() -> String:
	return GameState.get_clock_string()

func get_day_and_time_string() -> String:
	return GameState.get_day_and_time_string()

func get_day_count() -> int:
	return GameState.day_count

func get_weather_id() -> String:
	return GameState.current_weather

func get_weather_display_name() -> String:
	return GameState.get_weather_display_name()

func is_rainy() -> bool:
	return GameState.is_rainy_weather()

func is_severe_storm() -> bool:
	return GameState.is_severe_storm_weather()
