extends Sprite

var is_on = false

onready var gate_group = $".."

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
    gate_group.on_switch_toggle()
        
func close():
    if is_on:
        $animation.play_backwards("switch")
        is_on = false
    gate_group.on_switch_toggle()

func _on_area_body_entered(body):
    open()

func _on_area_body_exited(body):
    close()

func _add_to_gate_group():
    gate_group.add_switch(self)
