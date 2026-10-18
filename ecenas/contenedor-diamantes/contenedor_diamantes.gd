# Este código controla los diamantes del nivel
# Lleva la cuenta de cuántos hay y cuántos ha recogido Kong
# Le da nombre de clase para poder usarlo desde otros scripts
class_name ContenedorDiamantes

# Hereda de Node
extends Node

# Guarda la cantidad total de diamantes del nivel
var _total_diamantes: int

# Guarda la cantidad de diamantes que Kong ya recogió
var _diamantes_recogidos: int

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Obtiene todos los diamantes que hay dentro del contenedor
	var diamantes := get_children()

	# Guarda la cantidad total de diamantes
	_total_diamantes = diamantes.size()

	# Recorre todos los diamantes
	for diamante in diamantes:
		# Le dice a cada diamante cuál es su contenedor
		diamante.contenedor_diamantes = self

# Función que se activa cuando Kong recoge un diamante
func diamante_recogido():
	# Aumenta en uno los diamantes recogidos
	_diamantes_recogidos += 1

	# Obtiene la escena principal siguiendo la jerarquía: Contenedor -> Nivel -> EscenaPrincipal
	var ecena = get_parent().get_parent()

	# Avisa a la escena principal para actualizar el contador
	ecena.diamante_recogido()

	# Si ya recogió todos los diamantes
	if _diamantes_recogidos == _total_diamantes:
		# Pasa al siguiente nivel
		ecena.siguiente_nivel()
