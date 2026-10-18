# Este código controla la interfaz del juego: la vida de Kong, los diamantes y el nivel actual
# También muestra mensajes como ¡GANASTE! al terminar el juego
# Hereda de Control
extends Control

# Referencia a la barra de vida
var _barra: Range

# Texto donde aparece la cantidad de diamantes
var _contador: Label

# Texto donde aparece el número del nivel
var _texto_nivel: Label

# Estilo del relleno, permite cambiar el color de la barra
var _relleno := StyleBoxFlat.new()

# Tween que actualiza la barra suavemente
var _tween: Tween

# Tween que hace latir la barra en rojo cuando queda poca vida
var _pulso: Tween

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Busca la barra de vida dentro de la interfaz
	_barra = find_child("BarraVida", true, false) as Range

	# Busca los textos cuyo nombre empiece por ContadorDiamant
	var contadores := find_children("ContadorDiamant*", "Label", true, false)

	# Si encontró alguno
	if contadores.size() > 0:
		# Guarda el primero
		_contador = contadores[0]

	# Busca el texto del nivel actual
	_texto_nivel = find_child("TextoNivel", true, false) as Label

	# Si se encontró la barra, la configura
	if _barra:
		# Valor mínimo de la barra
		_barra.min_value = 0

		# Valor máximo de la barra
		_barra.max_value = 100

		# La barra empieza llena
		_barra.value = 100

		# Redondea las esquinas del relleno
		_relleno.set_corner_radius_all(6)

		# Si es una ProgressBar
		if _barra is ProgressBar:
			# Le aplica el estilo personalizado
			_barra.add_theme_stylebox_override("fill", _relleno)

# Función que actualiza la barra cuando cambia la vida de Kong
func actualizar_vida(vida: float, maximo: float = 100.0) -> void:
	# Si no hay barra, no hace nada
	if not _barra:
		# Sale de la función
		return

	# Si ya había un tween, lo detiene
	if _tween:
		_tween.kill()

	# Crea un tween nuevo
	_tween = create_tween()
	# Cambia el valor de la barra suavemente
	_tween.tween_property(_barra, "value", vida / maximo * 100.0, 0.25)

	# Calcula el porcentaje de vida que le queda
	var porcentaje := vida / maximo

	# La barra empieza en verde
	var color := Color(0.25, 0.8, 0.3)

	# Si queda un 30% o menos, se pone roja
	if porcentaje <= 0.3:
		color = Color(0.9, 0.2, 0.2)

	# Si queda un 60% o menos, se pone amarilla
	elif porcentaje <= 0.6:
		color = Color(0.95, 0.8, 0.2)

	# Aplica el color al relleno
	_relleno.bg_color = color

	# Si es una TextureProgressBar, también cambia su color
	if _barra is TextureProgressBar:
		_barra.tint_progress = color

	# Con poca vida la barra late en rojo para avisar del peligro
	if porcentaje <= 0.3 and porcentaje > 0.0:
		# Si no hay pulso activo, lo crea
		if _pulso == null or not _pulso.is_valid():
			# Pulso que se repite siempre
			_pulso = create_tween().set_loops()
			# Se pone rojiza
			_pulso.tween_property(_barra, "modulate", Color(1.0, 0.55, 0.55), 0.35)
			# Y vuelve a su color normal
			_pulso.tween_property(_barra, "modulate", Color.WHITE, 0.35)
	# Si no hay poca vida
	else:
		# Si había un pulso
		if _pulso:
			# Lo detiene
			_pulso.kill()
			# Y lo borra
			_pulso = null
		# La barra vuelve a su color normal
		_barra.modulate = Color.WHITE

# Función que actualiza el contador de diamantes (por ejemplo 4/8)
func actualizar_diamantes(actuales: int, meta: int) -> void:
	# Si existe el texto del contador
	if _contador:
		# Muestra los diamantes recogidos y la meta del nivel
		_contador.text = "💎 %d/%d" % [actuales, meta]

# Función que actualiza el texto del nivel
func actualizar_nivel(nivel: int) -> void:
	# Si existe el texto del nivel
	if _texto_nivel:
		# Muestra el número del nivel
		_texto_nivel.text = "NIVEL %d" % nivel

# Función que muestra un mensaje grande en el lugar del número del nivel
# Se usa para mostrar ¡GANASTE! o avisar que falta un nivel
func mostrar_mensaje(texto: String) -> void:
	# Si existe el texto del nivel
	if _texto_nivel:
		# Lo cambia por el mensaje recibido
		_texto_nivel.text = texto
