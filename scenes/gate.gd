extends Sprite

export var is_open = false
var next_anim = ""
var last_anim = ""

func _ready():
    add_to_group("gates")
    if is_open:
        $animation.play("close")
    else:
        $animation.play("open")
    
    $animation.seek(0, true)
    $animation.stop()
    
    _add_to_gate_group()

func _input(event):
#    if OS.is_debug_build() and event is InputEventKey and event.is_action_pressed("debug"):
#        toggle()
    pass

func open():
    if !is_open:
        _queue_anim("open")
        is_open = true

func close():
    if is_open:
        _queue_anim("close")
        is_open = false

func _queue_anim(anim):
    if !$animation.is_playing():
        $animation.play(anim)
        last_anim = anim
        return
    next_anim = anim
    yield($animation, "animation_finished")
    # Could've gotten interrupted in the interim
    if !$animation.is_playing() and last_anim != next_anim:
        $animation.play(next_anim)
        last_anim = anim

func toggle():
    if is_open:
        close()
    else:
        open()

func _add_to_gate_group():
    $"..".add_gate(self)
