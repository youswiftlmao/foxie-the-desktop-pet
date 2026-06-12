extends Node2D

var movespeed = 3
var direction = Vector2(1, 0) 

#behavior vars 

var current_state = State.MOVE
var state_timer := 0.0
enum State {
	MOVE,
	IDLE,
	LOOK,
	POUNCE,
	SCARED,
	SLEEP
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#more behavior code
	change_state(State.MOVE)
	state_timer = randf_range(3, 6)
	
	
	#to acces the os window not js the godot one 
	var window = get_window()
	# transparency set up
	
	get_viewport().transparent_bg = true
	window.transparent = true
	
	#window shape
	window.borderless = true
	
	#keep pet above everything
	window.always_on_top = true
	
	#to override windows resizing border
	window.unresizable = false
	# find floor
	var usable_rect = DisplayServer.screen_get_usable_rect()
	var targety = usable_rect.end.y - window.size.y
	window.position = Vector2i(0, targety)
	#above code helps pet sit ontop the taskbar for a better 
	#experience dont use translucent tb and secondly dont hide 
	#taskbar so its more visually appealing
	
	updmousemask()
	
	$AnimatedSprite2D.frame_changed.connect(updmousemask)

	

	
func _process(delta: float) -> void:
	state_timer -= delta
	
	if state_timer > 0:
		return
		
	_on_state_timer_end()
func _physics_process(delta):

	var window = get_window()
	if current_state == State.MOVE:
		var move_vector = Vector2i(direction * movespeed)
		window.position += move_vector
	
	#the zone or safezone where it interacts at lmao
	var usable_rect = DisplayServer.screen_get_usable_rect()
	
	#right edge detection
	if window.position.x + window.size.x > usable_rect.end.x:
		direction.x = -1
		$AnimatedSprite2D.flip_h = true
		updmousemask()
	#left edge detection
	elif window.position.x < usable_rect.position.x:
		direction.x = 1 
		$AnimatedSprite2D.flip_h = false
		updmousemask()
		
func updmousemask():
	var anim = $AnimatedSprite2D
	
	var texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	var image = texture.get_image()

	if anim.flip_h:
		image.flip_x()
		
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()), 0.1)

	DisplayServer.window_set_mouse_passthrough(polygons)


#behavioral funcs YAYYAYAYYA
func change_state(new_state):
	current_state = new_state
	
	match current_state:
		State.MOVE:
			$AnimatedSprite2D.play("move")
		State.IDLE:
			$AnimatedSprite2D.play("idle")
		State.LOOK:
			$AnimatedSprite2D.play("look back and forth")
		State.POUNCE:
			$AnimatedSprite2D.play("pounce")
		State.SCARED:
			$AnimatedSprite2D.play("scare")
		State.SLEEP:
			$AnimatedSprite2D.play("sleep")
			


func _on_state_timer_end():
	var r = randf()

	if current_state == State.MOVE:
		if r < 0.6:
			change_state(State.IDLE)
			state_timer = randf_range(2, 5)
		elif r < 0.85:
			change_state(State.LOOK)
			state_timer = randf_range(2, 4)
		else:
			change_state(State.SLEEP)
			state_timer = randf_range(5, 10)

	elif current_state == State.IDLE:
		if r < 0.5:
			change_state(State.MOVE)
			state_timer = randf_range(2, 4)
		else:
			change_state(State.LOOK)
			state_timer = randf_range(2, 4)

	elif current_state == State.LOOK:
		if r < 0.5:
			change_state(State.IDLE)
			state_timer = randf_range(2, 4)
		else:
			change_state(State.MOVE)
			state_timer = randf_range(2, 5)

	elif current_state == State.SLEEP:
		if r < 0.7:
			change_state(State.MOVE)
			state_timer = randf_range(3, 6)
		else:
			change_state(State.SLEEP)
			state_timer = randf_range(5, 10)


func _on_animated_sprite_2d_animation_finished() -> void:

	match current_state:

		State.LOOK:
			change_state(State.MOVE)

		State.POUNCE:
			change_state(State.MOVE)

		State.SCARED:
			change_state(State.MOVE)
