# Primeira implementação do sistema de habilidades

Este pacote foi preparado para o repositório `LucasCruz1377/chromatic_void` e
mantém o sistema de habilidades baseado em `Resource`.

## O que esta versão adiciona

- Tela funcional para selecionar e equipar uma habilidade ativa.
- Persistência da habilidade equipada no `save.json`.
- Carregamento automático da habilidade ao iniciar uma partida.
- Uma cópia independente do `Resource` para guardar cooldown e estado da partida.
- Base de habilidade com cooldown comum.
- Aura da Serenidade.
- Foco Absoluto.
- Onda de Choque.
- Correções de compatibilidade no Retrocesso e no Hiperdash.
- Efeito de tela negativo no Retrocesso, substituindo o tremor repetitivo.
- Atordoamento básico para inimigos.
- Correção da morte do inimigo, que antes era verificada antes da subtração do dano.

## Arquivos que devem ser substituídos

Copie os arquivos mantendo exatamente os mesmos caminhos dentro do projeto:

- `Scripts/HabilidadeBase.gd`
- `Scripts/player.gd`
- `Scripts/InimigoBase.gd`
- `Scripts/InimigoSeguidor.gd`
- `Scripts/shopcontroler.gd`
- `Scripts/tela_inicial.gd`
- `Rooms/Loja.tscn`
- `Habilidades/Retrocesso.gd`
- `Habilidades/Hiperdash.gd`
- `Habilidades/Shockwave.gd`
- `Habilidades/habilidadeRetrocesso.tres`
- `Habilidades/habilidadeHiperdash.tres`
- `FX/RetrocessoTela.tscn`
- `FX/retrocesso_tela.gdshader`
- `Scripts/RetrocessoTela.gd`

## Arquivos novos

Adicione estes arquivos aos caminhos indicados:

- `Habilidades/AuraSerenidade.gd`
- `Habilidades/FocoAbsoluto.gd`
- `Habilidades/habilidadeAuraSerenidade.tres`
- `Habilidades/habilidadeFocoAbsoluto.tres`
- `Habilidades/habilidadeShockwave.tres`

## Ordem recomendada

1. Crie e entre na branch `feature/sistema-loja-habilidades`.
2. Feche o Godot para evitar que uma cena antiga seja salva por cima dos arquivos.
3. Faça uma cópia ou commit do estado atual.
4. Copie todos os arquivos deste pacote de uma vez.
5. Abra o projeto no Godot.
6. Aguarde a importação terminar.
7. Confira o painel **Debugger > Errors** antes de executar.
8. Execute a cena principal.

Não copie somente `player.gd` ou somente `HabilidadeBase.gd`: esses arquivos
formam um contrato e precisam ser atualizados juntos.

## Teste rápido obrigatório

1. Abra a tela inicial e clique em **Loja**.
2. Percorra as cinco habilidades com as setas.
3. Equipe a Aura da Serenidade.
4. Volte ao menu, inicie a partida e confira o ícone no HUD.
5. Tome dano, ative a habilidade e confirme redução de dano e regeneração.
6. Volte à loja e equipe o Foco Absoluto.
7. Confirme que os inimigos desaceleram e a nave continua manobrável.
8. Equipe a Onda de Choque e confirme dano, empurrão e atordoamento.
9. Teste também Retrocesso e Hiperdash.
10. Feche e abra o jogo para confirmar que a habilidade equipada continua salva.

## Observação de validação

Os arquivos foram revisados contra a estrutura atual do repositório e usam APIs
do Godot 4. O ambiente onde o pacote foi preparado não possui o executável do
Godot, portanto o teste final de importação e execução precisa ser feito no editor.
Se o Debugger mostrar um erro, preserve a mensagem completa e a linha indicada.
