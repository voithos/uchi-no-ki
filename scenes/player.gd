extends KinematicBody2D
class_name Player

var velocity = Vector2.ZERO

const HORIZONTAL_VEL = 80.0
const HORIZONTAL_ACCEL = 20 # How quickly we accelerate to max speed
const GRAVITY = 6.0
const JUMP_VEL = 160
const TERM_VEL = JUMP_VEL * 2
const FAST_FALL_MULTIPLIER = 1.7 # How much faster fast fall is compared to gravity

const JUMP_RELEASE_MULTIPLIER = 0.5 # Multiplied by velocity if button released

var facing_left = true
var is_moving = false
var is_airborne = false
var is_fast_falling = false

func _ready():
    pass

func _physics_process(delta):
    var target_horizontal = 0
    is_moving = false
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

    var fall_multiplier = 1.0
    if is_fast_falling:
        fall_multiplier = FAST_FALL_MULTIPLIER

    velocity.y = min(TERM_VEL, velocity.y + GRAVITY * fall_multiplier)

    # Lerp horizontal movement
    velocity.x = lerp(velocity.x, target_horizontal, HORIZONTAL_ACCEL * delta)

    velocity = move_and_slide(velocity, Vector2.UP)

    _update_sprite_flip()

func _jump():
    is_airborne = true
    is_fast_falling = false
    velocity.y = -JUMP_VEL
    
func _update_sprite_flip():
    $sprite.flip_h = not facing_left
