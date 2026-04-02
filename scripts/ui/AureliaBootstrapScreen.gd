extends Control

var bootstrap_system := AureliaBootstrapSystem.new()

@onready var header_label = $VBoxContainer/HeaderLabel
@onready var goal_label = $VBoxContainer/IntroPanel/VBoxContainer/GoalLabel
@onready var status_label = $VBoxContainer/IntroPanel/VBoxContainer/StatusLabel
@onready var jobs_list = $VBoxContainer/JobsScroll/VBoxContainer/JobsList
@onready var info_label = $VBoxContainer/FooterPanel/VBoxContainer/InfoLabel

func _ready() -> void:
	$VBoxContainer/FooterPanel/VBoxContainer/ButtonRow/BackButton.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui() -> void:
	header_label.text = "Dockside Work - Aurelia"
	goal_label.text = bootstrap_system.get_goal_summary()
	status_label.text = "Current: %s | Money %d | Supplies %d | Ship %s" % [GameState.get_day_and_time_string(), GameState.money, GameState.supplies, GameData.get_ship(GameState.ship_id).get("name", GameState.ship_id)]
	for child in jobs_list.get_children():
		child.queue_free()

	var jobs: Array = bootstrap_system.get_jobs()
	if jobs.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No dockside work is available right now. Try again later in the day."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		jobs_list.add_child(empty_label)
		return

	for job in jobs:
		_add_job_row(job)

func _add_job_row(job: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var outer := HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(outer)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(info_box)

	var title := Label.new()
	title.text = "%s | %dh | %d gold%s" % [
		str(job.get("name", "Job")),
		int(job.get("hours", 0)),
		int(job.get("gold", 0)),
		(" | %d supply" % int(job.get("supplies", 0))) if int(job.get("supplies", 0)) > 0 else ""
	]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(title)

	var detail := Label.new()
	detail.text = "%s\n%s" % [str(job.get("description", "")), str(job.get("note", ""))]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(detail)

	var button := Button.new()
	button.text = "Work"
	button.custom_minimum_size = Vector2(120, 52)
	button.pressed.connect(_on_job_pressed.bind(str(job.get("id", ""))))
	outer.add_child(button)

	jobs_list.add_child(card)

func _on_job_pressed(job_id: String) -> void:
	var result: Dictionary = bootstrap_system.do_job(job_id)
	info_label.text = str(result.get("message", ""))
	refresh_ui()

func _on_back_pressed() -> void:
	ScreenRouter.show_port_screen()
