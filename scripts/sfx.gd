extends Node

# Centralized SFX management.

const SFX_DB = -8.0
const QUIET_DB = -16.0

enum {
    WALK,
}

const SAMPLES = {
    WALK: preload("res://assets/sfx/walk.wav"),
}

const POOL_SIZE = 8
var pool = []
# Index of the current audio player in the pool.
var next_player = 0

func _ready():
    _init_stream_players()

func _init_stream_players():
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
