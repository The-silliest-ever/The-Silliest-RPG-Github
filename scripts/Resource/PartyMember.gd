class_name PartyMember
extends Resource

@export_category("Info")
@export var name: String = "Choose"
@export_multiline var description: String = "choose"
@export var portrait: Texture2D

@export_category("Attacks")
@export var equipped_attacks: Array[AttackResource] = [
	preload("res://AttackResources/Nothing.tres"),
	preload("res://AttackResources/Nothing.tres"),
	preload("res://AttackResources/Nothing.tres"),
	preload("res://AttackResources/Nothing.tres")
]
