extends CanvasLayer

func _ready():
    call_deferred("setup_listeners")

func setup_listeners():
    var players = get_tree().get_nodes_in_group("player")
    assert(len(players) == 1)
    var player = players[0]
    player.connect("mana_changed", self, "on_mana_changed")

func on_mana_changed(ratio):
    $mana.value = ratio * 100

func process(delta):
    pass
