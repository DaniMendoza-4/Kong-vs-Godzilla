# Escena final del juego (¡GANASTE!)
# Controla los dos botones: JUGAR DE NUEVO y VER CRÉDITOS
# Esta escena tiene que tener, como hijos del nodo raíz, estos dos nodos (con estos nombres exactos):
# BotonJugar (TextureButton)
# BotonCreditos (TextureButton)
# Hereda de Node2D
extends Node2D

# Texto que aparece en los créditos, se edita desde el Inspector (cada salto de línea es una línea nueva)
@export_multiline var texto_creditos: String = "KONG VS GODZILLA\n\nUn juego creado por\n[Tu nombre aqui]\n\nProgramacion y diseño\n[Tu nombre aqui]\n\nArte y sprites\n[Autor o fuente]\n\nMusica y efectos de sonido\n[Autor o fuente]\n\nGracias por jugar"

# Fuente opcional para los créditos (por ejemplo Arcade Raiders), se arrastra desde el panel de archivos
@export var fuente: Font

# Cuánto crece un botón cuando se pasa el mouse por encima (1.06 = 6% más grande)
@export var aumento_hover: float = 1.06

# Efectos de la escena final (se pueden apagar los que no quiera)
@export_group("Efectos")
# La pantalla aparece poco a poco desde negro
@export var aparecer_desde_negro: bool = true
# Los botones aparecen uno después del otro, subiendo suavemente
@export var entrada_animada: bool = true
# Cae una lluvia suave de confeti desde arriba
@export var confeti: bool = true
# Dos cañones disparan confeti desde las esquinas de abajo (y repiten cada pocos segundos)
@export var canones_de_confeti: bool = true
# Suben brasas encendidas desde abajo (combinan con la lava)
@export var brasas: bool = true

# Botones de la escena
# Botón JUGAR DE NUEVO
var _boton_jugar: TextureButton
# Botón VER CRÉDITOS
var _boton_creditos: TextureButton

# Pantalla de créditos (se crea por código cuando se necesita)
var _creditos: CanvasLayer

# Confeti de los cañones (se vuelve a disparar cada pocos segundos)
var _confeti_canones: Array[CPUParticles2D] = []

# Tamaño original de cada botón
var _escalas: Dictionary = {}
# Animación que tiene en curso cada botón
var _animaciones: Dictionary = {}

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Por seguridad: si el juego venía en pausa o en cámara lenta, vuelve a la normalidad
	get_tree().paused = false
	# Velocidad normal del juego
	Engine.time_scale = 1.0

	# Busca el botón de jugar
	_boton_jugar = get_node_or_null("BotonJugar")
	# Busca el botón de créditos
	_boton_creditos = get_node_or_null("BotonCreditos")

	# Avisa si falta algún botón o tiene otro nombre
	if _boton_jugar == null or _boton_creditos == null:
		# Aviso en la consola
		push_warning("final.gd: faltan los nodos BotonJugar y/o BotonCreditos dentro de la escena final.")
		# Sale de la función
		return

	# Prepara el botón de jugar
	_preparar_boton(_boton_jugar)
	# Prepara el botón de créditos
	_preparar_boton(_boton_creditos)

	# Conecta el botón de jugar con su función
	_boton_jugar.pressed.connect(_jugar_de_nuevo)
	# Conecta el botón de créditos con su función
	_boton_creditos.pressed.connect(_ver_creditos)

	# Efectos visuales de la escena
	# Si el confeti está activado
	if confeti:
		# Crea la lluvia de confeti
		_crear_confeti()
	# Si los cañones están activados
	if canones_de_confeti:
		# Crea los cañones de confeti
		_crear_canones_confeti()
	# Si las brasas están activadas
	if brasas:
		# Crea las brasas
		_crear_brasas()
	# Si la entrada animada está activada
	if entrada_animada:
		# Anima la entrada de los botones
		_entrada_botones()
	# Si aparecer desde negro está activado
	if aparecer_desde_negro:
		# Hace el efecto de aparecer desde negro
		_aparecer_desde_negro()

	# Espera a que terminen las animaciones antes de activar los botones (así no se presionan sin querer)
	# Desactiva el botón de jugar
	_boton_jugar.disabled = true
	# Desactiva el botón de créditos
	_boton_creditos.disabled = true
	# Espera el tiempo de las animaciones
	await get_tree().create_timer(1.4 if entrada_animada else 0.5).timeout
	# Activa el botón de jugar
	_boton_jugar.disabled = false
	# Activa el botón de créditos
	_boton_creditos.disabled = false
	# El botón de jugar queda seleccionado
	_boton_jugar.grab_focus()

