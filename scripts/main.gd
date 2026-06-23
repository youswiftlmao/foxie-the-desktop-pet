extends Node2D

var movespeed = 3
var direction = Vector2(1, 0) 
@onready var food_window = $"food window"
#behavior vars 
@onready var stats_window = $statslayer/CanvasLayer/StatsWindow
#feeding vars ig im hungry
var food = [
	{"name": "apple","hunger": 20},
	{"name": "meat","hunger": 30},
	{"name": "egg","hunger": 20},
	{"name": "fish","hunger": 20},
	{"name": "cake","hunger": 10},
 ]

var currentfood = {}
var ovveridesleep := false
var holding_food := false

var current_state = State.MOVE
var state_timer := 0.0
enum State {
	MOVE,
	IDLE,
	LOOK,
	POUNCE,
	SCARED,
	SLEEP,
	ZOOMIES,
	CHASETOY
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
#more interaction with fox to feel more alive yeah
# making a simple pounce feature if mouse near he will pounce
var pouncing = false
var pouncetrgt = 0
#dragiing the fox
var dragging = false
var falling = false
var fallvelocity = 0.0
#zoomie vars gruhuhrgurhguoahoaghaiuh
var zoomies = false
var zoomietimer = 0.0
const  zoomieduration = 6.0
#making a play area fatch mainly
var toys = [
	{"name":"ball"},
	{"name":"bone"},
	{"name":"feather"}
]
var currenttoy = {}
var toy_active = false
@onready var toy_window = $"toys window"
var toythorwn = false
var carryingtoy = false
var toycaught = false
var toypounced = false
var timerunningstats = false
var returntoy := false
var bobtoyinmouthtimer := 0.0
# Called when the node enters the scene tree for the first time.


var statstimerhide


var achivement = {
	"firstnap": false,
	"slept": false,
	"atefood": false,
	"played": false,
	"hadzoomers": false,
	"gotpinched": false
}



#statiscits panel var like amt of time done (action)
var hoursslept
var foodeaten
var age
var distancetraveled
var timesplayed
var timepicked
var timespetted
var wheight
var phase
var size #starts out small as grows scale sdoes too and kgs yeah


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
	if toyvisible() \
	and toythorwn \
	and !toycaught \
	and !carryingtoy \
	and !returntoy \
	and current_state != State.CHASETOY \
	and !pouncing:
	
		change_state(State.CHASETOY)
		
	if toy_active and !toy_window.visible:
		resettoy()
	if zoomies:
		var window = get_window()

		zoomietimer -= delta
		energy -= 5 * delta

		# move every frame
		window.position += Vector2i(direction * getspeed() * 6)

		if zoomietimer <= 0:
			zoomies = false
			change_state(State.IDLE)
			state_timer = randf_range(2, 5)

		return
	if energy >= 100 and current_state == State.SLEEP:
		change_state(State.MOVE)

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

	if current_state == State.MOVE and mosueinpounce_zone() and !pouncing:
		if randf() < 0.01:
			
			pounce()
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
	
	
	#for slower sped while low enegry or like low hunger if not in zoomiues lol
	if zoomies:
		$AnimatedSprite2D.speed_scale  = 3
	else:
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

	if petting and !pouncing:
		return
	var window = get_window()
		
		
	if current_state == State.CHASETOY and toythorwn and !toycaught:
		if pouncing:
			return
		var toypos = findtoypos()
		var foxpos = getfoxpos()
		
		if toypos.x > foxpos.x:
			direction.x = 1
			$AnimatedSprite2D.flip_h = false
		else:
			direction.x = -1
			$AnimatedSprite2D.flip_h = true
			
		window.position.x += direction.x * 5
		
		var dist = foxpos.distance_to(toypos)
		
		if dist < 200 and !pouncing and !toycaught:
			toycaught = true
			carryingtoy  = true
			returntoy = true
			
			print("punced on toy")
			
			pounce()
		
		
	
		
		
	if carryingtoy :

		toy_window.carried = true
		toy_window.velocity = Vector2.ZERO
		toy_window.position = get_window().position + Vector2i(40, 70 )
		toy_window.grab_focus()
		
		
	if returntoy and !pouncing:
		direction.x =  1
		
