# Pequeñas herramientas de efectos visuales que usan varios scripts (brillos y chispas)
# No hay que agregarla a ninguna escena
# Le da nombre de clase para poder usarla desde cualquier script
class_name Efectos
# Hereda de RefCounted porque no es un nodo, solo guarda funciones
extends RefCounted

# Crea un degradado de un color a otro, sirve para que las partículas se desvanezcan
static func rampa(color_inicio: Color, color_final: Color) -> Gradient:
	# Crea el degradado
	var g := Gradient.new()
	# Color con el que empieza
	g.set_color(0, color_inicio)
	# Color con el que termina
	g.set_color(1, color_final)
	# Devuelve el degradado
	return g

# Crea una textura de brillo suave, un círculo que se difumina hacia afuera
static func textura_brillo() -> GradientTexture2D:
	# Crea el degradado
	var g := Gradient.new()
	# Centro blanco
	g.set_color(0, Color(1, 1, 1, 1))
	# Borde transparente
	g.set_color(1, Color(1, 1, 1, 0))
	# Punto intermedio para que el brillo sea más suave
	g.add_point(0.45, Color(1, 1, 1, 0.45))

	# Crea la textura a partir del degradado
	var t := GradientTexture2D.new()
	# Le asigna el degradado
	t.gradient = g
	# Hace que el degradado sea circular
	t.fill = GradientTexture2D.FILL_RADIAL
	# El círculo empieza en el centro
	t.fill_from = Vector2(0.5, 0.5)
	# Y termina en el borde de arriba
	t.fill_to = Vector2(0.5, 0.0)
	# Ancho de la textura
	t.width = 64
	# Alto de la textura
	t.height = 64
	# Devuelve la textura
	return t

# Material que suma la luz, hace que los brillos se vean como luz y no como manchas
static func material_aditivo() -> CanvasItemMaterial:
	# Crea el material
	var m := CanvasItemMaterial.new()
	# Le pone el modo aditivo
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Devuelve el material
	return m

# Lanza una explosión de chispas en una posición y se borra sola
static func chispas(padre: Node, posicion_global: Vector2, color_inicio: Color, color_final: Color, cantidad: int = 24, velocidad_max: float = 90.0, duracion: float = 0.5) -> void:
	# Crea las partículas
	var p := CPUParticles2D.new()
	# Les pone el material que suma luz
	p.material = material_aditivo()
	# Les pone la textura de brillo
	p.texture = textura_brillo()
	# Las partículas salen una sola vez
	p.one_shot = true
	# Salen todas al mismo tiempo
	p.explosiveness = 1.0
	# Cantidad de chispas
	p.amount = cantidad
	# Tiempo de vida de cada chispa
	p.lifetime = duracion
	# Las chispas salen hacia arriba
	p.direction = Vector2.UP
	# Y se abren en todas direcciones
	p.spread = 180.0
	# Gravedad que las hace caer
	p.gravity = Vector2(0, 120)
	# Velocidad mínima de las chispas
	p.initial_velocity_min = velocidad_max * 0.4
	# Velocidad máxima de las chispas
	p.initial_velocity_max = velocidad_max
	# Tamaño mínimo
	p.scale_amount_min = 0.08
	# Tamaño máximo
	p.scale_amount_max = 0.22
	# Color con el que empiezan y terminan
	p.color_ramp = rampa(color_inicio, color_final)
	# Agrega las partículas al nodo padre
	padre.add_child(p)
	# Las coloca en la posición indicada
	p.global_position = posicion_global
	# Empieza a lanzar las chispas
	p.emitting = true
	# Cuando pasa el tiempo, borra las partículas
	p.get_tree().create_timer(duracion + 0.3).timeout.connect(p.queue_free)
