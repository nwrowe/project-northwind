extends Control

const TILE_SIZE := 64
const WORLD_SIZE := Vector2(3072, 1792)
const PLAYER_SPEED := 260.0
const PLAYER_SIZE := Vector2(40, 56)
const PLAYER_MARGIN := 24.0
const CAMERA_TOP_LOCK := 0.0
const SHORE_MIN_Y := 220.0
const EXIT_ZONE_MARGIN := 48.0
const OBJECTIVE_MOVE := "Get your footing."
const OBJECTIVE_BOAT := "Inspect the rowboat."
const OBJECTIVE_DOCK := "Follow the shoreline lanterns to the storm-bent dock."
const OBJECTIVE_FISHER := "Speak to the fisher by the dock."
const OBJECTIVE_DONE := "Explore the beach and follow the path inland toward Aurelia."

const PLAYER_FRAME_PIXEL_SIZE := Vector2(16, 32)
const PLAYER_SPRITE_SCALE := 2.0
const PLAYER_SPRITE_FPS := 8.0

const PLAYER_FORWARD_FRAMES := [
	"res://art/characters/walking0.png",
	"res://art/characters/walking1.png",
	"res://art/characters/walking2.png",
	"res://art/characters/walking1.png",
]

@onready var world := $World
@onready var player := $World/Player
@onready var player_label: Label = $World/Player/PlayerLabel
@onready var boat_zone := $World/BoatZone
@onready var satchel_zone := $World/SatchelZone
@onready var fisher_zone := $World/FisherZone
@onready var dock_glow := $World/DockGlow
@onready var satchel := $World/Satchel
@onready var objective_label := $HUD/TopPanel/MarginContainer/VBoxContainer/ObjectiveLabel
@onready var hint_label := $HUD/TopPanel/MarginContainer/VBoxContainer/HintLabel
@onready var style_label := $HUD/TopPanel/MarginContainer/VBoxContainer/StyleLabel
@onready var story_label := $HUD/BottomPanel/MarginContainer/StoryLabel
@onready var interact_label := $HUD/InteractPrompt
@onready var continue_button := $HUD/ContinueButton
@onready var edge_hint_label := $HUD/EdgeHintLabel

var start_position := Vector2.ZERO
var has_moved := false
var boat_checked := false
var satchel_checked := false
var fisher_spoken := false
var transition_armed := false
var player_sprite: AnimatedSprite2D = null
var player_sprite_ready := false

func _ready() -> void:
	custom_minimum_size = get_viewport_rect().size
	start_position = player.position
	player.size = PLAYER_SIZE
	objective_label.text = OBJECTIVE_MOVE
	hint_label.text = "Move with arrow keys or WASD. Press Enter to interact. The world uses a 64x64 grid and is larger than the screen so you can explore."
	style_label.text = "Prototype target: warm storm-cleared coastal palette, water low on screen, broad beach above it, weathered wood dock, humble Mediterranean fishing edge."
	story_label.text = "The storm has only just passed. The sea has fallen back to the lower shore, leaving wreckage, kelp, and foam all along the beach."
	interact_label.visible = false
	edge_hint_label.visible = false
	continue_button.visible = false
	continue_button.text = "Continue to Aurelia"
	continue_button.pressed.connect(_on_continue_pressed)
	dock_glow.visible = false
	_setup_player_forward_walk_test()
	_update_camera()

func _process(delta: float) -> void:
	_handle_movement(delta)
	_update_progress()
	_update_interaction_prompt()
	_update_edge_hint()
	_update_camera()

	if Input.is_action_just_pressed("ui_accept"):
		if _handle_edge_transition():
			return
		_handle_interaction()

func _handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector == Vector2.ZERO:
		_set_player_idle_visual()
		return
	player.position += input_vector * PLAYER_SPEED * delta
	player.position.x = clamp(player.position.x, PLAYER_MARGIN, WORLD_SIZE.x - player.size.x - PLAYER_MARGIN)
	player.position.y = clamp(player.position.y, SHORE_MIN_Y, WORLD_SIZE.y - player.size.y - PLAYER_MARGIN)
	_set_player_walk_visual()

func _update_camera() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var target: Vector2 = player.position + player.size * 0.5 - viewport_size * 0.5
	target.x = clamp(target.x, 0.0, max(0.0, WORLD_SIZE.x - viewport_size.x))
	target.y = clamp(target.y, CAMERA_TOP_LOCK, max(CAMERA_TOP_LOCK, WORLD_SIZE.y - viewport_size.y))
	world.position = -target

func _update_progress() -> void:
	if not has_moved and player.position.distance_to(start_position) > 24.0:
		has_moved = true
		objective_label.text = OBJECTIVE_BOAT
		hint_label.text = "The first pass should teach the player: wreck, clue, human contact, then the inland route to town."
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

