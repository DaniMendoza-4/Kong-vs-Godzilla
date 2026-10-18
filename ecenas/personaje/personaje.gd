# Este código controla a Kong: sus movimientos, saltos, vida, daño y muerte
# También permite comer aves para recuperar vida y detecta los peligros del nivel
# Hereda de CharacterBody2D para tener físicas de personaje 2D (movimiento, gravedad y colisiones)
extends CharacterBody2D

# Señal que avisa cuando Kong muere para reiniciar el nivel
signal personaje_muerto

# Referencia a la animación de Kong desde el editor
@export var animacion: AnimatedSprite2D

# Área que detecta cuando Kong toca pinchos, bolas de fuego y aves
@export var area_2D: Area2D

# Nombre de la animación de victoria, la que hace Kong cuando se gana el juego
# Si no existe con este nombre, se busca otra que tenga "victor", "gana", "celebr" o "win"
@export var anim_victoria: StringName = &"victoria"

# Tiempo que tiene que pasar para que los pinchos vuelvan a quitar vida
const TIEMPO_ENTRE_PINCHAZOS: float = 1.0

# Velocidad de movimiento horizontal
var _velocidad_movimiento: float = 100.0

# Fuerza del salto (negativa porque en 2D el eje Y va hacia abajo)
var _volocidad_salto: float = -300.0

# Guarda si Kong está muerto o vivo
var _muerto: bool

# Tiempo que dura la animación de daño leve
var _tiempo_daño: float = 0.0

# Tiempo que se muestra la animación de comer un ave
var _tiempo_comer: float = 0.0

# Indica si Kong está tocando los pinchos
var _en_pinchos: bool = false

# Tiempo que falta para recibir otro daño de los pinchos
var _espera_pinchos: float = 0.0

# Distancia a la que llega el golpe de Kong (hacia el frente)
const ALCANCE_ATAQUE: float = 22.0

# Segundos que tiene que esperar Kong entre un golpe y otro
const TIEMPO_ENTRE_ATAQUES: float = 0.5

# Tiempo que se muestra la animación de ataque
var _tiempo_ataque: float = 0.0

# Tiempo que falta para poder volver a atacar
var _espera_ataque: float = 0.0

# Segundos que Kong no puede recibir daño después de ser golpeado, mientras tanto parpadea
const TIEMPO_INVULNERABLE: float = 0.8

# Tiempo que le falta a Kong para volver a poder recibir daño
var _invulnerable: float = 0.0

# Indica si Kong está celebrando la victoria (no se mueve ni recibe daño)
var _celebrando: bool = false

# Referencia al nodo que controla la vida de Kong
@onready var vida: Node = $"vida-kong"

# Se ejecuta una sola vez al iniciar el nodo
func _ready() -> void:
	# Agrega a Kong a los grupos "personaje" y "jugador" para identificarlo desde otros nodos
	add_to_group("personaje")
	add_to_group("jugador")

	# Hace que la animación de muerte se reproduzca una sola vez
	animacion.sprite_frames.set_animation_loop("daño-muerte", false)

	# Si existe la animación de ataque
	if animacion.sprite_frames.has_animation("atacar"):
		# Hace que se reproduzca una sola vez
		animacion.sprite_frames.set_animation_loop("atacar", false)

	# Conecta la señal de vida en cero con la función de morir
	vida.kong_muerto.connect(_morir)

	# Si el área está asignada, la configura
	if area_2D:
		# Agrega el área a los mismos grupos
		area_2D.add_to_group("personaje")
		area_2D.add_to_group("jugador")

		# Detecta cuando Kong entra a los pinchos
		area_2D.body_entered.connect(_tocar_pinchos)
		# Y cuando sale de ellos
		area_2D.body_exited.connect(_salir_de_pinchos)

		# Detecta cuando Kong toca una bola o un ave
		area_2D.area_entered.connect(_tocar_area)

