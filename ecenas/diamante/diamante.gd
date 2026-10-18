# Este código controla cada diamante del nivel
# Cuando Kong lo recoge suena, suelta chispas, avisa al contenedor y desaparece
# Hereda de Node2D
extends Node2D

# Aquí se asigna el Area2D que detecta cuando Kong toca el diamante
@export var area_2D: Area2D

# Referencia al contenedor que lleva la cuenta de los diamantes
var contenedor_diamantes: ContenedorDiamantes

# Evita que el diamante se recoja dos veces
var _ya_recogido: bool = false

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Detecta cuando un cuerpo entra en el Area2D del diamante
	area_2D.body_entered.connect(_recogido)

	# Inicia la animación para que suba y baje
	_iniciar_animacion()

# Función que se activa cuando Kong toca el diamante
func _recogido(_body) -> void:
	# Si ya fue recogido
	if _ya_recogido:
		# No hace nada
		return
	# Marca el diamante como recogido
	_ya_recogido = true

	# Avisa al contenedor de que se recogió un diamante
	contenedor_diamantes.diamante_recogido()

	# Obtiene cuántos diamantes se llevan recogidos
	var recogidos: int = contenedor_diamantes._diamantes_recogidos
	# Obtiene cuántos diamantes hay en total
	var total: int = contenedor_diamantes._total_diamantes
	# Cada diamante suena un poco más agudo que el anterior (1.0, 1.1, 1.2...)
	Audio.sfx("diamante", 1.0 + 0.1 * (recogidos - 1), 0.0, 0.0)

	# Si es el último diamante
	if recogidos >= total:
		# Suena también el sonido de nivel completado
		Audio.sfx("nivel_completo")

	# Chispas brillantes en el lugar del diamante
	Efectos.chispas(get_parent().get_parent(), global_position, Color(0.8, 1.0, 1.0, 1.0), Color(0.3, 0.7, 1.0, 0.0), 22, 80.0, 0.45)

	# Elimina el diamante de la escena
	queue_free()

# Función que mueve el diamante arriba y abajo
func _iniciar_animacion():
	# Crea un tween para mover el diamante
	var tween: Tween = create_tween()

	# Hace que la animación se repita siempre
	tween.set_loops(0)

	# Sube el diamante un poco durante medio segundo
	tween.tween_property(self, "position:y", position.y - 5, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# Baja el diamante para repetir el movimiento
	tween.tween_property(self, "position:y", position.y + 5, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