		$AnimatedSprite2D.flip_h = false
		change_state(State.MOVE)
		var usablrect = DisplayServer.screen_get_usable_rect()
		
		
		if window.position.x > usablrect.end.x - 300:
			if !achivement["played"]:
				achivement["played"] = true
				$"statslayer/CanvasLayer/StatsWindow/acheviements panel/Done4".visible = true
			droptoy()
			resettoy()
			returntoy = false
			happy = clamp(happy + 10 , 0 , 100)
			change_state(State.IDLE)
			state_timer = randf_range(2, 5)
	if dragging:
		var mouse = DisplayServer.mouse_get_position()
		
		falling = false
		window.position = Vector2i(
			mouse.x - window.size.x / 2,
			mouse.y - 70
		)
		return
	if current_state == State.MOVE and !pouncing:
		window.position += Vector2i(direction * getspeed())
	#pounce stuff
	
	if pouncing:
		print(window.position.x)
		window.position.x = move_toward(
			window.position.x,
			pouncetrgt,
			800*delta
		)
	
		
		if abs(window.position.x - pouncetrgt ) < 1:
			window.position.x  = pouncetrgt
			pouncing = false
	
	

	if falling:
		var usable_rect = DisplayServer.screen_get_usable_rect()
		var targety = usable_rect.end.y - window.size.y
		fallvelocity += 2100*delta
		window.position.y += int(fallvelocity * delta)
		
		if window.position.y >= targety:
			window.position.y = targety
			falling = false
			fallvelocity = 0
			
			change_state(State.MOVE)
			
	#the zone or safezone where it interacts at lmao

	var usable_rect = DisplayServer.screen_get_usable_rect()
	var targety = usable_rect.end.y - window.size.y
		
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
		$AnimatedSprite2D/neckarea/CollisionShape2D.position.x = 0.0
		updmousemask()


	if window.position.x + window.size.x >= usable_rect.end.x:
		direction.x = -1
		
	elif window.position.x <= usable_rect.position.x:
		direction.x = 1
		
		
	$AnimatedSprite2D.flip_h = direction.x < 0
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
		State.ZOOMIES:
			$AnimatedSprite2D.play("move")
		State.CHASETOY:
			$AnimatedSprite2D.play("move")

func _on_state_timer_end():
	if carryingtoy:
		change_state(State.MOVE)
		state_timer = randf_range(2, 5)
		return
		
	if ovveridesleep:
		change_state(State.SLEEP)
		state_timer = 9999
		return
	
	if happy > 80 and energy > 80:
		if randf() < 0.10:
			startzoomies()
			return
	
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
			change_state(State.IDLE)
		State.SCARED:
			change_state(State.MOVE)


func _on_body_area_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and timerunningstats == false:
		showstatswindow()
	



func _on_scarearea_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:

	if event is InputEventMouseButton and event.pressed:
		if  !achivement["gotpinched"]:
			achivement["gotpinced"] = true
			$"statslayer/CanvasLayer/StatsWindow/acheviements panel/Done6".visible = true
		change_state(State.SCARED)
		happy -= 10


func _on_pet_stat_timer_timeout() -> void:
	hunger  -= 0.3

	happy -= 0.2
	
	if current_state == State.SLEEP:
		energy += 1
	else:
		energy -= 0.3
		
	updui()
	print( "happy", happy)
	print("energy", energy)
	print("hunger", hunger)
	if ovveridesleep:
		if energy >=100:
			ovveridesleep = false
			change_state(State.SLEEP)
			state_timer = randf_range(2, 5)
	hunger = clamp(hunger, 0, 100)
	energy = clamp(energy, 0, 100)
	happy = clamp(happy, 0, 100)

