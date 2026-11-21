"""Executa quatro peers e rejeita erros de replicacao, mesmo com exit code zero."""
from pathlib import Path
import os
import re
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
ERRORS = re.compile(r"(?:SCRIPT )?ERROR:|ObjectDB instances were leaked at exit")


def main():
    processes = []
    failed = False
    with tempfile.TemporaryDirectory(prefix="cv-lifecycle-") as temporary:
        folder = Path(temporary)
        try:
            for role in ("host", "client_a", "client_b", "client_c"):
                env = os.environ.copy()
                env["XDG_DATA_HOME"] = str(folder / role)
                with (folder / f"{role}.log").open("w") as log:
                    process = subprocess.Popen(
                        ["godot", "--headless", "--verbose", "--audio-driver", "Dummy", "--path", str(ROOT),
                         "Tests/lifecycle_peer_integration.tscn", "--", f"--lifecycle-role={role}"],
                        cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT,
                    )
                processes.append((role, process))
                time.sleep(0.5 if role == "host" else 0.15)
            for role, process in processes:
                try:
                    status = process.wait(timeout=45)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                    status = -1
                output = (folder / f"{role}.log").read_text()
                peer_failed = status != 0 or bool(ERRORS.search(output)) or "TESTE OK:" not in output
                if not peer_failed:
                    output = "\n".join(line for line in output.splitlines() if any(
                        term in line.lower() for term in ("teste ok:", "error:", "warning:", "leaked instance", "resource still in use")
                    ))
                print(f"{role}: exit={status}\n{output}", flush=True)
                failed |= peer_failed
        finally:
            for _, process in processes:
                if process.poll() is None:
                    process.kill()
                    process.wait()
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
