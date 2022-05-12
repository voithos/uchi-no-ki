extends Node2D

const TOTAL_SCROLLS = 24

func _ready():
    # Load the game state once per level.
    saving.load_game()
    $canvas/skull/label.text = str(death_counter.total_deaths())
    $canvas/scroll/label.text = str(scroll_store.total_scrolls()) + " / " + str(TOTAL_SCROLLS)
