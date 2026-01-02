extends CharacterBody3D

const GRAVITY = 30.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()
