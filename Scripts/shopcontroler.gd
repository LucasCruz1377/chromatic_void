extends Control


const CAMINHOS_HABILIDADES: Array[String] = [
	"res://Habilidades/habilidadeRetrocesso.tres",
	"res://Habilidades/habilidadeHiperdash.tres",
	"res://Habilidades/habilidadeAuraSerenidade.tres",
	"res://Habilidades/habilidadeFocoAbsoluto.tres",
	"res://Habilidades/habilidadeShockwave.tres"
]


@onready var icone: TextureRect = $Margem/Coluna/Conteudo/Cartao/ColunaCartao/Icone
@onready var nome: Label = $Margem/Coluna/Conteudo/Cartao/ColunaCartao/Nome
@onready var descricao: Label = $Margem/Coluna/Conteudo/Cartao/ColunaCartao/Descricao
@onready var cooldown: Label = $Margem/Coluna/Conteudo/Cartao/ColunaCartao/Cooldown
@onready var estado: Label = $Margem/Coluna/Conteudo/Cartao/ColunaCartao/Estado
@onready var botao_equipar: Button = $Margem/Coluna/Conteudo/Cartao/ColunaCartao/Equipar

var habilidades: Array[Habilidade] = []
var desbloqueadas: Array[String] = []
var indice_atual := 0
var caminho_equipado := ""


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	carregar_catalogo()
	carregar_estado()
	atualizar_cartao()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			mudar_habilidade(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			mudar_habilidade(1)
			get_viewport().set_input_as_handled()


func carregar_catalogo() -> void:
	habilidades.clear()

	for caminho in CAMINHOS_HABILIDADES:
		if not ResourceLoader.exists(caminho):
			push_warning("Habilidade não encontrada: " + caminho)
			continue

		var recurso := load(caminho)
		if recurso is Habilidade:
			habilidades.append(recurso)
		else:
			push_warning("O arquivo não é uma Habilidade: " + caminho)


func carregar_estado() -> void:
	var dados := GerenciadorDeSave.carregar()
	caminho_equipado = str(
		dados.get(
			"habilidade_equipada",
			"res://Habilidades/habilidadeRetrocesso.tres"
		)
	)

	desbloqueadas.clear()
	var salvas = dados.get("habilidades_desbloqueadas", CAMINHOS_HABILIDADES)

	if salvas is Array:
		for valor in salvas:
			if valor is String:
				desbloqueadas.append(valor)

	if desbloqueadas.is_empty():
		desbloqueadas.assign(CAMINHOS_HABILIDADES)

	for indice in range(habilidades.size()):
		if habilidades[indice].resource_path == caminho_equipado:
			indice_atual = indice
			break


func atualizar_cartao() -> void:
	if habilidades.is_empty():
		nome.text = "Nenhuma habilidade encontrada"
		descricao.text = "Confira os caminhos configurados em shopcontroler.gd."
		cooldown.text = ""
		estado.text = "ERRO DE CATÁLOGO"
		icone.texture = null
		botao_equipar.disabled = true
		return

	var habilidade := habilidades[indice_atual]
	var caminho := habilidade.resource_path
	var desbloqueada := caminho in desbloqueadas
	var equipada := caminho == caminho_equipado

	icone.texture = habilidade.Icone
	nome.text = habilidade.Nome
	descricao.text = habilidade.Descricao
	cooldown.text = "RECARGA: %.1f s" % habilidade.Cooldown

	if not desbloqueada:
		estado.text = "BLOQUEADA"
		botao_equipar.text = "BLOQUEADA"
		botao_equipar.disabled = true
	elif equipada:
		estado.text = "HABILIDADE ATUAL"
		botao_equipar.text = "EQUIPADA"
		botao_equipar.disabled = true
	else:
		estado.text = "DESBLOQUEADA"
		botao_equipar.text = "EQUIPAR"
		botao_equipar.disabled = false


func mudar_habilidade(direcao: int) -> void:
	if habilidades.is_empty():
		return

	indice_atual = wrapi(indice_atual + direcao, 0, habilidades.size())
	atualizar_cartao()


func _on_left_pressed() -> void:
	mudar_habilidade(-1)


func _on_right_pressed() -> void:
	mudar_habilidade(1)


func _on_equipar_pressed() -> void:
	if habilidades.is_empty():
		return

	var habilidade := habilidades[indice_atual]
	var caminho := habilidade.resource_path

	if caminho not in desbloqueadas:
		return

	caminho_equipado = caminho
	GerenciadorDeSave.salvar({
		"habilidade_equipada": caminho_equipado,
		"habilidades_desbloqueadas": desbloqueadas
	})

	atualizar_cartao()


func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")
