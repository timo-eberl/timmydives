class_name PufferFish
extends Enemy

@onready var idle : Sprite2D = $Texture/IdleTexture

@export var unpuffed : CompressedTexture2D
@export var puffed : CompressedTexture2D

@export var shake_amount := 1.0

var puff : bool = false
var hit_player :bool = false
var shrink : bool = false
var puff_done : bool = false

@export var default_scale := 0.7
@export var puffed_scale := 1.4
@export var puff_speed := .5
@export var unpuff_speed := .5
var puff_progress := 0.0

func _process(delta):
	if is_dead:
		if death_fade_out_progress >= 1.0:
			queue_free()
		else:
			var current_fade = lerp(0.0, 1.0, death_fade_out_progress)
			sprites.get_node("DeathSprite").set_self_modulate(Color(1.0, 1.0, 1.0, 1.0 - current_fade))
	
		death_fade_out_progress += delta
	
	if not is_dead:
		if damage_taken:
			if hit_timer <= fade_out_duration:
				var modulate_color = lerp(hit_modulation_color, Color.WHITE, hit_timer / fade_out_duration)
				for sprite in sprites.get_children():
					sprite.set_self_modulate(modulate_color)
			else:
				damage_taken = false
				hit_timer = 0.0
			hit_timer += delta
		if puff:
			var puff_amount = lerp(default_scale, puffed_scale, puff_progress / puff_speed)
			
			idle.scale = Vector2(puff_amount, puff_amount)
			
			if puff_progress >= puff_speed:
				puff = false
				hit_player = true
				puff_progress = 0.0
			
			puff_progress += delta
		
		if hit_player:
			if player_in_area:
				player.apply_hit(enemy_stats.damage)
			hit_player = false;
			shrink = true

		if shrink:
			damage_timer = 0.0
			
			var unpuff_amount = lerp(puffed_scale, default_scale, puff_progress / unpuff_speed)
			
			idle.scale = Vector2(unpuff_amount, unpuff_amount)
			if puff_progress >= unpuff_speed:
				shrink = false
				puff_done = true
				puff_progress = 0.0
			damage_timer = 0.0
			
			puff_progress += delta
		
		if puff_done:
			idle.texture = unpuffed
			sprites.position = Vector2(0.0, 0.0)
			puff_done = false
		
		if player_in_area:
			var random_dir = Vector2(randf() - 0.5, randf() - 0.5).normalized()
			sprites.position += random_dir * shake_amount
			
			if damage_timer >= enemy_stats.hit_cooldown:
				puff = true
				idle.texture = puffed
			damage_timer += delta
		
		if health <= 0:
			_kill_enemy()
		
	if not animationPlayer.is_playing() and not is_dead:
		animationPlayer.play("idle")

func _physics_process(_delta):
	awake_if_water()
	if not is_asleep and not is_dead or player_in_area and not is_dead:
		_move()

func _area_entered(body):
	if body.name == "Player" and not is_asleep:
		player_in_area = true

func _area_left(body):
	if body.name == "Player" and not is_asleep:
		player_in_area = false
		damage_timer = 0.0

func _on_area_2d_body_entered(body):
	_area_entered(body)


func _on_area_2d_body_exited(body):
	_area_left(body)
	damage_timer = 0.0
	idle.position = Vector2(0.0, 0.0)
