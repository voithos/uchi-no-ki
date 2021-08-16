extends Node

# Store for storing number of deaths per level, and totally.

# Note, level names must be unique!
var levels = {}

func _ready():
    add_to_group("persistable")

func deaths_in_level(level_id) -> int:
    if !levels.has(level_id):
        return 0
    return levels[level_id]

func total_deaths() -> int:
    var deaths = 0
    for level in levels.keys():
        deaths += deaths_in_level(level)
    return deaths

func die():
    # Can only die in current level, naturally
    var level = _level_name()
    if !levels.has(level):
        levels[level] = 0
    levels[level] += 1
    # Persist the data.
    saving.save_game()

func _level_name():
    return get_tree().get_current_scene().get_name()

func save_state():
    return levels

func load_state(save_data):
    levels = save_data
