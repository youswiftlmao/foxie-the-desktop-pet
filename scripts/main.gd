extends Node2D

var movespeed = 3
var direction = Vector2(1, 0) 
@onready var food_window = $"food window"
#behavior vars 
@onready var stats_window = $statslayer/CanvasLayer/StatsWindow
#feeding vars ig im hungry
var food = [
	{"name": "apple","hunger": 10},
	{"name": "meat","hunger": 25},
	{"name": "egg","hunger": 15},
	{"name": "fish","hunger": 15},
	{"name": "cake","hunger": 10},
 ]

var currentfood = {}

var holding_food := false

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
@onready var hungerbar = $statslayer/CanvasLayer/StatsWindow/hungerbar
@onready var happybar = $statslayer/CanvasLayer/StatsWindow/Happybar
@onready var sleepybar = $statslayer/CanvasLayer/StatsWindow/sleepybar

var petting = false
var petingtimer = 0.0
var pettingmode = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	updui()

	
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
	


	

	
func _process(delta: float) -> void:
	

	if petting and pettingmode:
		var mousevel = Input.get_last_mouse_screen_velocity()

		if mousevel.length() > 20:
			happy = clamp(happy + 0.1, 0, 100)
			print("happy")
	if pettingmode:
		petingtimer -= delta

		if petingtimer <= 0:
			pettingmode = false
			petting = false
			print("petting session END")

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
		
	if food_window.holding:
		var mouth_pos = Vector2(get_window().position) + $AnimatedSprite2D/moutharea.global_position
		var food_pos = Vector2(food_window.position) + Vector2(food_window.size) / 2.0
		if mouth_pos.distance_to(food_pos) < 100:
			eat_food(food_window)
		#feeding is sm easier now omfddddddddds

func _physics_process(delta):
	if petting:
		return
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
		$"AnimatedSprite2D/body area/CollisionShape2D".position.x = 112
		$AnimatedSprite2D/scarearea/CollisionShape2D.position.x = -8.697
		$AnimatedSprite2D/scarearea/CollisionShape2D2.position.x = 3.999
		$AnimatedSprite2D/scarearea/CollisionShape2D3.position.x = -1.999
		$AnimatedSprite2D/scarearea/CollisionShape2D5.position.x = 1.5
		$AnimatedSprite2D/scarearea/CollisionShape2D4.position.x = -6.005
		$"AnimatedSprite2D/petting area/CollisionShape2D".position.x = 142
		$AnimatedSprite2D/moutharea.position.x = -12.196
		$"AnimatedSprite2D/petting area/CollisionShape2D2".position.x = 100
		$"AnimatedSprite2D/petting area/CollisionShape2D3".position.x = 56
		updmousemask()
	#left edge detection
	elif window.position.x < usable_rect.position.x:
		direction.x = 1 
		$AnimatedSprite2D.flip_h = false
		$"AnimatedSprite2D/body area/CollisionShape2D".position.x = 134
		$AnimatedSprite2D/scarearea/CollisionShape2D.position.x = 8.697
		$AnimatedSprite2D/scarearea/CollisionShape2D2.position.x = -3.999
		$AnimatedSprite2D/scarearea/CollisionShape2D3.position.x = 1.999
		$AnimatedSprite2D/scarearea/CollisionShape2D5.position.x = -1.5
		$AnimatedSprite2D/scarearea/CollisionShape2D4.position.x = 6.005
		$AnimatedSprite2D/moutharea.position.x = 6.998
		$"AnimatedSprite2D/petting area/CollisionShape2D".position.x = 117
		$"AnimatedSprite2D/petting area/CollisionShape2D2".position.x = 141.5
		$"AnimatedSprite2D/petting area/CollisionShape2D3".position.x = 184.5
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
		
	if petingtimer > 0:
		change_state(State.IDLE)
		state_timer = 0.2
		return
		
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

	updui()
	
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
		

func updbars(bar , value):
	bar.value = value

	var t = 1.0 - (value / 100.0) # 0 = full, 1 = empty

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

	var fill = bar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = c
	bar.add_theme_stylebox_override("fill", fill)
	
func updui():
	updbars(hungerbar, hunger)
	updbars(happybar, happy)
	updbars(sleepybar, energy)




func pickfood():
	currentfood = food.pick_random()
	food_window.start_food(currentfood)

func _on_hunger_pressed() -> void:
	pickfood()
	
func eat_food(fw):
	hunger += fw.food_data["hunger"]
	hunger = clamp(hunger, 0, 100)

	fw.stop_food()
	updui()


func _on_petting_area_mouse_entered() -> void:
	if pettingmode:
		petting = true
		print("petting is actigve")

func _on_petting_area_mouse_exited() -> void:
	petting = false
	print("MOUSE GONE")

func _on_happy_pressed() -> void:
	pettingmode = true
	petingtimer = 7.0
	print("petting start")
