extends Panel


signal clicou(tipo)

var tipo_upgrade

@onready var nome = $Nome
@onready var descricao = $Descricao
@onready var botao = $Botao
@onready var icone = $Icone

func configurar_carta(tipo,nome_chave,descricao_chave, icone_text):
	tipo_upgrade = tipo
	nome.text = nome_chave
	descricao.text = descricao_chave
	icone.texture = load(icone_text)


func _on_button_pressed():
	clicou.emit(tipo_upgrade)
