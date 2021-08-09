extends TextureProgress

export (float) var timeout = 0

var time_so_far = 0
var is_running = false

signal timeout

func _ready():
    hide()

func _process(delta):
    _update_progress()

func start_timer():
    is_running = true
    $warp_timer.timeout = timeout
    $warp_timer.start()
    _update_progress()
    show()
    
    yield($warp_timer, "timeout")
    emit_signal("timeout")
    is_running = false
    hide()
    
func _update_progress():
    if !is_running:
        return
    var percent = ($warp_timer.time_so_far / timeout) * 100
    # We count down, so the percent is the opposite of our value.
    value = 100 - percent