# Se ejecuta en cada frame de física
func _physics_process(delta: float) -> void:
	# Si Kong murió, deja de ejecutar sus movimientos
	if _muerto:
		# Sale de la función
		return

	# Mientras celebra la victoria se queda quieto en el suelo y no cambia su animación
	if _celebrando:
		# No se mueve en horizontal
		velocity.x = 0.0
		# Le aplica la gravedad
		velocity += get_gravity() * delta
		# Aplica el movimiento
		move_and_slide()
		# Sale de la función
		return

	# Mientras Kong es invulnerable, su dibujo parpadea (se vuelve transparente y normal)
	if _invulnerable > 0.0:
		# Reduce el tiempo de invulnerabilidad
		_invulnerable -= delta
		# Cambia la transparencia del dibujo para que parpadee
		animacion.self_modulate.a = 0.35 if int(_invulnerable * 16.0) % 2 == 0 else 1.0
		# Cuando termina la invulnerabilidad
		if _invulnerable <= 0.0:
			# El dibujo vuelve a ser normal
			animacion.self_modulate.a = 1.0

	# Reduce el tiempo de espera entre ataques
	if _espera_ataque > 0.0:
		# Resta el tiempo
		_espera_ataque -= delta

	# Reduce el tiempo de espera entre daños de los pinchos
	if _espera_pinchos > 0.0:
		# Resta el tiempo
		_espera_pinchos -= delta

	# Si Kong sigue encima de los pinchos y ya pasó el tiempo, vuelve a recibir daño
	if _en_pinchos and _espera_pinchos <= 0.0:
		# Aplica el daño de los pinchos
		_pinchazo()

		# Si Kong murió por los pinchos
		if _muerto:
			# Termina la función
			return

	# Asigna gravedad al personaje
	velocity += get_gravity() * delta

	# Salta si se presiona la tecla de aceptar y está en el suelo
	if Input.is_action_just_pressed("ui_accept") && is_on_floor():
		# Le da la fuerza del salto
		velocity.y = _volocidad_salto
		# Sonido del salto
		Audio.sfx("salto")

	# Detecta si se mantiene presionada la tecla derecha (ui_right)
	if Input.is_action_pressed("ui_right"):
		# Mueve a Kong a la derecha
		velocity.x = _velocidad_movimiento
		# Voltea su dibujo
		animacion.flip_h = false

	# Detecta si se mantiene presionada la tecla izquierda (ui_left)
	elif Input.is_action_pressed("ui_left"):
		# Mueve a Kong a la izquierda
		velocity.x = -_velocidad_movimiento
		# Voltea su dibujo
		animacion.flip_h = true

	# Si no se presiona ninguna tecla de movimiento
	else:
		# Kong deja de moverse en horizontal
		velocity.x = 0

	# Aplica el movimiento y maneja las colisiones automáticamente
	move_and_slide()

	# Animaciones del personaje
	# Si Kong acaba de recibir daño, muestra la animación de daño leve
	if _tiempo_daño > 0.0:
		# Resta el tiempo de la animación
		_tiempo_daño -= delta
		# Reproduce la animación
		animacion.play("daño-leve")

	# Si está comiendo un ave, muestra esa animación
	elif _tiempo_comer > 0.0:
		# Resta el tiempo de la animación
		_tiempo_comer -= delta
		# Reproduce la animación
		animacion.play("comer-ave")

	# Si Kong está atacando, muestra la animación de ataque
	elif _tiempo_ataque > 0.0:
		# Resta el tiempo de la animación
		_tiempo_ataque -= delta
		# Reproduce la animación
		animacion.play("atacar")

	# Si está en el aire, animación de saltar
	elif !is_on_floor():
		# Reproduce la animación
		animacion.play("salto")

	# Si se está moviendo, animación de correr
	elif velocity.x != 0:
		# Reproduce la animación
		animacion.play("correr")

	# Si no se mueve, animación de inactividad
	else:
		# Reproduce la animación
		animacion.play("inactividad")

