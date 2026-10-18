# Esta es la bola que se mueve por el nivel y si Kong la toca recibe daño leve
# Puede moverse hacia un lado o caer hacia abajo, y explota al llegar al borde
# Hereda de Area2D para detectar cuando toca a Kong
extends Area2D

# Velocidad con la que se mueve la bola
@export var velocidad: float = 150.0

# Tamaño de la imagen de la bola
@export var escala_visual: float = 1.3

# Textura de la bola cuando se mueve en horizontal
@export var textura_horizontal: Texture2D

# Textura de la bola cuando cae hacia abajo
@export var textura_vertical: Texture2D

# Dirección en la que empieza a moverse
var direccion: Vector2 = Vector2.LEFT

# Guarda si la bola ya está explotando
var _explotando: bool = false

# Referencia al Sprite2D de la bola
@onready var sprite = $Sprite2D

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Agrega la bola al grupo "bolas"
	add_to_group("bolas")

	# Capa de colisión de la bola
	collision_layer = 2

	# Hace que detecte los bordes del nivel
	collision_mask = 1

	# Conecta la colisión con la función que revisa si toca un borde
	body_entered.connect(_al_chocar)

	# Elige la textura según la dirección
	if direccion == Vector2.DOWN:
		sprite.texture = textura_vertical
	# Si no cae, usa la textura horizontal
	else:
		sprite.texture = textura_horizontal

	# Aumenta el tamaño de la imagen
	sprite.scale *= escala_visual

# Se ejecuta en cada frame
func _process(delta: float) -> void:
	# Si ya está explotando, no se mueve
	if _explotando:
		return

	# Mueve la bola según su dirección y velocidad
	position += direccion * velocidad * delta

	# Por seguridad, la elimina si se aleja mucho de la pantalla
	if abs(position.x) > 400 or abs(position.y) > 300:
		queue_free()

# Función que se activa cuando Kong toca la bola
func impactar(kong) -> void:
	# Si ya está explotando, no hace daño
	if _explotando:
		return

	# Kong recibe daño leve
	kong.recibir_daño_leve()

	# Elimina la bola después de golpear a Kong
	queue_free()

# Revisa si la bola choca con los bordes del nivel, los bloques los atraviesa sin explotar
func _al_chocar(cuerpo: Node2D) -> void:
	# Si no es un borde, no hace nada
	if not cuerpo.name.begins_with("borde"):
		return

	# Si va hacia la izquierda y llega al borde, explota
	if direccion == Vector2.LEFT and position.x < 0:
		explotar()

	# Si cae hacia abajo y llega al borde de abajo, explota
	elif direccion == Vector2.DOWN and position.y > 0:
		explotar()

# Función que hace la animación de la explosión
func explotar() -> void:
	# Indica que ya está explotando
	_explotando = true

	# Desactiva las colisiones para que ya no haga daño
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Crea un tween para que crezca y desaparezca al mismo tiempo
	var tween := create_tween().set_parallel(true)

	# Hace crecer la imagen durante la explosión
	tween.tween_property(sprite, "scale", sprite.scale * 1.8, 0.3)

	# Hace que se vuelva transparente con un tono naranja
	tween.tween_property(sprite, "modulate", Color(1.0, 0.6, 0.2, 0.0), 0.3)

	# Al terminar, elimina la bola
	tween.chain().tween_callback(queue_free)
