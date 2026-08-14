extends CanvasLayer

@onready var bag = $Control/PanelContainer/BG/MarginContainer/BagMenu
@onready var party = $Control/PanelContainer/BG/MarginContainer/PartyMenu
@onready var attacks = $Control/PanelContainer/BG/MarginContainer/AttackMenu
@onready var settings = $Control/PanelContainer/BG/MarginContainer/SettingsMenu
#bag
@onready var item_list: ItemList = %ItemList

func show_menu(menu_to_show: Control):
	# 1. Hide all menus
	bag.visible = false
	party.visible = false
	attacks.visible = false
	settings.visible = false
	
	# 2. Show the specific menu passed into the function
	menu_to_show.visible = true

func refresh_menu() -> void:
	item_list.clear()
	
	# Loop through the Autoload's inventory array
	for item in GameData.inventory:
		item_list.add_item(item.Name, item.icon, true)

func _ready():
	show_menu(bag)
# Connect directly to the GameData Autoload's signal
	GameData.inventory_updated.connect(refresh_menu)
	
	# Go ahead and populate the menu immediately just in case 
	# the player already has items when this menu loads
	refresh_menu()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	queue_free()


func _onBagPressed() -> void:
	show_menu(bag)


func _onPartyPressed() -> void:
	show_menu(party)


func _onAttacksPressed() -> void:
	show_menu(attacks)


func _onSettingsPressed() -> void:
	show_menu(settings)
