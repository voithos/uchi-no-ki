extends Node

# Centralized SFX management.

const SFX_DB = -8.0
const QUIET_DB = -12.0
const EXTRA_QUIET_DB = -20.0
const EVEN_QUIETER_DB = -25.0

enum {
    WALK,
    GOAL,
    DEATH,
    JUMP,
    SHADE,
    SHADE_RETURN,
    TELEPORT,
    BUTTON,
    SWITCH,
    CHECKPOINT,
    ORB_SHATTER,
    SHADE_DASH,
}

const SAMPLES = {
    WALK: preload("res://assets/sfx/walk.wav"),
    GOAL: preload("res://assets/sfx/goal.wav"),
    DEATH: preload("res://assets/sfx/death.wav"),
    JUMP: preload("res://assets/sfx/jump.wav"),
    SHADE: preload("res://assets/sfx/shade.wav"),
    SHADE_RETURN: preload("res://assets/sfx/shade_return.wav"),
    TELEPORT: preload("res://assets/sfx/teleport.wav"),
    BUTTON: preload("res://assets/sfx/switch.wav"), # The switch sound is better
    SWITCH: preload("res://assets/sfx/switch.wav"),
    CHECKPOINT: preload("res://assets/sfx/checkpoint.wav"),
    ORB_SHATTER: preload("res://assets/sfx/shatter.wav"),
    SHADE_DASH: preload("res://assets/sfx/shade_dash.wav"),
}

const POOL_SIZE = 8
var pool = []
# Index of the current audio player in the pool.
var next_player = 0

func _ready():
    _init_stream_players()

func _init_stream_players():
    # warning-ignore:unused_variable
    for i in range(POOL_SIZE):
        var player = AudioStreamPlayer.new()
        add_child(player)
        pool.append(player)

func _get_next_player_idx():
    var next = next_player
    next_player = (next_player + 1) % POOL_SIZE
    return next

func play(sample, db=SFX_DB):
    assert(sample in SAMPLES)
    var stream = SAMPLES[sample]
    var idx = _get_next_player_idx()

    var player = pool[idx]
    player.stream = stream
    player.volume_db = db
    player.play()
