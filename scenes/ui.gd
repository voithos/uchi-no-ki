extends CanvasLayer

var mana_percent = 100

func _ready():
    $mana.value = mana_percent
    call_deferred("setup_listeners")

func setup_listeners():
    var players = get_tree().get_nodes_in_group("player")
    assert(len(players) == 1)
    var player = players[0]
    player.connect("mana_changed", self, "on_mana_changed")

func on_mana_changed(ratio):
    mana_percent = ratio * 100
    
func _process(delta):
    # Lerp to the target mana
    $mana.value = lerp($mana.value, mana_percent, 0.4)