# Deja un botón listo: centro de giro, efecto al pasar el mouse y color apagado
func _preparar_boton(boton: TextureButton) -> void:
	# El efecto de crecer parte desde el centro del botón
	var minimo: Vector2 = boton.get_combined_minimum_size()
	# Calcula el centro
	var centro: Vector2 = Vector2(max(boton.size.x, minimo.x), max(boton.size.y, minimo.y)) / 2.0

	# Al mover el centro de giro, un botón con escala menor a 1 se desplazaría en pantalla
	# Se corrige la posición para que quede exactamente donde lo puse en el editor
	var encoge: Vector2 = Vector2.ONE - boton.scale
	# Calcula dónde está la esquina visible
	var esquina_visible: Vector2 = boton.position + boton.pivot_offset * encoge
	# Pone el centro de giro
	boton.pivot_offset = centro
	# Corrige la posición
	boton.position = esquina_visible - centro * encoge

	# Guarda la escala original del botón
	_escalas[boton] = boton.scale

	# Cuando no está seleccionado se ve un poco más oscuro
	boton.modulate = Color(0.85, 0.85, 0.85)

	# Al pasar el mouse, el botón queda seleccionado (así mouse y teclado funcionan igual)
	boton.mouse_entered.connect(boton.grab_focus)
	# Cuando se selecciona, se resalta
	boton.focus_entered.connect(_resaltar.bind(boton, true))
	# Cuando se deja de seleccionar, vuelve a su estado normal
	boton.focus_exited.connect(_resaltar.bind(boton, false))

