extends Window


var toydata = []
var holding  = false

@onready var ball = $Ball
@onready var bone = $Bone
@onready var feather = $Feather
#physics var
var dragging := false
var lastmouse := Vector2.ZERO
var velocity := Vector2.ZERO

var floor_y

# Called when the node enters the scene tree for the first time.
func start_toy(toy):
	toydata = toy
	
	$Ball.visible = false
	$Bone.visible = false
	$Feather.visible = false
	
	match toy.name:
		"ball":
			$Ball.visible = true
		"bone":
			$Bone.visible = true
		"feather":
			$Feather.visible = true
			
	show()
func _ready() -> void:
	
	borderless = true
	unresizable = true
	transparent = true
	always_on_top  = true
	size = Vector2i(32, 32)
	hide()
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		if event.is_pressed():
			dragging = true
			lastmouse = DisplayServer.mouse_get_position()
			velocity = Vector2.ZERO
			
		else:
			dragging = false
			
func _process(delta: float) -> void:
	var mouse = Vector2(DisplayServer.mouse_get_position())
	var window = get_window()

	if dragging:
		velocity = mouse - lastmouse
		window.position = Vector2i(mouse) - size / 2
	else:
		window.position += Vector2i(velocity)
		velocity *= 0.85
	var screen = DisplayServer.screen_get_size()
	var pos = window.position
	var size_i = size

	var floor_y = screen.y - size_i.y - 60

	if pos.x < 0:
		pos.x = 0
		velocity.x *= -0.8
	elif pos.x > screen.x - size_i.x:
		pos.x = screen.x - size_i.x
		velocity.x *= -0.8

	if pos.y < 0:
		pos.y = 0
		velocity.y *= -0.8
	elif pos.y > floor_y:
		pos.y = floor_y
		velocity.y *= -0.8

	window.position = pos
	lastmouse = mouse
