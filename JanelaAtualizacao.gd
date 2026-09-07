extends CanvasLayer

@onready var titulo: Label = $PanelContainer/VBoxContainer/Titulo
@onready var mensagem: Label = $PanelContainer/VBoxContainer/Mensagem
@onready var versao_atual: Label = $PanelContainer/VBoxContainer/VersaoAtual
@onready var nova_versao: Label = $PanelContainer/VBoxContainer/NovaVersao
@onready var botao_atualizar: Button = $PanelContainer/VBoxContainer/HBoxContainer/BotaoAtualizar
@onready var botao_mais_tarde: Button = $PanelContainer/VBoxContainer/HBoxContainer/BotaoMaisTarde


func _ready() -> void:
	hide()

	UpdateManager.update_available.connect(_mostrar_atualizacao)

	botao_atualizar.pressed.connect(_clicou_atualizar)
	botao_mais_tarde.pressed.connect(_clicou_mais_tarde)

	UpdateManager.verificar_atualizacao()

func _mostrar_atualizacao(version: String) -> void:
	versao_atual.text = "Versão atual: " + UpdateManager.current_version
	nova_versao.text = "Nova versão: " + version

	show()


func _clicou_atualizar() -> void:
	print("Usuário escolheu atualizar para: ", UpdateManager.latest_version)

	botao_atualizar.disabled = true
	botao_mais_tarde.disabled = true

	UpdateManager.baixar_atualizacao_windows()

func _clicou_mais_tarde() -> void:
	hide()
