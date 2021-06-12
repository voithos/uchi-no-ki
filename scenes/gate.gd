extends Sprite

export var is_open = false

func _ready():
    add_to_group("gates")
    $animation.play("open")
    if is_open:
        $animation.seek(2.0, true)
    else:
        $animation.seek(0, true)
    $animation.stop()
    
    _add_to_gate_group()

func _input(event):
#    if OS.is_debug_build() and event is InputEventKey and event.is_action_pressed("debug"):
#        toggle()
    pass

func open():
    if !is_open:
        $animation.play("open")
        is_open = true

func close():
    if is_open:
        # TODO: Replace this with a proper close animation
        $animation.play_backwards("open")
        is_open = false

func toggle():
    if is_open:
        close()
    else:
        open()

func _add_to_gate_group():
    $"..".add_gate(self)
