extends Node2D

export (String, FILE, "*.tscn") var next_level

func _ready():
    add_to_group("levels")
    music.play_background()
