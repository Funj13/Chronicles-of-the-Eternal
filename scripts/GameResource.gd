class_name GameResource
extends Node

signal depleated
signal replenished
signal max_changed(new_max)
signal current_changed(new_current)

@export var max_amount := 10 : set = set_max_amount

@onready var current_amount := max_amount : set = set_current_amount


func _ready() -> void:
	max_changed.emit(max_amount)
	current_changed.emit(current_amount)


func set_max_amount(new_max_amount: int) -> void:
	if current_amount == max_amount:
		current_amount = new_max_amount
	max_amount = new_max_amount
	max_changed.emit(max_amount)


func set_current_amount(new_amount: int) -> void:
	current_amount = clampi(new_amount, 0, max_amount)
	current_changed.emit(current_amount)
	if new_amount < 1:
		depleated.emit()
	elif new_amount >= max_amount:
		replenished.emit()


func increase(amount: int) -> void:
	current_amount += amount


func decrease(amount: int) -> void:
	current_amount -= amount
