import os
import sys
import time
import shutil
import zipfile
import subprocess
import tempfile


def log(mensagem):
    print("[Updater]", mensagem, flush=True)


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
    if len(sys.argv) < 5:
        log("Argumentos insuficientes.")
        log("Uso:")
        log("Updater.exe --worker <zip> <pasta_do_jogo> <executavel>")
        return 1

    zip_path = os.path.abspath(sys.argv[2])
    game_dir = os.path.abspath(sys.argv[3])
    game_exe = os.path.abspath(sys.argv[4])

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

    temp_dir = os.path.join(game_dir, "_update_temp")

    try:
        # Limpa atualização anterior, caso tenha sobrado alguma coisa.
        if os.path.exists(temp_dir):
            log("Removendo atualização temporária anterior...")
            shutil.rmtree(temp_dir, ignore_errors=True)

        os.makedirs(temp_dir)

        # ----------------------------------------
        # 1. Extrair atualização
        # ----------------------------------------

        log("Extraindo atualização...")

        with zipfile.ZipFile(zip_path, "r") as arquivo_zip:
            arquivo_zip.extractall(temp_dir)

        log("Atualização extraída.")

        # ----------------------------------------
        # 2. Esperar o jogo fechar
        # ----------------------------------------

        log("Esperando o jogo fechar...")

        for tentativa in range(30):
            try:
                with open(game_exe, "a"):
                    pass

                log("Jogo fechado.")
                break

            except PermissionError:
                log(
                    "Jogo ainda está aberto. "
                    f"Tentativa {tentativa + 1}/30..."
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

                log("Atualizando: " + os.path.relpath(
                    destino_arquivo,
                    game_dir
                ))

                shutil.copy2(
                    origem,
                    destino_arquivo
                )

        log("Arquivos atualizados.")

        # ----------------------------------------
        # 4. Limpar arquivos temporários
        # ----------------------------------------

        shutil.rmtree(
            temp_dir,
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
        return 1


def main():
    # O primeiro processo apenas cria uma cópia temporária.
    if len(sys.argv) < 2 or sys.argv[1] != "--worker":
        return iniciar_worker()

    # A cópia temporária executa a atualização.
    return executar_worker()


if __name__ == "__main__":
    sys.exit(main())