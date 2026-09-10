# Laboratório de testes

O laboratório existe somente quando `Global.modo_desenvolvedor` está ativo.
Durante uma partida, abra-o com **F10** ou pressionando **L3 + R3** ao mesmo
tempo. A navegação e a confirmação dos botões funcionam pelo controle.

## Ferramentas disponíveis

- conceder 1 ponto de melhoria;
- subir 1 ou 5 níveis imediatamente;
- restaurar toda a vida;
- alternar invulnerabilidade de desenvolvimento;
- pausar os spawns automáticos;
- limpar inimigos, bosses e projéteis hostis da arena;
- reiniciar a partida atual;
- invocar qualquer boss implementado em dificuldade inicial.

Bosses invocados pelo laboratório não concluem setores, não avançam o próximo
encontro e não alteram a progressão normal da partida.

## Segurança das builds

Não é necessário alterar uma constante antes de publicar. A permissão é
calculada automaticamente: o laboratório funciona somente dentro do editor do
Godot. Exportações Release e Debug não criam o indicador, o atalho nem o painel,
e também não liberam cristais ou habilidades da loja.

O workflow de Release usa explicitamente `export_debug: false`.
