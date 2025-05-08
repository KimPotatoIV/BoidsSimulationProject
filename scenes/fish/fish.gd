extends Node2D

##################################################
const SCREEN_SIZE: Vector2 = Vector2(1920.0, 1080.0)
# 화면 크기
const TEXTURE_1: Texture = preload("res://scenes/fish/fish_1.png")
const TEXTURE_2: Texture = preload("res://scenes/fish/fish_2.png")
const TEXTURE_3: Texture = preload("res://scenes/fish/fish_3.png")
const TEXTURE_4: Texture = preload("res://scenes/fish/fish_4.png")
const TEXTURE_5: Texture = preload("res://scenes/fish/fish_5.png")
# 물고기 텍스처들
const MOVING_SPEED: float = 100.0
# 물고기 이동 속도
const BOUNDARY_MARGIN: float = 64.0
# 가장자리 이동 제한 마진
const SEPERATION_FACTOR: float = 5000.0
const ALIGNMENT_FACTOR: float = 5.0
const COHESION_FACTOR: float = 5.0
# 분리/정렬/응집 계수
const BOUNDARY_FACTOR: float = 100.0
# 가장자리 이동 제한 계수
const MAX_CALCULATION: int = 20
# 최대 연산 수

var sprite_node: Sprite2D
var area_node: Area2D

var type: int = 0
# 물고기 종류
var velocity: Vector2 = Vector2.ZERO
# 속도 및 방향
var acceleration: Vector2 = Vector2.ZERO
# velocity에 적용할 가속도
var other_fishes: Array = []
# 다른 물고기들 연산 목록

##################################################
func _ready() -> void:
	sprite_node = $Sprite2D
	area_node = $Area2D
	
	area_node.connect("area_entered", Callable(self, "_on_area_entered"))
	area_node.connect("area_exited", Callable(self, "_on_area_exited"))
	
	var rand_texture: int = randi_range(0, 5)
	match rand_texture:
		0:
			sprite_node.texture = TEXTURE_1
			type = 0
		1:
			sprite_node.texture = TEXTURE_2
			type = 1
		2:
			sprite_node.texture = TEXTURE_3
			type = 2
		3:
			sprite_node.texture = TEXTURE_4
			type = 3
		4:
			sprite_node.texture = TEXTURE_5
			type = 4
	# 각 물고기 스프라이트를 임의로 설정 후 타입도 지정
	
	velocity = Vector2(randf_range(-1.0, 1.0), \
		randf_range(-1.0, 1.0)).normalized() * MOVING_SPEED
	# 시작 velocity를 임의로 설정

##################################################
func _physics_process(delta: float) -> void:
	acceleration = Vector2.ZERO
	# 가속도 초기화
	apply_separation()
	# 분리 힘 적용
	apply_alignment()
	# 정렬 힘 적용
	apply_cohesion()
	# 응집 힘 적용
	velocity += acceleration * delta
	# velocity에 가속도 적용
	velocity = velocity.normalized() * MOVING_SPEED
	# 가속도를 정규화 후 일정 속도로 변환
	# 가속도로는 방향만 바꾸겠다는 의도
	position += velocity * delta
	# 실제 이동
	limit_boundary()
	# 가장자리로 이동하면 방향 전환
	sprite_node.flip_h = velocity.x < 0
	# 이동하는 x 방향에 따라 스프라이트 전환
	
	reset_position()
	# 혹시 화면 밖으로 나가면 화면 중앙으로 초기화

##################################################
func _on_area_entered(area: Area2D) -> void:
	var other_fish = area.get_parent()
	if other_fish != self and not other_fishes.has(other_fish):
		other_fishes.append(other_fish)
# area에 들어오면 연산 물고기 목록에 등록

##################################################
func _on_area_exited(area: Area2D) -> void:
	var other_fish = area.get_parent()
	other_fishes.erase(other_fish)
# area에서 나가면 연산 물고기 목록에서 해제

##################################################
func apply_separation() -> void:
	var separation_force := Vector2.ZERO
	var total_count: int = 0
	
	for fish in other_fishes:
	# 연산 목록 물고기들을 순회하며
		var direction = global_position - fish.global_position
		var distance = direction.length()
		# 나와 다른 물고기 사이의 방향 및 거리를 구함
		
		if distance > 0 and distance < BOUNDARY_MARGIN:
		# 일정 거리 이상 가까우면
			separation_force += direction.normalized() / distance
			# 거리가 가까울수록 큰 힘을 반대 방향으로 중첩하여 줌
			total_count += 1
		
		if total_count > MAX_CALCULATION:
			break
		# 최대 연산 제한
	
	if total_count > 0:
		separation_force /= total_count
		# 중첩된 힘을 total_count로 나눠 평균을 구함
		acceleration += separation_force * SEPERATION_FACTOR
		# 가속도에 적용

##################################################
func apply_alignment() -> void:
	var average_velocity: Vector2 = Vector2.ZERO
	var total_count: int = 0

	for fish in other_fishes:
	# 연산 목록 물고기들을 순회하며
		if type != fish.type:
			continue
		# 같은 타입의 물고기만 아래 연산을 실행
		
		average_velocity += fish.velocity
		# 상대 물고기의 velocity를 중첩
		total_count += 1
		
		if total_count > MAX_CALCULATION:
			break
		# 최대 연산 제한

	if total_count > 0:
		average_velocity /= total_count
		# 중첩된 velocity를 total_count로 나눠 평균을 구함
		var alignment_force: Vector2 = average_velocity - velocity
		# 주변 물고기들과의 평균 velocity를 맞추기 위한 연산
		# 주변 물고기가 Vector(200, 0)이고 내가 Vector(-200, 0)이라면 
		# Vector(200, 0) - Vector(-200, 0) = Vector(400, 0)
		# 내가 우측으로 현재 velocity의 반대 방향으로 두 배의 힘을 줘야 갈 수 있는 상태
		acceleration += alignment_force * ALIGNMENT_FACTOR
		# 가속도에 적용

##################################################
func apply_cohesion() -> void:
	var center_of_position := Vector2.ZERO
	var total_count: int = 0
	
	for fish in other_fishes:
	# 연산 목록 물고기들을 순회하며
		if type != fish.type:
			continue
		# 같은 타입의 물고기만 아래 연산을 실행
		
		center_of_position += fish.global_position
		# 상대 물고기의 좌표를 중첩
		total_count += 1
		
		if total_count > MAX_CALCULATION:
			break
		# 최대 연산 제한
	
	if total_count > 0:
		center_of_position /= total_count
		# 좌표 평균 값을 구함
		var cohesion_force := (center_of_position - global_position).normalized()
		# 이동해야 할 방향을 구함
		acceleration += cohesion_force * COHESION_FACTOR
		# 가속도에 적용

##################################################
func limit_boundary() -> void:
	if global_position.x < BOUNDARY_MARGIN or \
		global_position.x > SCREEN_SIZE.x - BOUNDARY_MARGIN:
			velocity.x *= -BOUNDARY_FACTOR
	elif global_position.y < BOUNDARY_MARGIN or \
		global_position.y > SCREEN_SIZE.y - BOUNDARY_MARGIN:
			velocity.y *= -BOUNDARY_FACTOR

##################################################
func reset_position() -> void:
	if global_position.x < 0.0 or global_position.x > SCREEN_SIZE.x or \
		global_position.y < 0.0 or global_position.y > SCREEN_SIZE.y:
			global_position = SCREEN_SIZE / 2