	updui()
	
func getspeed():
	var speed = movespeed
	if zoomies:
		return movespeed * 1.5
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
	if !achivement["atefood"]:
		achivement["atefood"] = true
		$"statslayer/CanvasLayer/StatsWindow/acheviements panel/Done3".visible = true
	hunger += fw.food_data["hunger"]
	hunger = clamp(hunger, 0, 100)
	energy += 5

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


func _on_sleep_pressed() -> void:
	if !achivement["firstnap"]:
		achivement["firstnap"] = true
		$"statslayer/CanvasLayer/StatsWindow/acheviements panel/Done2".visible = true
	ovveridesleep = true
	change_state(State.SLEEP)
	state_timer = 9999


func _on_body_area_mouse_entered() -> void:
	if pettingmode:
		petting = true


func _on_body_area_mouse_exited() -> void:

	petting = false


func pounce():
	
	if pouncing :
		return
	pouncing = true
	change_state(State.POUNCE)

	await get_tree().process_frame

	var mouse = DisplayServer.mouse_get_position()
	var window = get_window()
	if $AnimatedSprite2D.flip_h:
		pouncetrgt = window.position.x - 200
	else:
		pouncetrgt = window.position.x + 200

	if abs(pouncetrgt - window.position.x) < 50:
		pouncing = false
		change_state(State.IDLE)
		return
func mosueinpounce_zone():

	
	
	var mouse = DisplayServer.mouse_get_position()
	var fox_window = get_window()
	var fox = Vector2(fox_window.position) + Vector2(fox_window.size) * 0.5
	
	var rangy = 120
	var rangx = 250

	var inside = false

	if $AnimatedSprite2D.flip_h:
		inside = (
			mouse.x < fox.x and
			mouse.x > fox.x - rangx and
			abs(mouse.y - fox.y) < rangy
		)
		
		
		if inside:
			print("cursor entered left laser")
	else:
		inside = (
			mouse.x > fox.x and
			mouse.x < fox.x + rangx and
			abs(mouse.y - fox.y) < rangy
		)
		
		if inside:
			print("cursor entered right laser")
	return inside


func _on_neckarea_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		if event.pressed:
			dragging = true
			falling = false
			fallvelocity = 0.0
		else:
			if dragging:
				dragging = false
				falling = true
func startzoomies():
	if !achivement["hadzoomers"]:
		achivement["hadzoomers"] = true
		$"statslayer/CanvasLayer/StatsWindow/acheviements panel/Done5".visible = true
	if zoomies:
		return
		
	zoomies = true
	zoomietimer = zoomieduration
	
	change_state(State.ZOOMIES)
	happy = clamp(happy + 10, 0 , 100)





func _on_playbtn_pressed() -> void:
	if toy_active:
		return
	
	pictoy()
	
	
	
func pictoy():
	currenttoy = toys.pick_random()
	toy_window.start_toy(currenttoy)
	toy_active = true
	toypounced = false
	toycaught = false

func showstatswindow():
	stats_window.visible = true
	timerunningstats = true
	await get_tree().create_timer(5.0).timeout
	hidestatswindow()
func hidestatswindow():
	timerunningstats = false
	stats_window.visible = false
	
func toyvisible():
	return toy_window.visible
	
func findtoypos():
	return Vector2(toy_window.position) + Vector2(toy_window.size) / 2.0
	
func getfoxpos():
	var window = get_window()
	return Vector2(window.position) + Vector2(window.size) / 2.0
func droptoy():
	carryingtoy = false
	toycaught = false
	toy_window.carried = false
	toy_window.position = get_window().position + Vector2i(80, 80)
	toy_active = false
	#2 be called when dropping or at end mayb despawn it later wlooo
func resettoy():
	toy_active = false
	toythorwn = false
	toycaught = false
	carryingtoy = false
	returntoy = false
	toypounced = false
	toy_window.carried = false
	
	
	pouncing = false
	current_state = State.IDLE
	
	
	var window  = get_window()
	window.grab_focus()
	
	toy_window.position = window.position + Vector2i(80, 80)
	print("toy systm resetted")


func _on_ahcevement_panel_opener_pressed() -> void:
	
	var panel = $"statslayer/CanvasLayer/StatsWindow/acheviements panel"
	panel.visible = !panel.visible
#added achievements panel with written attainabale achivemnets 
#and if reached criteria it will display a tick mark yay
