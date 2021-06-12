extends KinematicBody2D
class_name Player

var velocity = Vector2.ZERO
var shade_velocity = Vector2.ZERO

const HORIZONTAL_VEL = 80.0
const HORIZONTAL_ACCEL = 20 # How quickly we accelerate to max speed

const SHADE_HORIZONTAL_VEL = 50.0
const SHADE_HORIZONTAL_ACCEL = 40
const SHADE_VERTICAL_VEL = 50.0
const SHADE_VERTICAL_ACCEL = 40

const GRAVITY = 6.0
const JUMP_VEL = 160
const TERM_VEL = JUMP_VEL * 2
const FAST_FALL_MULTIPLIER = 1.7 # How much faster fast fall is compared to gravity

const JUMP_RELEASE_MULTIPLIER = 0.5 # Multiplied by velocity if button released

const MAX_MANA = 100.0
var mana = MAX_MANA
const MANA_DEPLETION = 50 # Rate of depletion
const MANA_GAIN = 40 # Rate of gain when not in shade
# TODO: Add distance factor? Or maybe elasticity?
signal mana_changed

var facing_left = true
var is_moving = false
var is_shade_moving = false
var is_airborne = false
var is_fast_falling = false
var is_shade_out = false

var is_controllable = true

const WALK_SFX_COOLDOWN = 0.3 # seconds
var walk_sfx_cooldown = 0

onready var camera = $shade/player_camera

func _ready():
    add_to_group("player")
    $shade.hide()
    $shade.position = Vector2.ZERO
    $shade/shape.disabled = true
    pass

func _physics_process(delta):
    if !is_controllable:
        return

    if Input.is_action_just_pressed("ki_burst"):
        _toggle_shade()

    if is_shade_out:
        _move_shade(delta)
    _move_player(delta)

    _update_mana(delta)
    
    _update_sprite_flip()
    _walk_sfx(delta)

func _toggle_shade():
    is_shade_out = !is_shade_out
    if is_shade_out:
        $shade.show()
        $shade/shape.disabled = false
    else:
        $shade.hide()
        $shade/shape.disabled = true
    $shade.position = Vector2.ZERO

func _move_player(delta):
    var target_horizontal = 0
    var fall_multiplier = 1.0
    is_moving = false

    if !is_shade_out:
        if Input.is_action_pressed("move_left"):
            target_horizontal -= HORIZONTAL_VEL
            is_moving = true
        if Input.is_action_pressed("move_right"):
            target_horizontal += HORIZONTAL_VEL
            is_moving = true

        if Input.is_action_just_pressed("move_up") and is_on_floor():
            _jump()
        
        if target_horizontal != 0:
            facing_left = target_horizontal < 0

        # Apply gravity and fast falling
        if is_airborne and Input.is_action_just_released("move_up"):
            is_fast_falling = true
            if velocity.y < 0:
                velocity.y *= JUMP_RELEASE_MULTIPLIER

        if is_fast_falling:
            fall_multiplier = FAST_FALL_MULTIPLIER

    velocity.y = min(TERM_VEL, velocity.y + GRAVITY * fall_multiplier)

    # Lerp horizontal movement
    velocity.x = lerp(velocity.x, target_horizontal, HORIZONTAL_ACCEL * delta)

    # Handle shade being out
    var shade_pos = $shade.global_position
    velocity = move_and_slide(velocity, Vector2.UP)
    if is_shade_out:
        $shade.global_position = shade_pos

func _move_shade(delta):
    var target_horizontal = 0
    var target_vertical = 0
    is_shade_moving = false
    if Input.is_action_pressed("move_left"):
        target_horizontal -= SHADE_HORIZONTAL_VEL
        is_shade_moving = true
    if Input.is_action_pressed("move_right"):
        target_horizontal += SHADE_HORIZONTAL_VEL
        is_shade_moving = true

    if Input.is_action_pressed("move_up"):
        target_vertical -= SHADE_VERTICAL_VEL
    if Input.is_action_pressed("move_down"):
        target_vertical += SHADE_VERTICAL_VEL
    
    if target_horizontal != 0:
        facing_left = target_horizontal < 0

    # No gravity for shade
    shade_velocity.x = lerp(shade_velocity.x, target_horizontal, SHADE_HORIZONTAL_ACCEL * delta)
    shade_velocity.y = lerp(shade_velocity.y, target_vertical, SHADE_VERTICAL_ACCEL * delta)

    shade_velocity = $shade.move_and_slide(shade_velocity, Vector2.UP)

func _jump():
    is_airborne = true
    is_fast_falling = false
    velocity.y = -JUMP_VEL
    
func _update_mana(delta):
    if is_shade_out:
        mana = max(0, mana - MANA_DEPLETION * delta)
        if mana == 0:
            _toggle_shade()
    else:
        mana = min(MAX_MANA, mana + MANA_GAIN * delta)
    emit_signal("mana_changed", mana / MAX_MANA)

func _update_sprite_flip():
    if is_shade_out:
        $shade/sprite.flip_h = not facing_left
    else:
        $sprite.flip_h = not facing_left

func _walk_sfx(delta):
    if !is_on_floor() or !is_moving:
        walk_sfx_cooldown = 0
        return

    if walk_sfx_cooldown <= 0:
        sfx.play(sfx.WALK, sfx.QUIET_DB)
        walk_sfx_cooldown = WALK_SFX_COOLDOWN
    if walk_sfx_cooldown > 0:
        walk_sfx_cooldown -= delta


func _on_hurtbox_area_entered(area):
    pass # Actually uses the body

func _on_hurtbox_body_entered(body):
    die()

func die():
    is_controllable = false
    # TODO: Add death animation and transition
    
