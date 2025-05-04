extends Node3D

var ad : AbilityData

@onready var visual = $Visual
@onready var recall_timer = $RecallTimer
@onready var manager = get_node("..")

func press() -> Basics.AbilityError:
	manager.in_casting = true
	manager.disable_player_movement(ad.ability_dealer)
	get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
		manager.enable_player_movement(ad.ability_dealer)
		manager.stop_player_path(ad.ability_dealer)
		recall_timer.start()
		manager.start_channeling(recall_timer.wait_time, "Recall", true)
		visual.set_visible(true))
	return Basics.AbilityError.OK

func cancel_ability(reason : Basics.AbilityCancel) -> void:
	if reason == Basics.AbilityCancel.TAKING_DAMAGE:
		manager.stop_player_path(ad.ability_dealer)
	manager.start_ability_cooldown(ad.ability)
	manager.stop_channeling()
	manager.in_casting = false
	manager.enable_player_movement(ad.ability_dealer)
	queue_free()

func _on_recall_timer_timeout() -> void:
	manager.entity.respawn_base()
	cancel_ability(Basics.AbilityCancel.MOVING)
