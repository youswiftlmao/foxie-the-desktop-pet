extends Node2D

var movespeed = 3
var direction = Vector2(1, 0) 

#behavior vars 

var current_state = State.MOVE

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
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	
	
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

	
	change_state(State.MOVE)
func _physics_process(delta):

	if current_state != State.MOVE:
		return

	var window = get_window()
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
			
func _on_animation_finished():

	match current_state:

		State.LOOK:
			change_state(State.MOVE)

		State.POUNCE:
			change_state(State.MOVE)

		State.SCARED:
			change_state(State.MOVE)