# Función que se ejecuta cuando Kong recibe daño leve de una bola
func recibir_daño_leve() -> void:
	# No recibe daño si ya murió, si acaba de ser golpeado o si está celebrando
	if _muerto or _invulnerable > 0.0 or _celebrando:
		# Sale de la función
		return

	# Reduce la vida de Kong
	vida.daño_bola_leve()

	# Sonido de dolor de Kong
	Audio.sfx("kong_daño")

	# Si el daño hizo que Kong muriera
	if _muerto:
		# Termina la función
		return

	# Kong queda protegido un momento después del golpe
	_invulnerable = TIEMPO_INVULNERABLE

	# Cancela la animación de comer para darle prioridad al daño
	_tiempo_comer = 0.0

	# Obtiene los fotogramas de la animación
	var frames := animacion.sprite_frames
	# Calcula cuánto dura la animación de daño leve
	_tiempo_daño = frames.get_frame_count("daño-leve") / frames.get_animation_speed("daño-leve")

	# Inicia la animación de daño
	animacion.play("daño-leve")

	# Muestra en la consola la vida que le queda a Kong
	print("¡Kong recibió daño leve! Vida: ", vida.vida_actual)

# Función que se ejecuta cuando Kong toca una bola que provoca la muerte
func recibir_daño_muerte() -> void:
	# Si Kong ya murió
	if _muerto:
		# No hace nada
		return

	# Muestra un mensaje en la consola
	print("¡Kong recibió daño mortal!")

	# Aplica el daño mortal
	vida.daño_mortal()

# Función que permite que Kong recupere vida al comer un ave
func recibir_cura(_cantidad: float = 25.0) -> void:
	# Si Kong ya murió
	if _muerto:
		# No recupera vida
		return

	# Recupera vida mediante el sistema de vida
	vida.comer_ave()

	# Sonido de comer
	Audio.sfx("comer")

	# Muestra en la consola la vida actual
	print("¡Kong comió un ave! Vida: ", vida.vida_actual)

	# Kong parpadea en verde para indicar que recuperó vida
	_destello(Color(0.4, 1.0, 0.5))

	# Si existe la animación de comer un ave
	if animacion.sprite_frames.has_animation("comer-ave"):
		# Cancela el tiempo de daño para mostrar la animación de curación
		_tiempo_daño = 0.0

		# Calcula cuánto se muestra la animación de comer
		_tiempo_comer = _duracion_animacion("comer-ave")

		# Inicia la animación desde el primer fotograma
		animacion.play("comer-ave")
		# Pone el fotograma en 0
		animacion.frame = 0

# Función que calcula cuánto dura una animación completa
func _duracion_animacion(nombre: StringName) -> float:
	# Obtiene los fotogramas de la animación
	var frames := animacion.sprite_frames

	# Guarda la duración total
	var total := 0.0

	# Recorre cada fotograma
	for i in frames.get_frame_count(nombre):
		# Suma la duración de cada uno
		total += frames.get_frame_duration(nombre, i)

	# Devuelve la duración total teniendo en cuenta la velocidad de la animación
	return total / frames.get_animation_speed(nombre)

# Función que revisa si Kong necesita recuperar vida
func necesita_vida() -> bool:
	# Devuelve verdadero si tiene menos vida que su máximo
	return vida.vida_actual < vida.vida_maxima

# Función que se ejecuta cuando Kong toca los pinchos
func _pinchazo() -> void:
	# Los pinchos no dependen de la invulnerabilidad de otros golpes, solo se evitan mientras Kong celebra la victoria
	if _celebrando:
		# Sale de la función
		return

	# Establece el tiempo que tiene que pasar antes del siguiente daño
	_espera_pinchos = TIEMPO_ENTRE_PINCHAZOS

	# Reduce la vida de Kong por tocar los pinchos
	vida.daño_pinchos()

	# Sonido de los pinchos
	Audio.sfx("pinchos")

	# Muestra en la consola la vida que le queda
	print("¡Kong tocó los pinchos! Vida: ", vida.vida_actual)

	# Si Kong sigue vivo
	if not _muerto:
		# Cambia su color a rojo un momento
		_destello(Color(18.892, 0.0, 0.0, 1.0))

