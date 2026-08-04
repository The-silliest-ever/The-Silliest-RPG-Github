class_name AttackResource
extends Resource

@export var name: String = "Enrique"
@export var damage: int = 10
@export var heal_amount: int = 0
@export var sprite_texture: Texture2D
@export_enum("Physical", "Special", "Heal") var type: String = "Physical"
@export_enum("None", "Attack", "Defense", "Specialattck", "Specialdfnse") var statAdd: String = "None"
@export_enum("None", "Attack", "Defense", "Specialattck", "Specialdfnse") var statMinus: String = "None"
@export_enum("None", "Attack", "Defense", "Specialattck", "Specialdfnse") var statAddSelf: String = "None"
@export_enum("None", "Attack", "Defense", "Specialattck", "Specialdfnse") var statMinusSelf: String = "None"
@export_enum("None", "Burn", "Poison", "Groovy", "LifeSteal", "Mini") var StatusEffect: String = "None"
@export_enum("None", "Burn", "Poison", "Groovy", "Electrified", "Mini") var StatusEffectSelf: String = "None"
