extends Sprite

export var is_open = false
export var is_latchable = false # "Latches" in a stuck position once it is engaged / disengaged
export var nodust = false
var is_latched = false

onready var default_state = is_open

var next_anim = ""
var last_anim = ""

func _ready():
    add_to_group("gates")
    if is_open:
        $animation.play(_anim_name("close"))
    else:
        $animation.play(_anim_name("open"))
    
    $animation.seek(0, true)
    $animation.stop()
    
    _add_to_gate_group()

func _physics_process(delta):
    # TODO: Does this work well?
    #$animation.playback_speed = time_warp.time_scale
    pass

func _input(event):
#    if OS.is_debug_build() and event is InputEventKey and event.is_action_pressed("debug"):
#        toggle()
    pass

func _anim_name(anim):
    if nodust:
        return anim + "_nodust"
    return anim

func open():
    if !is_open and !is_latched:
        _queue_anim(_anim_name("open"))
        is_open = true
        if is_latchable:
            is_latched = true

func close():
    if is_open and !is_latched:
        _queue_anim(_anim_name("close"))
        is_open = false
        if is_latchable:
            is_latched = true

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