func _update_edge_hint() -> void:
	var near_north_exit: bool = player.position.x > 2460.0 and player.position.y < 360.0
	var near_east_exit: bool = player.position.x > WORLD_SIZE.x - 220.0 and player.position.y > 520.0 and player.position.y < 980.0
	edge_hint_label.visible = near_north_exit or near_east_exit
	if near_north_exit:
		edge_hint_label.text = "North exit: inland path to Aurelia [Enter]"
	elif near_east_exit:
		edge_hint_label.text = "East exit: upriver shoreline and bridge ruins [Enter]"

func _handle_edge_transition() -> bool:
	var near_north_exit: bool = player.position.x > 2460.0 and player.position.y < 360.0
	var near_east_exit: bool = player.position.x > WORLD_SIZE.x - 220.0 and player.position.y > 520.0 and player.position.y < 980.0
	if near_north_exit:
		_on_continue_pressed()
		return true
	if near_east_exit:
		story_label.text = "This edge is reserved for a future upriver scene, where you can later show the broken bridge and river crossing route."
		return true
	return false

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
		story_label.text = "The rowboat sits low on the lower shore so the player first reads the sea at the bottom, then the landing zone, then the climb into the rest of the map."
		objective_label.text = OBJECTIVE_DOCK
		return
	story_label.text = "Use this hook for your final rowboat sprite. Keep it close to the wet-sand band so it feels freshly washed up."

func _interact_satchel() -> void:
	satchel_checked = true
	satchel.visible = false
	story_label.text = "The satchel belongs in the mid-beach debris line, where it visually bridges the wreck landing and the path toward the dock district."

func _interact_fisher() -> void:
	if not boat_checked:
		story_label.text = "The fisher should be the last major anchor of the scene, so the player is nudged to inspect the wreck first."
		return

	if not fisher_spoken:
		fisher_spoken = true
		story_label.text = "The fisher marks the storm-bent dock as the human center of the shoreline. From here, the map opens inland toward Aurelia and east toward future river content."
		continue_button.visible = true
		transition_armed = true
		return

	story_label.text = "The fisher waits by the storm-bent pier, exactly where your final NPC sprite and idle animation can stand."

func _on_continue_pressed() -> void:
	if not transition_armed:
		transition_armed = true
	if Engine.has_singleton("GameState"):
		GameState.current_port_id = "aurelia"
		GameState.pending_status_message = "Prototype layout complete. Use this explorable map as the baseline for your final opening beach art pass and inland transition."
	if Engine.has_singleton("ScreenRouter"):
		ScreenRouter.show_port_screen()

func _is_near(node: Control) -> bool:
	var player_rect := Rect2(player.position, player.size)
	var zone_rect := Rect2(node.position, node.size).grow(24.0)
	return player_rect.intersects(zone_rect)

func _setup_player_forward_walk_test() -> void:
	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerForwardWalkSprite"
	player_sprite.centered = false
	player_sprite.z_index = 50
	player_sprite.position = Vector2(
		round((PLAYER_SIZE.x - PLAYER_FRAME_PIXEL_SIZE.x * PLAYER_SPRITE_SCALE) * 0.5),
		round(PLAYER_SIZE.y - PLAYER_FRAME_PIXEL_SIZE.y * PLAYER_SPRITE_SCALE)
	)
	player_sprite.scale = Vector2.ONE * PLAYER_SPRITE_SCALE
	player.add_child(player_sprite)

	var frames := SpriteFrames.new()
	frames.add_animation("forward_walk")
	frames.set_animation_loop("forward_walk", true)
	frames.set_animation_speed("forward_walk", PLAYER_SPRITE_FPS)

	for frame_path in PLAYER_FORWARD_FRAMES:
		var texture: Texture2D = load(frame_path) as Texture2D
		if texture != null:
			frames.add_frame("forward_walk", texture)

	if frames.get_frame_count("forward_walk") == 0:
		story_label.text = "Forward-walk test scene loaded, but walking0/1/2 PNGs were not found in res://art/characters."
		return

	player_sprite.sprite_frames = frames
	player_sprite.animation = "forward_walk"
	player_sprite.frame = 0
	player_sprite.stop()
	player_sprite_ready = true
	if is_instance_valid(player_label):
		player_label.visible = false
	player.self_modulate = Color(1, 1, 1, 0)
	story_label.text = "Forward-walk test loaded. The four front-facing PNGs are being reused for movement in every direction until the other directional sprites are ready."

func _set_player_walk_visual() -> void:
	if not player_sprite_ready or player_sprite == null:
		return
	if player_sprite.animation != "forward_walk":
		player_sprite.animation = "forward_walk"
	if not player_sprite.is_playing():
		player_sprite.play("forward_walk")

func _set_player_idle_visual() -> void:
	if not player_sprite_ready or player_sprite == null:
		return
	player_sprite.stop()
	player_sprite.frame = 0
