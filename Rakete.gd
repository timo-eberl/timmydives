class_name Rocket
extends RigidBody2D

@onready var rocketSprite : Sprite2D = $Rakete;
@export var explosion : PackedScene;
@onready var obstacles : Map = get_tree().root.get_child(0).get_node("ObstaclesTiles")
@export var explosion_knockback := 5.0
@onready var upgrade_counter : UpgradeCounter = get_tree().root.get_child(0).find_child("Player").find_child("UpgradeCounter")
var rocket_power : float;


func _process(_delta):
	#rocketSprite.look_at(get_global_mouse_position())
	#self.apply_force(get_global_mouse_position() - global_position)
	pass;

func _ready() -> void:
	rocketSprite.look_at(get_global_mouse_position())
	rocketSprite.scale = Vector2(0.6, 0.6) * ((4 + rocket_power) / 4.0) ;
	self.apply_impulse((get_global_mouse_position() - global_position).normalized() * 1000.0)
	
	pass

func _integrate_forces(_state: PhysicsDirectBodyState2D):
	#self.linear_velocity = (Vector2.RIGHT * 100.0).rotated(get_angle_to(get_global_mouse_position()))
	pass;

# only call this during _physic_process
func explode():
	# Spawn visual explosions
	var explo = explosion.instantiate()
	explo.global_position = global_position
	explo.scale = Vector2(4,4) * (1 + rocket_power);
	get_tree().root.add_child(explo)
	
	var radius = 150 + rocket_power * 30;
	var damage = 4 + (rocket_power / 3) # damage should be between 1 and 4
	
	var space_state = get_world_2d().direct_space_state
	var shape_rid = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape_rid, radius)
	
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape_rid = shape_rid
	query.transform = Transform2D(0, global_position)
	
	var results = space_state.intersect_shape(query, 512)
	# Release the shape when done with physics queries.
	PhysicsServer2D.free_rid(shape_rid)
	
	for result in results:
		# damage map
		if result.collider == obstacles:
			var coords := obstacles.get_coords_for_body_rid(result.rid)
			var global_coords := obstacles.to_global(obstacles.map_to_local(coords))
			var d := (global_position - global_coords).length()
			var damage_reduction := int(d / 70.0) # with distance, reduce damage
			for i in (damage - damage_reduction):
				obstacles.take_damage_at(coords)
		# damage enemies
		if result.collider is Enemy:
			var enemy : Enemy = result.collider
			enemy.take_damage(damage / 2.0)
			enemy.apply_impulse(
				(enemy.global_position - global_position).normalized() * 100.0 * damage * explosion_knockback
			)
	
	self.get_parent().queue_free()

func _on_body_entered(_body: Node) -> void:
	explode()
