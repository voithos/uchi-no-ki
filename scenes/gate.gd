extends Sprite

func _ready():
    add_to_group("gates")
    $animation.play("open")
    $animation.seek(0, true)
    $animation.stop()

func _input(event):
    if OS.is_debug_build() and event is InputEventKey and event.is_action_pressed("debug"):
        open()

func open():
    $animation.play("open")
