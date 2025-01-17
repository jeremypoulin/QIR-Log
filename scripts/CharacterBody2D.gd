extends CharacterBody2D

var character_started = false
var ai_started = false
var direction_type = 0
var rising = true
var throw_counter = 0
var stun_counter = 0
var stunned = false
var grabbed = false
var grab_counter = 0
var throwing = true
var no_collisions = 0
var speed = 400
var outgoing_force = speed * 0.1
var lunge_counter = 0.0
var lunge_duration = 0.0
var lunging = false
var collision_counter = 0
var spacer = 0
var direction = Vector2.ZERO
var other_direction = Vector2.ZERO
@onready var puck = get_parent().get_node("Puck")
@onready var timer = get_parent().get_node("Puck/Timer")
@onready var timeout = get_parent().get_node("Puck/Timeout")
@onready var puck_sprite = get_parent().get_node("Puck/Sprite2D")
@onready var control = get_parent().get_node("Control")
@onready var lunge_bar = get_parent().get_node("Control/LungeBar")
@onready var throw_bar = get_parent().get_node("Control/ThrowBar")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var casper2 = get_parent().get_node("Area2D")
@onready var casper3 = get_parent().get_node("Area2D2")


func _physics_process(delta):
	if(puck.global_position.y > 600 && !character_started):
		ai_started = false
		Global.side_ai = false
		timeout.start()
		character_started = true
			
	if(puck.global_position.y < 600 && !ai_started):
		character_started = false
		Global.side_ai = true
		timeout.start()
		ai_started = true
	#display lunge bar
	lunge_bar.value = lunge_counter
	#display throw bar
	throw_bar.value = throw_counter
	#get velocity vector and convert to unit vector
	if(lunging == false):
		direction = Vector2(int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")), int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")))
		if(direction != Vector2.ZERO):
			direction_type = 0
			other_direction = direction
			direction = direction.normalized()
		else:
			animated_sprite.play("idle")
		
	if(direction.x > 0 && direction.y == 0):
		direction_type = 1
		animated_sprite.play("right")
	if(direction.x < 0 && direction.y == 0):
		direction_type = 2
		animated_sprite.play("left")
	if(direction.y > 0 && direction.x == 0):
		direction_type = 3
		animated_sprite.play("down")
	if(direction.y < 0 && direction.x == 0):
		direction_type = 4
		animated_sprite.play("up")
	if(direction.x > 0 && direction.y > 0):
		direction_type = 5
		animated_sprite.play("down")
	if(direction.x > 0 && direction.y < 0):
		direction_type = 6
		animated_sprite.play("up")
	if(direction.x < 0 && direction.y > 0):
		direction_type = 7
		animated_sprite.play("down")
	if(direction.x < 0 && direction.y < 0):
		direction_type = 8
		animated_sprite.play("up")
	#lunge cooldown counter
	if(Input.is_action_pressed("ui_lunge") == false && lunge_counter < 100.0):
		lunge_counter += 1.0
	#while(Input.is_action_pressed("ui_lunge") == true && lunge_counter > 0):
		#lunge_counter -= 1
		
	#lunge mechanic
	if(Input.is_action_pressed("ui_lunge") == true && lunge_counter == 100.0 || lunge_duration > 0.0):
		print("lunging")
		if(lunging == false):
			lunge_duration = 10.0
		lunging = true
		lunge_counter = 0.0
		lunge_bar.value = lunge_bar.min_value
		speed = 1200
		if(lunge_duration > 0.0):
			lunge_duration -= 1.0
			if(lunge_duration == 0.0):
				lunging = false
				
	else:
		speed = 400
	#normal movement
	if(!grabbed && !stunned):
		velocity = direction * speed
		move_and_slide()
	if(!grabbed && grab_counter > 0):
		grab_counter -= 1
		$AnimatedSprite2D.self_modulate = Color(0, 0, 1)
		if(grab_counter == 0):
			$AnimatedSprite2D.self_modulate = Color(1, 1, 1)
			
	#throw collision disabling
	if(throwing):
		no_collisions -= 1
		if(no_collisions <= 0):
			puck.set_collision_mask_value(4, true)
			set_collision_mask_value(3, true)
			throwing = false
			no_collisions = 0

	#collision cooldown counter
	if(collision_counter > 0):
		collision_counter -= 1
		
	if(abs(puck.linear_velocity.length()) > abs(speed) * 3/4 && puck.linear_velocity.length() > 300 || velocity == Vector2.ZERO && puck.linear_velocity.length() >= 300):
		puck_sprite.self_modulate = Color(1, 0, 0)
	else:
		puck_sprite.self_modulate = Color(1, 1 , 1)
	#collision
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if(collision.get_collider() is RigidBody2D && collision_counter == 0 && no_collisions <= 0):
			collision_counter = 50
			if(lunging):
				collision.get_collider().apply_central_impulse(-collision.get_normal() * (outgoing_force * 3))
			else:
				collision.get_collider().apply_central_impulse(-collision.get_normal() * outgoing_force)
			if(abs(puck.linear_velocity.length()) > abs(speed) * 3/4 && puck.linear_velocity.length() > 300 || velocity == Vector2.ZERO && puck.linear_velocity.length() >= 300):
				stunned = true
				stun_counter = 50
				velocity = Vector2.ZERO
	
	#set throw bar location
	throw_bar.position.x = position.x - 65
	throw_bar.position.y = position.y + 25
			
	if(stunned && stun_counter > 0):
		stun_counter -= 1
		if(stun_counter <= 0):
			stunned = false
	if(grabbed):
		spacer -= 1
		$Arrow.visible = true
		throw_bar.visible = true
		print("GRABBED")
		if(rising == true):
			throw_counter += 2
			if(throw_counter >= 50):
				rising = false
		if(rising == false):
			throw_counter -= 2
			if(throw_counter <= 0):
				rising = true
				_throw()
		if(direction_type == 0 || direction_type == 4):
			$Arrow.position.y = -100
			$Arrow.position.x = 0
			$Arrow.rotation_degrees = 0
		if(direction_type == 1):
			$Arrow.position.y = 0
			$Arrow.position.x = 100
			$Arrow.rotation_degrees = 90
		if(direction_type == 2):
			$Arrow.position.y = 0
			$Arrow.position.x = -100
			$Arrow.rotation_degrees = -90
		if(direction_type == 3):
			$Arrow.position.y = 100
			$Arrow.position.x = 0
			$Arrow.rotation_degrees = 180
		if(direction_type == 5):
			$Arrow.position.y = 100
			$Arrow.position.x = 100
			$Arrow.rotation_degrees = 135
		if(direction_type == 6):
			$Arrow.position.y = -100
			$Arrow.position.x = 100
			$Arrow.rotation_degrees = 45
		if(direction_type == 7):
			$Arrow.position.y = 100
			$Arrow.position.x = -100
			$Arrow.rotation_degrees = -135
		if(direction_type == 8):
			$Arrow.position.y = -100
			$Arrow.position.x = -100
			$Arrow.rotation_degrees = -45
			
	
	if(!puck.complete && Input.is_action_pressed("ui_grab") && grab_counter == 0):
		_grab()
				
	if(puck.complete && Input.is_action_just_pressed("ui_grab")):
		_throw()
		
		
