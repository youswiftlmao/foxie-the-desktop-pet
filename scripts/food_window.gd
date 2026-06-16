extends Window

var holding := false
var food_data = {}

func _ready():
	borderless = true
	transparent = true
	always_on_top = true
	unresizable = true
	size = Vector2i(60, 60)
	visible = false

func start_food(data):
	food_data = data
	holding = true
	visible = true
	update_visual()
func stop_food():
	holding = false
	visible = false
	update_visual()
func _process(_delta):
	if holding:
		position = DisplayServer.mouse_get_position() - Vector2i(size.x/2, size.y/2)
func update_visual():
	$apple.visible = false
	$meat.visible = false
	$egg.visible = false
	$fish.visible = false
	$cake.visible = false

	match food_data["name"]:
		"apple":
			$apple.visible = true
		"meat":
			$meat.visible = true
		"egg":
			$egg.visible = true
		"fish":
			$fish.visible = true
		"cake":
			$cake.visible = true
func get_food_name():
	return food_data["name"]
