extends Node2D

const FIRST_LEVEL = "res://scenes/levels/1_intro_level.tscn"

func _ready():
    music.play_background()

func _input(event):
    if Input.is_action_pressed("ki_burst"):
        # Start the game.
        var transition = get_tree().get_nodes_in_group("transition")[0]
        transition.connect("fade_complete", self, "_load_next_level")
        transition.begin_fade()

func _load_next_level():
    get_tree().change_scene(FIRST_LEVEL)