# Función que cambia el color de Kong un momento y luego lo devuelve a la normalidad
func _destello(color: Color) -> void:
	# Aplica el color indicado al dibujo
	animacion.modulate = color

	# Hace que el color vuelva poco a poco al blanco
	create_tween().tween_property(animacion, "modulate", Color.WHITE, 0.4)

# Función que se ejecuta cuando la vida de Kong llega a cero
func _morir() -> void:
	# Evita ejecutar la muerte más de una vez
	if _muerto:
		# Sale de la función
		return

	# Marca a Kong como muerto
	_muerto = true

	# Devuelve el color del dibujo a la normalidad
	animacion.modulate = Color.WHITE
	# Quita la transparencia
	animacion.self_modulate.a = 1.0

	# Reproduce la animación de muerte
	animacion.play("daño-muerte")

	# Sonido de muerte
	Audio.sfx("kong_muerte")

	# Espera un segundo para que se vea la animación
	await get_tree().create_timer(1.0).timeout

	# Avisa a la escena principal para reiniciar el nivel
	personaje_muerto.emit()

# Función que indica que Kong acaba de tocar los pinchos
func _tocar_pinchos(_body: Node2D) -> void:
	# Marca que está en los pinchos
	_en_pinchos = true

# Función que indica que Kong ya salió de los pinchos
func _salir_de_pinchos(_body: Node2D) -> void:
	# Marca que ya no está en los pinchos
	_en_pinchos = false

# Función que detecta cuando Kong toca una bola o un ave
func _tocar_area(area: Area2D) -> void:
	# Si el objeto tiene la función impactar, la ejecuta y le pasa a Kong
	if area.has_method("impactar"):
		# Ejecuta impactar
		area.impactar(self)

# Función que permite provocar la muerte de Kong desde otro código
func morir() -> void:
	# Aplica el daño mortal para activar el sistema de muerte
	recibir_daño_muerte()

# Detecta la tecla de ataque (Z o X)
func _unhandled_input(event: InputEvent) -> void:
	# Si se presionó una tecla y no es una repetición
	if event is InputEventKey and event.pressed and not event.echo:
		# Si es la Z o la X
		if event.keycode == KEY_Z or event.keycode == KEY_X:
			# Ataca
			_atacar()

# Función que hace que Kong golpee hacia donde está mirando
func _atacar() -> void:
	# No puede atacar si murió, si está celebrando o si todavía está descansando del último golpe
	if _muerto or _celebrando or _espera_ataque > 0.0:
		# Sale de la función
		return

	# Reinicia el tiempo de espera para atacar
	_espera_ataque = TIEMPO_ENTRE_ATAQUES

	# Si existe la animación de ataque, la reproduce
	if animacion.sprite_frames.has_animation("atacar"):
		# Cancela el tiempo de daño
		_tiempo_daño = 0.0
		# Cancela el tiempo de comer
		_tiempo_comer = 0.0
		# Calcula cuánto dura la animación de ataque
		_tiempo_ataque = _duracion_animacion("atacar")
		# Reproduce la animación
		animacion.play("atacar")
		# Empieza desde el primer fotograma
		animacion.frame = 0
	# Si no existe, Kong solo parpadea
	else:
		# Parpadeo amarillo
		_destello(Color(1.0, 1.0, 0.5))

	# Sonido del puñetazo
	Audio.sfx("golpe_aire")

	# Revisa si algún Godzilla está enfrente de Kong y a su alcance
	for g in get_tree().get_nodes_in_group("godzilla"):
		# Distancia horizontal hasta Godzilla
		var dx: float = g.global_position.x - global_position.x
		# Indica si Godzilla está del lado hacia donde mira Kong
		var enfrente: bool = (dx > 0.0 and not animacion.flip_h) or (dx < 0.0 and animacion.flip_h)
		# Si está enfrente y a su alcance
		if enfrente and g.esta_en_alcance(global_position, ALCANCE_ATAQUE):
			# Godzilla recibe el golpe
			g.recibir_golpe()
			# Sonido del impacto
			Audio.sfx("impacto_kong")
			# Hace temblar la cámara
			Audio.sacudir_camara(1.5, 0.12)

