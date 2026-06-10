extends Node2D

var movespeed = 3
var direction = Vector2(1, 0) 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
func _physics_process(delta: float) -> void:
	var window = get_window()
	var move_vector = Vector2i(direction * movespeed)
	window.position += move_vector
	
	#the zone or safezone where it interacts at lmao
	var usable_rect = DisplayServer.screen_get_usable_rect()
	
	#right edge detection
	if window.position.x + window.size.x > usable_rect.end.x:
		direction.x = -1
		$AnimatedSprite2D.flip_h = true
	#left edge detection
	elif window.position.x < usable_rect.position.x:
		direction.x = 1 
		$AnimatedSprite2D.flip_h = false
		
