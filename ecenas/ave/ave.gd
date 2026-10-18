# Hereda de Area2D para detectar cuando Kong toca el ave
extends Area2D

# Velocidad con la que se mueve el ave
@export var velocidad: float = 60.0

# Cantidad de espacio que sube y baja mientras vuela
@export var amplitud: float = 12.0

# Velocidad con la que sube y baja
@export var frecuencia: float = 4.0

# Dirección en la que empieza a moverse el ave
var direccion: Vector2 = Vector2.LEFT

# Guarda el tiempo para controlar el movimiento
var _tiempo: float = 0.0

# Guarda la posición vertical inicial del ave
var _y_base: float = 0.0

# Referencia a la animación del ave
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Agrega el ave al grupo "aves"
	add_to_group("aves")

	# Configura la capa de colisión para que Kong pueda detectarla
	collision_layer = 2
	# No detecta nada, solo es detectada
	collision_mask = 0

	# Voltea el sprite según hacia dónde se mueve
	sprite.flip_h = direccion == Vector2.RIGHT

	# Inicia la animación de vuelo
	sprite.play("volar")

	# Guarda la posición inicial en Y
	_y_base = position.y

# Se ejecuta en cada frame
func _process(delta: float) -> void:
	# Aumenta el tiempo para el movimiento de subir y bajar
	_tiempo += delta

	# Mueve el ave en horizontal según su dirección y velocidad
	position.x += direccion.x * velocidad * delta

	# Hace que suba y baje mientras avanza
	position.y = _y_base + sin(_tiempo * frecuencia) * amplitud

	# Si sale de la pantalla
	if abs(position.x) > 260.0:
		# Elimina el ave
		queue_free()

# Función que se activa cuando Kong toca el ave
func impactar(objetivo) -> void:
	# Si Kong ya tiene toda la vida, el ave no se consume
	if objetivo.has_method("necesita_vida") and not objetivo.necesita_vida():
		# Sale de la función
		return

	# Si Kong se puede curar, recupera vida
	if objetivo.has_method("recibir_cura"):
		# Cura a Kong
		objetivo.recibir_cura()

	# Elimina el ave después de que Kong la coma
	queue_free()
