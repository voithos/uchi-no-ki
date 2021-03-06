extends Sprite

export var is_on = false
# Whether or not you can "undo" the toggle. Timed switches should not be toggleable.
export var is_toggleable = false
# Whether or not the switch is timed
export var is_timed = false
export (float) var timeout = 0

# Necessary switches must all be true in order to open a gate.
# Sufficient switches open the gate all by themselves.
# A switch that is unnecessary, but sufficient, can act as a "reset" for a locked gate.
export (bool) var is_necessary = true
export (bool) var is_sufficient = false

# If true, this forces all gates open/closed, instead of just toggling them from default state.
export (bool) var force_open = false
export (bool) var force_close = false

onready var gate_group = $".."

func _ready():
    assert(!(is_toggleable && is_timed))

    add_to_group("switches")
    # Rotate the timer so that it's always upright.
    $switch_timer.rect_rotation = rotation_degrees
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
        sfx.play_with_player($audio, sfx.SWITCH, sfx.QUIET_DB)

        if is_timed:
            $switch_timer.timeout = timeout
            $switch_timer.start_timer()
            yield($switch_timer, "timeout")
            close()
            
func close():
    if is_on:
        $animation.play_backwards("switch")
        is_on = false
        gate_group.on_switch_toggle()
        sfx.play_with_player($audio, sfx.SWITCH, sfx.QUIET_DB)

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
