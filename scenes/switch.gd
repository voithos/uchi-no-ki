extends Sprite

export var is_on = false
# Whether or not you can "undo" the toggle
export var is_toggleable = false
# Whether or not the switch is timed
export var is_timed = false
export (float) var timeout = 0

# Necessary switches must all be true in order to open a gate.
# Sufficient switches open the gate all by themselves.
# A switch that is unnecessary, but sufficient, can act as a "reset" for a locked gate.
export (bool) var is_necessary = true
export (bool) var is_sufficient = false

onready var gate_group = $".."

func _ready():
    add_to_group("switches")
    if is_timed:
        assert(timeout != 0)
        texture = preload("res://assets/props/timed_switch.png")
    else:
        texture = preload("res://assets/props/switch.png")
    
    $animation.play("switch")
    if is_on:
        $animation.seek(0.5, true)
    else:
        $animation.seek(0, true)
    $animation.stop()
    
    _add_to_gate_group()

func open():
    if !is_on:
        $animation.play("switch")
        is_on = true
        gate_group.on_switch_toggle()

        if is_timed:
            $timer.wait_time = timeout
            $timer.one_shot = true
            $timer.start()
            yield($timer, "timeout")
            close()
            
func close():
    if is_on:
        $animation.play_backwards("switch")
        is_on = false
        gate_group.on_switch_toggle()

func toggle():
    if is_on and !is_toggleable:
        return

    if is_on:
        close()
    else:
        open()

func _on_area_body_entered(body):
    toggle()

func _add_to_gate_group():
    gate_group.add_switch(self)
