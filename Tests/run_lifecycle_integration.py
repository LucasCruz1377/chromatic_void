"""Executa tres peers e rejeita erros de replicacao, mesmo com exit code zero."""
from pathlib import Path
import os
import re
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
ERRORS = re.compile(r"SCRIPT ERROR:|ERROR: (?:Can't find overlapping|Condition.*recv_nodes|Ignoring delta|Node not found|Failed to get cached node)")


def main():
    processes = []
    failed = False
    with tempfile.TemporaryDirectory(prefix="cv-lifecycle-") as temporary:
        folder = Path(temporary)
        try:
            for role in ("host", "client_a", "client_b"):
                env = os.environ.copy()
                env["XDG_DATA_HOME"] = str(folder / role)
                with (folder / f"{role}.log").open("w") as log:
                    process = subprocess.Popen(
                        ["godot", "--headless", "--audio-driver", "Dummy", "--path", str(ROOT),
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
                print(f"{role}: exit={status}\n{output}", flush=True)
                failed |= status != 0 or bool(ERRORS.search(output)) or "TESTE OK:" not in output
        finally:
            for _, process in processes:
                if process.poll() is None:
                    process.kill()
                    process.wait()
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
