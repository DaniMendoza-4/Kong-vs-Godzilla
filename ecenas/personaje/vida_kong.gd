# Este código controla la vida de Kong
# Permite quitar vida, recuperarla y avisar cuando Kong muere
# Hereda de Node
extends Node

# Señal que avisa cuando cambia la vida de Kong
signal vida_cambio(vida_actual)

# Señal que se activa cuando Kong se queda sin vida
signal kong_muerto

# Cantidad máxima de vida que puede tener Kong
@export var vida_maxima: float = 100.0

# Guarda la vida que tiene Kong en ese momento
var vida_actual: float

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Hace que Kong empiece con la vida completa
	vida_actual = vida_maxima

	# Avisa a los demás nodos de cuánta vida tiene
	vida_cambio.emit(vida_actual)

# Función que reduce la vida según el daño recibido
func recibir_daño(cantidad: float) -> void:
	# Resta el daño a la vida actual
	vida_actual -= cantidad

	# Evita que la vida sea menor que cero o mayor que el máximo
	vida_actual = clamp(vida_actual, 0.0, vida_maxima)

	# Avisa que la vida cambió para actualizar la barra
	vida_cambio.emit(vida_actual)

	# Si Kong se queda sin vida
	if vida_actual <= 0:
		# Avisa que murió
		kong_muerto.emit()

# Función que permite recuperar vida
func curar(cantidad: float) -> void:
	# Suma la vida que se recupera
	vida_actual += cantidad

	# Evita que la vida pase del máximo
	vida_actual = clamp(vida_actual, 0.0, vida_maxima)

	# Actualiza la barra de vida
	vida_cambio.emit(vida_actual)

# Función que quita vida cuando Kong recibe una bola de daño leve
func daño_bola_leve() -> void:
	# Resta 10 puntos de vida
	recibir_daño(10.0)

# Función que quita vida cuando Kong toca los pinchos
func daño_pinchos() -> void:
	# Resta 5 puntos de vida
	recibir_daño(5.0)

# Función que elimina toda la vida de Kong
func daño_mortal() -> void:
	# Pone la vida directamente en cero
	vida_actual = 0.0

	# Actualiza la barra para mostrar que ya no tiene vida
	vida_cambio.emit(vida_actual)

	# Avisa que Kong murió
	kong_muerto.emit()

# Función que recupera vida al comer un ave
func comer_ave() -> void:
	# Suma 25 puntos de vida sin pasar el máximo
	curar(25.0)

# Función que pone la vida de Kong al pasar de nivel
func fijar_vida(valor: float) -> void:
	# Asigna la vida recibida sin salirse de los límites
	vida_actual = clamp(valor, 0.0, vida_maxima)

	# Avisa que la vida cambió para actualizar la barra
	vida_cambio.emit(vida_actual)
