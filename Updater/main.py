import os
import sys
import time
import shutil
import zipfile
import subprocess
import tempfile


def log(mensagem):
    print("[Updater]", mensagem, flush=True)


def processo_existe(pid):
    """Retorna True enquanto o processo do jogo ainda estiver ativo."""
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def extrair_zip_seguro(zip_path, destino):
    """Extrai o pacote recusando caminhos que escapem da pasta temporária."""
    destino_real = os.path.realpath(destino)

    with zipfile.ZipFile(zip_path, "r") as arquivo_zip:
        for membro in arquivo_zip.infolist():
            caminho = os.path.realpath(os.path.join(destino, membro.filename))
            if os.path.commonpath([destino_real, caminho]) != destino_real:
                raise RuntimeError(
                    "O pacote contém um caminho inseguro: " + membro.filename
                )

        arquivo_zip.extractall(destino)


def iniciar_worker():
    """Copia o próprio Updater para uma pasta temporária e executa a cópia."""
    executavel_atual = os.path.abspath(sys.executable)

    pasta_temp = tempfile.mkdtemp(prefix="chromatic_void_updater_")
    updater_temp = os.path.join(pasta_temp, "Updater.exe")

    log("Preparando atualizador temporário...")
    log("Origem: " + executavel_atual)
    log("Destino: " + updater_temp)

    shutil.copy2(executavel_atual, updater_temp)

    argumentos = [updater_temp, "--worker"] + sys.argv[1:]

    subprocess.Popen(
        argumentos,
        cwd=pasta_temp,
        creationflags=subprocess.CREATE_NEW_PROCESS_GROUP
    )

    log("Atualizador temporário iniciado.")
    return 0


def executar_worker():
    if len(sys.argv) < 6:
        log("Argumentos insuficientes.")
        log("Uso:")
        log("Updater.exe --worker <zip> <pasta_do_jogo> <executavel> <pid>")
        return 1

    zip_path = os.path.abspath(sys.argv[2])
    game_dir = os.path.abspath(sys.argv[3])
    game_exe = os.path.abspath(sys.argv[4])
    game_pid = int(sys.argv[5])

    log("========================================")
    log("ATUALIZADOR")
    log("========================================")
    log("ZIP: " + zip_path)
    log("Pasta do jogo: " + game_dir)
    log("Executável: " + game_exe)
    log("========================================")

    if not os.path.isfile(zip_path):
        log("ERRO: ZIP não encontrado.")
        return 1

    if not os.path.isdir(game_dir):
        log("ERRO: pasta do jogo não encontrada.")
        return 1

    if os.path.commonpath([game_dir, game_exe]) != game_dir:
        log("ERRO: executável fora da pasta do jogo.")
        return 1

    temp_dir = os.path.join(game_dir, "_update_temp")
    backup_dir = os.path.join(game_dir, "_update_backup")
    arquivos_novos = []
    arquivos_substituidos = []

    try:
        # Limpa atualização anterior, caso tenha sobrado alguma coisa.
        if os.path.exists(temp_dir):
            log("Removendo atualização temporária anterior...")
            shutil.rmtree(temp_dir, ignore_errors=True)

        if os.path.exists(backup_dir):
            shutil.rmtree(backup_dir, ignore_errors=True)

        os.makedirs(temp_dir)
        os.makedirs(backup_dir)

        # ----------------------------------------
        # 1. Extrair atualização
        # ----------------------------------------

        log("Extraindo atualização...")

        extrair_zip_seguro(zip_path, temp_dir)

        executavel_novo = os.path.join(temp_dir, os.path.basename(game_exe))
        if not os.path.isfile(executavel_novo):
            raise RuntimeError(
                "O pacote não contém " + os.path.basename(game_exe) + "."
            )

        log("Atualização extraída.")

        # ----------------------------------------
        # 2. Esperar o jogo fechar
        # ----------------------------------------

        log("Esperando o jogo fechar...")

        for tentativa in range(60):
            if not processo_existe(game_pid):
                log("Jogo fechado.")
                break

            log(
                "Jogo ainda está aberto. "
                f"Tentativa {tentativa + 1}/60..."
            )
            time.sleep(1)

        else:
            log("ERRO: o jogo não fechou dentro do tempo esperado.")
            return 1

        # ----------------------------------------
        # 3. Copiar arquivos da atualização
        # ----------------------------------------

        log("Copiando arquivos novos...")

        for raiz, diretorios, arquivos in os.walk(temp_dir):
            caminho_relativo = os.path.relpath(raiz, temp_dir)

            if caminho_relativo == ".":
                destino = game_dir
            else:
                destino = os.path.join(
                    game_dir,
                    caminho_relativo
                )

            os.makedirs(destino, exist_ok=True)

            for arquivo in arquivos:
                origem = os.path.join(raiz, arquivo)
                destino_arquivo = os.path.join(destino, arquivo)
                relativo_arquivo = os.path.relpath(destino_arquivo, game_dir)

                log("Atualizando: " + os.path.relpath(
                    destino_arquivo,
                    game_dir
                ))

                if os.path.isfile(destino_arquivo):
                    backup_arquivo = os.path.join(backup_dir, relativo_arquivo)
                    os.makedirs(os.path.dirname(backup_arquivo), exist_ok=True)
                    shutil.copy2(destino_arquivo, backup_arquivo)
                    arquivos_substituidos.append((backup_arquivo, destino_arquivo))
                else:
                    arquivos_novos.append(destino_arquivo)

                temporario_destino = destino_arquivo + ".update-new"
                shutil.copy2(origem, temporario_destino)
                os.replace(temporario_destino, destino_arquivo)

        log("Arquivos atualizados.")

        # ----------------------------------------
        # 4. Limpar arquivos temporários
        # ----------------------------------------

        shutil.rmtree(
            temp_dir,
            ignore_errors=True
        )
        shutil.rmtree(
            backup_dir,
            ignore_errors=True
        )

        try:
            os.remove(zip_path)
            log("ZIP temporário removido.")
        except OSError:
            pass

        # ----------------------------------------
        # 5. Iniciar nova versão
        # ----------------------------------------

        log("Abrindo nova versão...")

        subprocess.Popen(
            [game_exe],
            cwd=game_dir
        )

        log("========================================")
        log("ATUALIZAÇÃO CONCLUÍDA")
        log("========================================")

        return 0

    except Exception as erro:
        log("========================================")
        log("ERRO DURANTE A ATUALIZAÇÃO")
        log("========================================")
        log(str(erro))

        log("Restaurando a instalação anterior...")
        for arquivo_novo in reversed(arquivos_novos):
            try:
                if os.path.isfile(arquivo_novo):
                    os.remove(arquivo_novo)
            except OSError:
                pass

        for backup_arquivo, destino_arquivo in reversed(arquivos_substituidos):
            try:
                os.makedirs(os.path.dirname(destino_arquivo), exist_ok=True)
                shutil.copy2(backup_arquivo, destino_arquivo)
            except OSError as erro_rollback:
                log("Falha ao restaurar " + destino_arquivo + ": " + str(erro_rollback))

        shutil.rmtree(temp_dir, ignore_errors=True)
        shutil.rmtree(backup_dir, ignore_errors=True)
        return 1


def main():
    # O primeiro processo apenas cria uma cópia temporária.
    if len(sys.argv) < 2 or sys.argv[1] != "--worker":
        return iniciar_worker()

    # A cópia temporária executa a atualização.
    return executar_worker()


if __name__ == "__main__":
    sys.exit(main())
