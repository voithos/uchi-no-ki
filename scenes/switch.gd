extends Sprite

export var is_on = false
# Whether or not you can "undo" the toggle
export var is_toggleable = false

onready var gate_group = $".."

func _ready():
    add_to_group("switches")
    $animation.play("switch")
    if is_on:
        $animation.seek(0.5, true)
    else:
        $animation.seek(0, true)
    $animation.stop()
    
    _add_to_gate_group()

func _input(event):
    if OS.is_debug_build() and event is InputEventKey and event.is_action_pressed("debug"):
        toggle()

func open():
    if !is_on:
        $animation.play("switch")
        is_on = true
        
func close():
    if is_on:
        $animation.play_backwards("switch")
        is_on = false

func toggle():
    if is_on and !is_toggleable:
        return

    if is_on:
        close()
    else:
        open()

    gate_group.on_switch_toggle()

func _on_area_body_entered(body):
    toggle()

func _add_to_gate_group():
    gate_group.add_switch(self)
