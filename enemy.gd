extends Area2D

signal enemy_destroyed

func _on_area_entered(_area):
	queue_free()
	enemy_destroyed.emit()


func destroy():
	queue_free()
