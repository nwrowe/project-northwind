extends Control

const PLAYER_SPEED := 240.0
const PLAYER_MARGIN := 18.0
const OBJECTIVE_MOVE := "Get your footing."
const OBJECTIVE_BOAT := "Inspect the rowboat."
const OBJECTIVE_DOCK := "Follow the lantern path to the old dock."
const OBJECTIVE_FISHER := "Speak to the fisher by the dock."
const OBJECTIVE_DONE := "Head inland."

@onready var world := $World
@onready var player := $World/Player
@onready var boat_zone := $World/BoatZone
@onready var satchel_zone := $World/SatchelZone
@onready var fisher_zone := $World/FisherZone
@onready var dock_glow := $World/DockGlow
@onready var satchel := $World/Satchel
@onready var objective_label := $HUD/TopPanel/MarginContainer/VBoxContainer/ObjectiveLabel
@onready var hint_label := $HUD/TopPanel/MarginContainer/VBoxContainer/HintLabel
@onready var story_label := $HUD/BottomPanel/MarginContainer/StoryLabel
@onready var interact_label := $HUD/InteractPrompt
@onready var continue_button := $HUD/ContinueButton

var start_position := Vector2.ZERO
var has_moved := false
var boat_checked := false
var satchel_checked := false
var fisher_spoken := false
var transition_armed := false

func _ready() -> void:
	start_position = player.position
	objective_label.text = OBJECTIVE_MOVE
	hint_label.text = "Move with arrow keys or WASD. Press Enter to interact."
	story_label.text = "Cold surf. Splintered wood. The tide has already started to pull away."
	interact_label.visible = false
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	dock_glow.visible = false

func _process(delta: float) -> void:
	_handle_movement(delta)
	_update_progress()
	_update_interaction_prompt()

	if Input.is_action_just_pressed("ui_accept"):
		_handle_interaction()

func _handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector == Vector2.ZERO:
		return

	player.position += input_vector * PLAYER_SPEED * delta
	player.position.x = clamp(player.position.x, PLAYER_MARGIN, world.size.x - player.size.x - PLAYER_MARGIN)
	player.position.y = clamp(player.position.y, 250.0, world.size.y - player.size.y - PLAYER_MARGIN)

func _update_progress() -> void:
	if not has_moved and player.position.distance_to(start_position) > 24.0:
		has_moved = true
		objective_label.text = OBJECTIVE_BOAT
		hint_label.text = ""
		story_label.text = "Your legs hold. Barely."

	if boat_checked and not fisher_spoken:
		dock_glow.visible = true
		objective_label.text = OBJECTIVE_FISHER
	elif fisher_spoken:
		objective_label.text = OBJECTIVE_DONE

func _update_interaction_prompt() -> void:
	var prompt := ""
	if _is_near(boat_zone):
		prompt = "Inspect rowboat"
	elif _is_near(satchel_zone) and not satchel_checked:
		prompt = "Check satchel"
	elif _is_near(fisher_zone):
		prompt = "Speak to fisher"

	interact_label.visible = not prompt.is_empty()
	if not prompt.is_empty():
		interact_label.text = "%s [Enter]" % prompt

func _handle_interaction() -> void:
	if _is_near(boat_zone):
		_interact_boat()
		return
	if _is_near(satchel_zone) and not satchel_checked:
		_interact_satchel()
		return
	if _is_near(fisher_zone):
		_interact_fisher()

func _interact_boat() -> void:
	if not boat_checked:
		boat_checked = true
		story_label.text = "Salt, split timber, a torn strap. Nothing aboard tells you your name."
		objective_label.text = OBJECTIVE_DOCK
		return
	story_label.text = "The little boat is finished. Whatever carried you here will not carry you farther."

func _interact_satchel() -> void:
	satchel_checked = true
	satchel.visible = false
	story_label.text = "A waterlogged satchel. Empty, except for a brass token stamped with a windrose and a scratched-off crest."

func _interact_fisher() -> void:
	if not boat_checked:
		story_label.text = "The fisher squints at you. \"Easy now. See to your wreck first. Tide keeps its own ledger.\""
		return

	if not fisher_spoken:
		fisher_spoken = true
		story_label.text = "\"You look half-drowned, friend. Gull's Landing is up the bluff. Come warm yourself before you fall over.\""
		continue_button.visible = true
		transition_armed = true
		return

	story_label.text = "The fisher waits by the dock, patient and unsurprised."

func _on_continue_pressed() -> void:
	if not transition_armed:
		return
	GameState.current_port_id = "aurelia"
	GameState.pending_status_message = "You reached Aurelia soaked, nameless, and carrying only a brass token from the shore."
	ScreenRouter.show_port_screen()

func _is_near(node: Control) -> bool:
	var player_rect := Rect2(player.position, player.size)
	var zone_rect := Rect2(node.position, node.size).grow(20.0)
	return player_rect.intersects(zone_rect)
