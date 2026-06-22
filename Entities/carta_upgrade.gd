extends Panel


signal clicou(tipo)

var tipo_upgrade

@onready var nome = $Nome
@onready var descricao = $Descricao
@onready var botao = $Botao

func configurar_carta(tipo,nome_chave,descricao_chave):
	tipo_upgrade = tipo
	nome.text = nome_chave
	descricao.text = descricao_chave
	


func _on_button_pressed():
	clicou.emit(tipo_upgrade)
