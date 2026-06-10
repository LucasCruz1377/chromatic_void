extends Node

var Camera : Camera2D

func shake(forca : float , duracao: float):
	if Camera:
		Camera.shake(forca,duracao)