# Función que se ejecuta cuando Godzilla golpea a Kong
func recibir_golpe_godzilla(cantidad: float = 20.0) -> void:
	# Evita recibir daño si ya murió, si acaba de ser golpeado o si está celebrando
	if _muerto or _invulnerable > 0.0 or _celebrando:
		# Sale de la función
		return

	# Resta la vida, si llega a cero se activa la muerte
	vida.recibir_daño(cantidad)
	# Sonido de dolor
	Audio.sfx("kong_daño")
	# Si murió
	if _muerto:
		# Termina la función
		return

	# Kong queda protegido un momento después del golpe
	_invulnerable = TIEMPO_INVULNERABLE

	# Cancela la animación de comer
	_tiempo_comer = 0.0
	# Cancela la animación de ataque
	_tiempo_ataque = 0.0
	# Obtiene los fotogramas de la animación
	var frames := animacion.sprite_frames
	# Calcula cuánto dura la animación de daño leve
	_tiempo_daño = frames.get_frame_count("daño-leve") / frames.get_animation_speed("daño-leve")
	# Reproduce la animación de daño
	animacion.play("daño-leve")
	# Parpadeo rojo
	_destello(Color(1.0, 0.2, 0.2))

# Kong celebra la victoria: deja de moverse y repite su animación de victoria
func celebrar() -> void:
	# Si ya murió o ya está celebrando, no hace nada
	if _muerto or _celebrando:
		return
	# Marca que está celebrando
	_celebrando = true

	# Deja de parpadear y cancela cualquier animación o ataque a medias
	_invulnerable = 0.0
	# Quita la transparencia
	animacion.self_modulate.a = 1.0
	# Devuelve el color a la normalidad
	animacion.modulate = Color.WHITE
	# Cancela el ataque
	_tiempo_ataque = 0.0
	# Cancela la animación de comer
	_tiempo_comer = 0.0
	# Detiene el movimiento horizontal
	velocity.x = 0.0

	# Busca la animación de victoria
	var nombre: StringName = _buscar_animacion_victoria()
	# Si no la encuentra
	if nombre == &"":
		# Avisa en la consola
		push_warning("Kong: no se encontro la animacion de victoria. Revisa el nombre en Anim Victoria.")
		# Termina la función
		return

	# La animación se repite mientras dura la celebración
	animacion.sprite_frames.set_animation_loop(nombre, true)
	# Reproduce la animación
	animacion.play(nombre)

# Busca la animación de victoria: primero por su nombre exacto y luego por parecido
func _buscar_animacion_victoria() -> StringName:
	# Obtiene los fotogramas
	var frames: SpriteFrames = animacion.sprite_frames
	# Si no hay fotogramas
	if frames == null:
		# Devuelve vacío
		return &""
	# Si existe la animación con el nombre exacto
	if frames.has_animation(anim_victoria):
		# La devuelve
		return anim_victoria
	# Si no, recorre todas las animaciones
	for nombre in frames.get_animation_names():
		# Pasa el nombre a minúsculas
		var minusculas: String = String(nombre).to_lower()
		# Si el nombre se parece a victoria
		if minusculas.contains("victor") or minusculas.contains("gana") or minusculas.contains("celebr") or minusculas.contains("win"):
			# Devuelve ese nombre
			return StringName(nombre)
	# Si no encontró ninguna, devuelve vacío
	return &""
