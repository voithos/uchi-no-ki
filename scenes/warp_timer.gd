# A scene similar to Timer, but that takes into account the time_warp scale.
extends Node2D

export (float) var timeout = 0

var time_so_far = 0
export (bool) var is_running = false

signal timeout

func _ready():
    pass

func _process(delta):
    if is_running:
        time_so_far += delta * time_warp.time_scale
        if time_so_far >= timeout:
            emit_signal("timeout")
            is_running = false

func start():
    is_running = true
    time_so_far = 0
    show()
