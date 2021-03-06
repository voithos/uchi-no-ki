extends Node

const SLOW_TIME_SCALE = 0.07
const SLOWDOWN_TIME = 0.4
var time_scale = 1.0

var camera = null
const SLOWDOWN_CAMERA_ZOOM = 0.7

onready var time_tween = Tween.new()

func _ready():
    add_child(time_tween)

func slowdown(slow_time_scale=SLOW_TIME_SCALE, slowdown_time=SLOWDOWN_TIME):
    time_tween.remove_all()
    time_tween.interpolate_method(
        self, "_set_time_scale", time_scale, slow_time_scale, slowdown_time, Tween.TRANS_QUAD, Tween.EASE_OUT)
    time_tween.start()

func speedup(slowdown_time=SLOWDOWN_TIME):
    time_tween.remove_all()
    time_tween.interpolate_method(
        self, "_set_time_scale", time_scale, 1.0, slowdown_time, Tween.TRANS_QUAD, Tween.EASE_IN)
    time_tween.start()

func _set_time_scale(scale):
    time_scale = scale
    if camera:
        # TODO: This doesn't work exactly when custom time scales are used.
        var r = 1.0 - SLOW_TIME_SCALE
        var zoom = lerp(1.0, SLOWDOWN_CAMERA_ZOOM, (1.0 - scale) / r)
        camera.zoom.x = zoom
        camera.zoom.y = zoom

func set_camera(c):
    camera = c
