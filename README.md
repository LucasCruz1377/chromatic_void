# Atualização visual do Retrocesso

Extraia este pacote na raiz do projeto depois de instalar a primeira versão do
sistema de habilidades.

Arquivos substituídos:

- `Habilidades/Retrocesso.gd`
- `Habilidades/habilidadeRetrocesso.tres`

Arquivos novos:

- `FX/RetrocessoTela.tscn`
- `FX/retrocesso_tela.gdshader`
- `Scripts/RetrocessoTela.gd`

O tremor repetitivo durante o rewind foi removido. No lugar, a habilidade usa
um `CanvasLayer` com negativo, separação cromática, scanlines e vinheta. Existe
apenas um pulso pequeno de câmera quando o Retrocesso termina.

