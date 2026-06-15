extends Node2D

var movespeed = 3
var direction = Vector2(1, 0) 

#behavior vars 
@onready var stats_window = $statslayer/CanvasLayer/StatsWindow



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

var hunger := 100.00
#so its easier to work with rather then 0
var happy := 100.00
var energy := 100.00

#statvars
@onready var hungerbar = $hungerbar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updhungerbar()

	
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
	if stats_window.visible:
		var fox_window = get_window()
		
		stats_window.position = Vector2i(
			fox_window.position.x,
			fox_window.position.y - stats_window.size.y - 10
		)
	
	
	
	state_timer -= delta
	
	if state_timer > 0:
		return
		
	_on_state_timer_end()
	
	
	#for slower sped while low enegry or like low hunger
	$AnimatedSprite2D.speed_scale = clamp(energy / 100.0, 0.4, 1.0)
	
	if hunger <=0 :
		hunger = 0
	if happy <=0 :
		happy = 0
	if energy <=0 :
		energy = 0
		
		
		

func _physics_process(delta):
	
	var window = get_window()
	if current_state == State.MOVE:
		var move_vector = Vector2i(direction * getspeed())
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

	print(polygons.size())
	
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

	var sleepchance = 0.05

	if energy < 30 :
		sleepchance += 0.25
	if energy < 15 :
		sleepchance += 0.35
		
	if r < sleepchance:
		change_state(State.SLEEP)
		state_timer = randf_range(15,25)
		
	elif r < 0.6:
		change_state(State.IDLE)
		state_timer = randf_range(2 , 5)
	elif r < 0.85:
		change_state(State.LOOK)
		state_timer = randf_range(2 , 4)
	else:
		change_state(State.MOVE)
		state_timer = randf_range(2,5)


func _on_animated_sprite_2d_animation_finished() -> void:

	match current_state:

		State.LOOK:
			change_state(State.MOVE)

		State.POUNCE:
			change_state(State.MOVE)

		State.SCARED:
			change_state(State.MOVE)


func _on_body_area_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		
		stats_window.visible = !stats_window.visible
		
		change_state(State.IDLE)
		state_timer = 5


func _on_scarearea_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		change_state(State.SCARED)
		happy -= 10


func _on_pet_stat_timer_timeout() -> void:
	hunger  -= 0.3

	happy -= 0.2
	
	if current_state == State.SLEEP:
		energy += 2
	else:
		energy -= 0.3
	print( "happy", happy)
	print("energy", energy)
	print("hunger", hunger)
	if current_state == State.SLEEP and energy >90:
		change_state(State.MOVE)
		state_timer = randf_range( 2 , 5)
	hunger = clamp(hunger, 0, 100)
	energy = clamp(energy, 0, 100)
	happy = clamp(happy, 0, 100)
	updhungerbar()
func getspeed():
	var speed = movespeed
	
	if energy < 50:
		speed *= 0.7
	if energy < 25 :
		speed*= 0.4
		
	if hunger < 50:
		speed *= 0.8
	if hunger <20:
		speed *= 0.5
		
	return speed
		

func updhungerbar():
	hungerbar.value = hunger

	var t = 1.0 - (hunger / 100.0) # 0 = full, 1 = empty

	var white = Color(1, 1, 1)
	var yellow = Color(1, 1, 0)
	var orange = Color(1, 0.5, 0)
	var red = Color(1, 0, 0)

	var c: Color

	if t < 0.33:
		c = white.lerp(yellow, t / 0.33)
	elif t < 0.66:
		c = yellow.lerp(orange, (t - 0.33) / 0.33)
	else:
		c = orange.lerp(red, (t - 0.66) / 0.34)

	var fill = hungerbar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = c
	hungerbar.add_theme_stylebox_override("fill", fill)
