# Este código crea las bolas de fuego que aparecen en cada nivel
# Salen por los lados o caen desde arriba, y algunas hacen que Kong muera
# Hereda de Node2D
extends Node2D

# Aquí se asigna la escena de la bola de daño leve
@export var escena_bola_leve: PackedScene

# Aquí se asigna la escena de la bola que mata a Kong
@export var escena_bola_muerte: PackedScene

# Segundos que pasan entre la aparición de cada bola, si es mayor salen menos bolas
@export var segundos_entre_bolas: float = 4.0

# Velocidad de la bola de daño leve
@export var velocidad_leve: float = 150.0

# Velocidad de la bola de muerte
@export var velocidad_muerte: float = 170.0

# Probabilidad de que salga una bola de muerte (0.25 es un 25%)
@export var probabilidad_muerte: float = 0.25

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Agrega el generador al grupo "spawner" para poder detenerlo al cambiar de nivel
	add_to_group("spawner")

	# Si falta alguna de las dos escenas
	if not escena_bola_leve or not escena_bola_muerte:
		# Avisa en la consola
		push_warning("SpawnerBolas: falta asignar 'Escena Bola Leve' y/o 'Escena Bola Muerte' en el Inspector.")

	# Inicia el temporizador para crear las bolas
	$Timer.start(segundos_entre_bolas)

# Función que detiene la aparición de bolas
func detener() -> void:
	# Detiene el temporizador
	$Timer.stop()

# Se ejecuta cada vez que termina el tiempo del temporizador
func _on_timer_timeout() -> void:
	# Si falta alguna escena, no crea nada
	if not escena_bola_leve or not escena_bola_muerte:
		# Sale de la función
		return

	# Posición donde aparece la bola
	var posicion: Vector2
	# Dirección hacia donde se mueve
	var direccion: Vector2

	# Puede salir por la derecha y moverse hacia la izquierda
	if randf() < 0.5:
		posicion = Vector2(212, randf_range(-100, 116))
		direccion = Vector2.LEFT

	# O aparecer arriba y caer hacia abajo
	else:
		posicion = Vector2(randf_range(-212, 212), -100)
		direccion = Vector2.DOWN

	# Busca a Kong para que la bola no aparezca muy cerca de él
	var kong := get_tree().get_first_node_in_group("jugador") as Node2D

	# Si Kong está a menos de 90 unidades del punto de aparición, cancela la bola
	if kong and get_parent().to_global(posicion).distance_to(kong.global_position) < 90:
		return

	# Variable donde se guarda la bola
	var bola: Area2D

	# Decide al azar si la bola es mortal
	if randf() < probabilidad_muerte:
		# Crea la bola de muerte
		bola = escena_bola_muerte.instantiate()

		# Le asigna su velocidad
		bola.velocidad = velocidad_muerte

	# Si no, crea la bola de daño leve
	else:
		# Crea la bola de daño leve
		bola = escena_bola_leve.instantiate()

		# Le asigna su velocidad
		bola.velocidad = velocidad_leve

	# Coloca la bola en la posición elegida
	bola.position = posicion

	# Le dice hacia dónde moverse
	bola.direccion = direccion

	# Agrega la bola al nivel
	get_parent().add_child(bola)
