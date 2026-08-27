# CI/CD do Chromatic Void

Este projeto usa GitHub Actions para validar o jogo, gerar builds e publicar versões.

## O que inicia cada automação

| Gatilho | Validação e smoke tests | Builds Windows/Web | GitHub Release |
| --- | --- | --- | --- |
| Push em qualquer branch | Sim | Somente na `main` | Não |
| Pull Request para `main` | Sim | Sim | Não |
| Segunda-feira às 09:00 (Brasília) | Sim | Sim | Não |
| Execução manual do CI | Sim | Opcional | Não |
| Tag `v*` | Sim | Sim | Sim |
| Execução manual do CD | Sim | Sim | Sim, para uma tag existente |

## O que o CI verifica

1. Confirma que o projeto usa e abre no Godot 4.7.
2. Procura referências literais `res://` que apontem para arquivos ausentes.
3. Importa todo o projeto em modo headless.
4. Executa automaticamente todas as cenas `Tests/*_smoke.tscn`.
5. Em `main`, PRs, execução semanal ou execução manual autorizada, exporta Windows e Web separadamente.
6. Guarda cada build como artefato por sete dias.

Se Windows falhar e Web funcionar, as duas tarefas aparecem separadas na aba **Actions**.

## Tags e tipos de Release

Formatos aceitos:

- `v0.6.0-alpha.1`: teste inicial, criado como prerelease.
- `v0.6.0-beta.1`: beta, criado como prerelease.
- `v0.6.0-rc.1`: candidato a lançamento, criado como prerelease.
- `v0.6.0`: versão estável, marcada como Latest.

O CD gera notas automaticamente, anexa os dois builds e cria `SHA256SUMS.txt` para conferir a integridade dos arquivos.

### Criar e enviar uma versão

No terminal, dentro do projeto:

```bash
git switch main
git pull
git tag -a v0.6.0-beta.1 -m "Chromatic Void v0.6.0 beta 1"
git push origin v0.6.0-beta.1
```

O último comando é o gatilho do CD. Não é necessário criar uma tag em todo commit.

## Executar manualmente

1. Abra o repositório no GitHub.
2. Entre em **Actions**.
3. Escolha **CI - Validar Chromatic Void** para testar uma branch.
4. Clique em **Run workflow** e escolha se deseja gerar builds.

Para refazer a publicação de uma tag existente, escolha **CD - Publicar Chromatic Void**, informe a tag e execute. Uma Release já existente com a mesma tag não será sobrescrita automaticamente.

## Proteger a main

Esta configuração depende do GitHub e não fica dentro do código:

1. Abra **Settings > Rules > Rulesets**.
2. Crie uma regra para a branch `main`.
3. Ative a exigência de status checks antes de alterações entrarem na branch.
4. Selecione **Importar e executar smoke tests**.
5. Opcionalmente exija também **Exportar Windows** e **Exportar Web**.

Para um projeto individual, a validação e os smoke tests devem ser obrigatórios. Os builds podem continuar opcionais para não bloquear correções por falhas temporárias de download.

## Rodar verificações localmente

Com Godot 4.7 disponível no terminal:

```bash
python3 Tests/validar_referencias.py
godot --headless --audio-driver Dummy --path . --import --quit
godot --headless --audio-driver Dummy --path . res://Tests/interface_smoke.tscn
```

No Windows, os testes também podem ser abertos diretamente no editor e executados com **F6**.
