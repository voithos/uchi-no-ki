extends Sprite

# Necessary switches must all be true in order to open a gate.
# Sufficient switches open the gate all by themselves.
# A switch that is unnecessary, but sufficient, can act as a "reset" for a locked gate.
export (bool) var is_necessary = true
export (bool) var is_sufficient = false
var is_on = false

onready var gate_group = $".."
var body_count = 0

func _ready():
    add_to_group("switches")
    $animation.play("switch")
    $animation.seek(0, true)
    $animation.stop()
    
    _add_to_gate_group()

func open():
    if !is_on:
        $animation.play("switch")
        is_on = true
        sfx.play(sfx.BUTTON, sfx.QUIET_DB)
    gate_group.on_switch_toggle()

func close():
    if is_on:
        $animation.play_backwards("switch")
        is_on = false
    gate_group.on_switch_toggle()

func _on_area_body_entered(body):
    body_count += 1
    if body_count > 0:
        open()

func _on_area_body_exited(body):
    body_count -= 1
    if body_count <= 0:
        close()

func _add_to_gate_group():
    gate_group.add_switch(self)