func _grab():
	if(puck.in_range && !puck.complete && Input.is_action_pressed("ui_grab") && !stunned):
		spacer = 3
		puck.complete = true
		print("grab!")
		puck.linear_velocity = Vector2.ZERO
		grabbed = true
		puck.freeze = true
		puck.scale.x = 0.5
		puck.scale.y = 0.5
		puck.global_position = global_position
		
func _throw():
	if(spacer <= 0):
		spacer = 0
		$Arrow.visible = false
		throw_bar.visible = false
		puck.complete = false
		grabbed = false
		puck.freeze = false
		grab_counter = 50
		throwing = true
		no_collisions = 50
		puck.set_collision_mask_value(4, false)
		set_collision_mask_value(3, false)
		puck.scale.x = 1
		puck.scale.y = 1
		if(direction == Vector2.ZERO):
			puck.linear_velocity = (speed + (25 * throw_counter)) * Vector2.UP
		else:
			puck.linear_velocity = (speed + (25 * throw_counter)) * direction
		throw_counter = 0
		puck.global_position.x = global_position.x
		puck.global_position.y = global_position.y


func _on_timeout_timeout():
	if(Global.side_ai == false):
		print("P2 Scored")
		Global.bot_score += 1
		control._update_bot_score()
		if(Global.bot_score >= 7):
			Global.user_score = 0
			Global.bot_score = 0
			Global.top_player_win = true
			get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
		else:
			timer.start()
	else:
		print("P1 Scored")
		Global.user_score += 1
		control._update_user_score()
		if(Global.user_score >= 7):
			Global.user_score = 0
			Global.bot_score = 0
			Global.bottom_player_win = true
			get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
		else:
			timer.start()
