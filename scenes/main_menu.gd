extends Node2D

var incomplete_texture = preload("res://assets/ui/level_incomplete.png")
var locked_texture = preload("res://assets/ui/level_locked.png")

const FIRST_LEVEL = "1_intro_level"

var LEVELS = {
    "1_intro_level": "res://scenes/levels/1_intro_level.tscn",
    "2_button_madness": "res://scenes/levels/2_button_madness.tscn",
    "3_midair_shenanigans": "res://scenes/levels/3_midair_shenanigans.tscn",
    "4_platforming": "res://scenes/levels/4_platforming.tscn",
    "5_mana_orb": "res://scenes/levels/5_mana_orb.tscn",
    "6_crystal_dash": "res://scenes/levels/6_crystal_dash.tscn",
    "7_finale": "res://scenes/levels/7_finale.tscn",
}

const HORIZ_OFFSET = 20
const START_OFFSET = -60
var is_selecting_level = false
var current_level_idx = 0
var max_available_idx = 0

func _ready():
    music.play_background()
    saving.load_game()

func _input(event):
    if Input.is_action_just_pressed("ki_burst"):
        if is_selecting_level:
            _transition_to_level(LEVELS.keys()[current_level_idx])
        else:
            _maybe_initialize_level_select()
    elif Input.is_action_just_pressed("move_left"):
        current_level_idx = max(0, current_level_idx - 1)
    elif Input.is_action_just_pressed("move_right"):
        current_level_idx = min(max_available_idx, current_level_idx + 1)
    
    $canvas/level_select/Cursor.position.x = current_level_idx * HORIZ_OFFSET + START_OFFSET

func _maybe_initialize_level_select():
    $animation.stop()
    $canvas/press_space.hide()
    
    var first_incomplete = null
    for lvl in LEVELS:
        # State is "completed" by default. Find the first incomplete one.
        if !progression_store.has_completed_level(lvl):
            var sprite = get_node("canvas/level_select/l" + lvl.left(1))
            if first_incomplete == null:
                first_incomplete = lvl
                sprite.set_texture(incomplete_texture)
            else:
                sprite.set_texture(locked_texture)
    
    if first_incomplete == FIRST_LEVEL:
        # Automatically start the first level if this is the first time a user has begun the game.
        _transition_to_level(FIRST_LEVEL)
        return
    
    $canvas/level_select.show()
    $animation.play("cursor")
    is_selecting_level = true
    if first_incomplete == null:
        max_available_idx = 6
    else:
        max_available_idx = int(first_incomplete.left(1)) - 1
        current_level_idx = max_available_idx

func _transition_to_level(lvl):
    var transition = get_tree().get_nodes_in_group("transition")[0]
    transition.connect("fade_complete", self, "_load_level", [lvl])
    transition.begin_fade()

func _load_level(lvl):
    get_tree().change_scene(LEVELS[lvl])
