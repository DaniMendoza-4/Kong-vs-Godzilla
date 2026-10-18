# Este código hace aparecer aves de vez en cuando para que Kong las recoja
# Las aves cruzan la pantalla y sirven para recuperar vida
# Se coloca como un Node2D dentro de cada nivel
# Hereda de Node2D
extends Node2D

# Aquí se asigna la escena del ave que se va a crear
@export var escena_ave: PackedScene

# Segundos que pasan entre la aparición de cada ave
@export var segundos_entre_aves: float = 20.0

# Cantidad máxima de aves que puede haber a la vez en pantalla
@export var max_aves_a_la_vez: int = 1

# Velocidad con la que se mueven las aves
@export var velocidad_ave: float = 60.0

# Altura mínima a la que pueden aparecer
@export var altura_min: float = 30.0

# Altura máxima a la que pueden aparecer
@export var altura_max: float = 100.0

# Temporizador que controla cuándo aparecen las aves
var _timer := Timer.new()

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Agrega el generador al grupo "spawner" para poder detenerlo al cambiar de nivel
	add_to_group("spawner")

	# Si no se asignó la escena del ave
	if not escena_ave:
		# Avisa en la consola
		push_warning("SpawnerAves: falta asignar 'Escena Ave' en el Inspector.")

	# Establece cada cuántos segundos aparece una ave nueva
	_timer.wait_time = segundos_entre_aves

	# Conecta el temporizador con la función que crea las aves
	_timer.timeout.connect(_on_timer_timeout)

	# Agrega el temporizador como hijo
	add_child(_timer)

	# Inicia el temporizador
	_timer.start()

# Función que detiene la aparición de aves
func detener() -> void:
	# Detiene el temporizador
	_timer.stop()

# Se ejecuta cada vez que termina el tiempo del temporizador
func _on_timer_timeout() -> void:
	# Si no hay escena o ya se llegó al máximo de aves, no crea otra
	if not escena_ave or get_tree().get_nodes_in_group("aves").size() >= max_aves_a_la_vez:
		# Sale de la función
		return

	# Crea una copia de la escena del ave
	var ave: Area2D = escena_ave.instantiate()

	# Le asigna la velocidad
	ave.velocidad = velocidad_ave

	# Elige una altura aleatoria entre los límites
	var altura := randf_range(altura_min, altura_max)

	# Decide al azar de qué lado aparece el ave
	if randf() < 0.5:
		# Aparece por la derecha y va hacia la izquierda
		ave.position = Vector2(212, altura)
		ave.direccion = Vector2.LEFT
	# Si no, aparece por la izquierda y va hacia la derecha
	else:
		ave.position = Vector2(-212, altura)
		ave.direccion = Vector2.RIGHT

	# Agrega el ave al nivel
	get_parent().add_child(ave)