# Anima el botón: crece y se ilumina cuando está seleccionado
func _resaltar(boton: TextureButton, activo: bool) -> void:
	# Si ya había una animación en curso
	if _animaciones.has(boton) and _animaciones[boton]:
		# La detiene
		_animaciones[boton].kill()

	# Escala original del botón
	var base: Vector2 = _escalas[boton]
	# Escala a la que tiene que llegar
	var destino_escala: Vector2 = base * aumento_hover if activo else base
	# Color al que tiene que llegar
	var destino_color: Color = Color.WHITE if activo else Color(0.85, 0.85, 0.85)

	# Crea un tween en paralelo
	var t := create_tween().set_parallel(true)
	# Guarda la animación del botón
	_animaciones[boton] = t
	# Anima el tamaño
	t.tween_property(boton, "scale", destino_escala, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Anima el color
	t.tween_property(boton, "modulate", destino_color, 0.12)

	# Si el botón se seleccionó
	if activo:
		# Sonido al pasar por el botón
		_sfx("boton_hover")

# JUGAR DE NUEVO: vuelve a empezar el juego desde el nivel 1
func _jugar_de_nuevo() -> void:
	# Sonido del clic
	_sfx("boton_click")
	# Quita la pausa
	get_tree().paused = false
	# Velocidad normal del juego
	Engine.time_scale = 1.0
	# Recarga la escena
	get_tree().reload_current_scene()

# VER CRÉDITOS: muestra los créditos encima de la escena
func _ver_creditos() -> void:
	# Si los créditos ya se están mostrando
	if is_instance_valid(_creditos):
		# No hace nada
		return
	# Sonido del clic
	_sfx("boton_click")

	# Esconde los dos botones mientras se ven los créditos
	_boton_jugar.hide()
	_boton_creditos.hide()

	# Crea la capa de los créditos
	_creditos = CanvasLayer.new()
	# Número de capa
	_creditos.layer = 50
	# La agrega a la escena
	add_child(_creditos)

	# Fondo oscuro
	var fondo := ColorRect.new()
	# Color del fondo
	fondo.color = Color(0, 0, 0, 0.85)
	# Ocupa toda la pantalla
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Lo agrega a la capa
	_creditos.add_child(fondo)

	# Centra el contenido en la pantalla
	var centro := CenterContainer.new()
	# Ocupa toda la pantalla
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Lo agrega a la capa
	_creditos.add_child(centro)

	# Caja vertical para el texto y el botón
	var caja := VBoxContainer.new()
	# Separación entre elementos
	caja.add_theme_constant_override("separation", 28)
	# La agrega al contenedor
	centro.add_child(caja)

	# Texto de los créditos
	var etiqueta := Label.new()
	# Pone el texto
	etiqueta.text = texto_creditos
	# Lo centra
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tamaño de la letra
	etiqueta.add_theme_font_size_override("font_size", 24)
	# Color de la letra
	etiqueta.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	# Si hay una fuente asignada
	if fuente:
		# La aplica
		etiqueta.add_theme_font_override("font", fuente)
	# Lo agrega a la caja
	caja.add_child(etiqueta)

	# Botón para volver
	var volver := Button.new()
	# Texto del botón
	volver.text = "Volver"
	# Tamaño mínimo
	volver.custom_minimum_size = Vector2(200, 54)
	# Tamaño de la letra
	volver.add_theme_font_size_override("font_size", 24)
	# Si hay una fuente asignada
	if fuente:
		# La aplica
		volver.add_theme_font_override("font", fuente)
	# Conecta el botón con la función que cierra los créditos
	volver.pressed.connect(_cerrar_creditos)
	# Lo agrega a la caja
	caja.add_child(volver)
	# Queda seleccionado
	volver.grab_focus()

# Cierra los créditos y vuelve a mostrar los botones
func _cerrar_creditos() -> void:
	# Sonido del clic
	_sfx("boton_click")
	# Si los créditos existen
	if is_instance_valid(_creditos):
		# Los elimina
		_creditos.queue_free()
	# Los borra de la variable
	_creditos = null
	# Muestra el botón de jugar
	_boton_jugar.show()
	# Muestra el botón de créditos
	_boton_creditos.show()
	# El botón de créditos queda seleccionado
	_boton_creditos.grab_focus()

# Con la tecla Escape también se cierran los créditos
func _unhandled_input(event: InputEvent) -> void:
	# Si los créditos están abiertos y se presionó Escape
	if is_instance_valid(_creditos) and event.is_action_pressed("ui_cancel"):
		# Cierra los créditos
		_cerrar_creditos()

# Reproduce un efecto de sonido solo si el Autoload Audio está registrado
func _sfx(nombre: String) -> void:
	# Busca el Autoload Audio
	var audio = get_node_or_null("/root/Audio")
	# Si existe
	if audio:
		# Reproduce el sonido
		audio.sfx(nombre)

# La pantalla empieza en negro y se aclara poco a poco
func _aparecer_desde_negro() -> void:
	# Crea la capa
	var capa := CanvasLayer.new()
	# Número de capa
	capa.layer = 90
	# La agrega a la escena
	add_child(capa)

	# Crea el rectángulo negro
	var negro := ColorRect.new()
	# Color negro
	negro.color = Color(0, 0, 0, 1)
	# Ocupa toda la pantalla
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	# No bloquea los clics
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Lo agrega a la capa
	capa.add_child(negro)

	# Crea el tween
	var t := create_tween()
	# Baja la opacidad del negro hasta que desaparece
	t.tween_property(negro, "color:a", 0.0, 1.2)
	# Al terminar, elimina la capa
	t.tween_callback(capa.queue_free)

# Los botones aparecen uno después del otro, subiendo un poco mientras se hacen visibles
func _entrada_botones() -> void:
	# Orden del botón
	var orden: int = 0
	# Recorre los dos botones
	for boton in [_boton_jugar, _boton_creditos]:
		# Guarda la posición final
		var destino: Vector2 = boton.position
		# Lo baja un poco para que luego suba
		boton.position = destino + Vector2(0, 14)
		# Empieza invisible
		boton.modulate.a = 0.0

		# Calcula el retraso según el orden
		var retraso: float = 0.7 + orden * 0.25
		# Crea un tween en paralelo
		var t := create_tween().set_parallel(true)
		# Sube el botón a su posición
		t.tween_property(boton, "position", destino, 0.45).set_delay(retraso).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Lo hace visible
		t.tween_property(boton, "modulate:a", 1.0, 0.35).set_delay(retraso)
		# Aumenta el orden
		orden += 1

# Lluvia suave de confeti (tiras, cuadritos y círculos) que cae desde arriba y se mece
func _crear_confeti() -> void:
	# Un sistema de partículas por cada forma, así se ven mezcladas
	for forma in 3:
		# Crea el sistema de partículas
		var p := _sistema_confeti(forma, 30)
		# Lo coloca arriba
		p.position = Vector2(0, -150)
		# Tiempo de vida
		p.lifetime = 7.0
		# Hace que ya haya confeti cayendo desde el primer momento
		p.preprocess = 4.0
		# Salen en una línea horizontal
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		# Ancho de la línea
		p.emission_rect_extents = Vector2(240, 4)
		# Caen hacia abajo
		p.direction = Vector2(0, 1)
		# Se abren un poco
		p.spread = 20.0
		# Gravedad
		p.gravity = Vector2(0, 45)
		# Velocidad mínima
		p.initial_velocity_min = 5.0
		# Velocidad máxima
		p.initial_velocity_max = 25.0
		# El "damping" frena la caída: el confeti flota despacio en vez de caer como piedra
		p.damping_min = 0.8
		p.damping_max = 1.4
		# Empuja de lado a los papelitos para que se muevan en curvas
		p.tangential_accel_min = -25.0
		p.tangential_accel_max = 25.0
		# Lo agrega detrás de los botones
		_agregar_detras_de_botones(p)

# Dos cañones en las esquinas de abajo que disparan confeti hacia el centro
func _crear_canones_confeti() -> void:
	# Recorre los dos lados (izquierda y derecha)
	for lado in [-1.0, 1.0]:
		# Recorre las tres formas de confeti
		for forma in 3:
			# Crea el sistema de partículas
			var p := _sistema_confeti(forma, 22)
			# Lo coloca en la esquina
			p.position = Vector2(lado * 232.0, 125.0)
			# Sale una sola vez
			p.one_shot = true
			# Salen casi todos al mismo tiempo
			p.explosiveness = 0.95
			# Tiempo de vida
			p.lifetime = 4.5
			# Sale hacia arriba y un poco hacia el centro
			p.direction = Vector2(-lado * 0.55, -1.0)
			# Se abre un poco
			p.spread = 22.0
			# Gravedad
			p.gravity = Vector2(0, 80)
			# Velocidad mínima
			p.initial_velocity_min = 170.0
			# Velocidad máxima
			p.initial_velocity_max = 280.0
			# Frenado mínimo
			p.damping_min = 1.0
			# Frenado máximo
			p.damping_max = 1.6
			# Empieza sin disparar
			p.emitting = false
			# Lo agrega detrás de los botones
			_agregar_detras_de_botones(p)
			# Lo guarda en la lista de cañones
			_confeti_canones.append(p)

	# Dispara a 1 segundo de empezar y luego cada 6 segundos
	var t := create_tween().set_loops()
	# Espera 1 segundo
	t.tween_interval(1.0)
	# Dispara los cañones
	t.tween_callback(_disparar_canones)
	# Espera 6 segundos
	t.tween_interval(6.0)

# Dispara (o vuelve a disparar) los dos cañones de confeti
func _disparar_canones() -> void:
	# Recorre las partículas de los cañones
	for p in _confeti_canones:
		# Si todavía existen
		if is_instance_valid(p):
			# Las reinicia
			p.restart()
			# Y las dispara
			p.emitting = true

# Crea un sistema de partículas de confeti de una forma (0 = tira, 1 = cuadrito, 2 = círculo)
func _sistema_confeti(forma: int, cantidad: int) -> CPUParticles2D:
	# Crea las partículas
	var p := CPUParticles2D.new()
	# Les pone la textura de la forma
	p.texture = _textura_confeti(forma)
	# Sin suavizado: se ven nítidas, como el resto del juego
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Cantidad de partículas
	p.amount = cantidad

	# Tamaños variados y cada papelito empieza girado distinto
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	p.angle_min = 0.0
	p.angle_max = 360.0
	# Velocidad de giro
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0

	# El tamaño sube y baja mientras cae: parece que el papelito se voltea en el aire
	var voltear := Curve.new()
	voltear.add_point(Vector2(0.0, 1.0))
	voltear.add_point(Vector2(0.2, 0.3))
	voltear.add_point(Vector2(0.4, 1.0))
	voltear.add_point(Vector2(0.6, 0.3))
	voltear.add_point(Vector2(0.8, 1.0))
	voltear.add_point(Vector2(1.0, 0.4))
	# Aplica la curva al tamaño
	p.scale_amount_curve = voltear

	# Cada papelito sale de uno de estos colores (los del juego: dorado, naranja, blanco, azul y rojo)
	var colores := Gradient.new()
	colores.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colores.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	colores.colors = PackedColorArray([
		Color(1.0, 0.82, 0.2),
		Color(1.0, 0.5, 0.1),
		Color(1.0, 1.0, 1.0),
		Color(0.35, 0.65, 0.95),
		Color(0.9, 0.2, 0.25)
	])
	# Aplica los colores iniciales
	p.color_initial_ramp = colores

	# Se desvanece al final de su vida
	var desvanecer := Gradient.new()
	desvanecer.offsets = PackedFloat32Array([0.0, 0.85, 1.0])
	desvanecer.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	# Aplica el degradado
	p.color_ramp = desvanecer
	# Devuelve las partículas
	return p

# Dibuja por código la imagen de un papelito (0 = tira, 1 = cuadrito, 2 = círculo)
func _textura_confeti(forma: int) -> ImageTexture:
	# Ancho de la imagen
	var ancho: int = 8 if forma == 0 else 5
	# Alto de la imagen
	var alto: int = 3 if forma == 0 else 5
	# Crea una imagen vacía
	var imagen := Image.create_empty(ancho, alto, false, Image.FORMAT_RGBA8)
	# Calcula el centro
	var centro := Vector2(ancho - 1, alto - 1) / 2.0
	# Recorre cada píxel
	for x in ancho:
		for y in alto:
			# Por defecto pinta el píxel
			var pintar: bool = true
			# Si es un círculo
			if forma == 2:
				# Solo pinta los píxeles cercanos al centro
				pintar = Vector2(x, y).distance_to(centro) <= 2.2
			# Si hay que pintar
			if pintar:
				# Pinta el píxel de blanco
				imagen.set_pixel(x, y, Color.WHITE)
	# Devuelve la textura creada
	return ImageTexture.create_from_image(imagen)

# Brasas encendidas que suben desde la lava
func _crear_brasas() -> void:
	# Crea las partículas
	var p := CPUParticles2D.new()
	# Las coloca abajo
	p.position = Vector2(0, 135)
	# Cantidad de brasas
	p.amount = 40
	# Tiempo de vida
	p.lifetime = 4.0
	# Hace que ya haya brasas desde el primer momento
	p.preprocess = 4.0
	# Salen en una línea horizontal
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	# Ancho de la línea
	p.emission_rect_extents = Vector2(235, 2)
	# Suben hacia arriba
	p.direction = Vector2(0, -1)
	# Se abren un poco
	p.spread = 25.0
	# Gravedad hacia arriba
	p.gravity = Vector2(0, -6)
	# Velocidad mínima
	p.initial_velocity_min = 10.0
	# Velocidad máxima
	p.initial_velocity_max = 28.0
	# Tamaño mínimo
	p.scale_amount_min = 1.0
	# Tamaño máximo
	p.scale_amount_max = 2.4

	# Se encienden en amarillo y se apagan en rojo transparente
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1.0, 0.75, 0.25, 1.0))
	degradado.set_color(1, Color(1.0, 0.2, 0.0, 0.0))
	# Aplica el degradado
	p.color_ramp = degradado

	# Material que suma luz para que parezcan brasas brillantes
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Aplica el material
	p.material = aditivo

	# Las agrega detrás de los botones
	_agregar_detras_de_botones(p)

# Agrega un efecto a la escena, por encima del fondo pero por debajo de los botones
func _agregar_detras_de_botones(nodo: Node) -> void:
	# Agrega el nodo a la escena
	add_child(nodo)
	# Si el botón de jugar existe
	if is_instance_valid(_boton_jugar):
		# Mueve el nodo justo detrás del botón
		move_child(nodo, _boton_jugar.get_index())
