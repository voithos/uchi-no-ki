extends TextureProgress

export (float) var timeout = 0

var time_so_far = 0
var is_running = false

signal timeout

func _ready():
    hide()

func _process(delta):
    if is_running:
        time_so_far += delta * time_warp.time_scale
        _update_progress()
        if time_so_far >= timeout:
            emit_signal("timeout")
            is_running = false
            hide()

func start_timer():
    is_running = true
    time_so_far = 0
    _update_progress()
    show()
    
func _update_progress():
    var percent = (time_so_far / timeout) * 100
    # We count down, so the percent is the opposite of our value.
    value = 100 - percent
