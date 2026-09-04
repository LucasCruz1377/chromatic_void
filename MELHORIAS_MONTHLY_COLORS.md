# Monthly Colors — conquistas e equipamentos

Esta versão adiciona 50 opções permanentes à loja sem alterar sua estrutura de
quatro abas:

- 15 poderes ativos;
- 13 estilos de arma;
- 10 módulos de nave;
- 12 mutações para a habilidade ativa.

Somente um item de cada aba pode ficar equipado. Compras normais usam cristais;
itens inspirados em padrões dos bosses são recompensas de conquistas e não podem
ser comprados.

## Conquistas

O progresso fica no mesmo `save.json` já usado pelo jogo. Saves antigos são
migrados automaticamente.

- abates totais: 1, 10, 50, 250 e 1.000;
- derrota individual de PET-0, Florecimento, Sentinela Dourada, Ruptura Lilás e
  Sizígia Eterna;
- derrota de 1, 3 e 5 bosses diferentes;
- conclusão de uma partida com os cinco setores.

Ao desbloquear uma conquista, um aviso animado aparece no canto superior. A loja
mostra a condição e o progresso nos itens ainda bloqueados.

## Efeitos e desempenho

Ataques de grande impacto usam partículas geométricas, anéis neon, vibração e
tremor de câmera proporcional. No celular a quantidade das novas partículas é
automaticamente reduzida. Scanners e verificações de quase-colisão são
executados em intervalos curtos, não a cada quadro.

## Compatibilidade de save

As chaves antigas `habilidade_equipada` e `habilidades_desbloqueadas` foram
preservadas. As novas chaves são aditivas:

- `kills_totais`;
- `bosses_derrotados`;
- `jogos_zerados`;
- `conquistas_desbloqueadas`;
- `itens_desbloqueados`;
- `equipamentos_loja`.
