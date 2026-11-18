"""Execute depois de godot --headless --editor --import."""
import asyncio
import os
from pathlib import Path
import random
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]


class Relay(asyncio.DatagramProtocol):
    def __init__(self):
        self.random = random.Random(1377)
        self.client = None
        self.resume = 0.0

    def connection_made(self, transport):
        self.transport = transport

    def datagram_received(self, data, sender):
        if sender[1] == 24567:
            destination = self.client
        else:
            self.client = sender
            destination = ("127.0.0.1", 24567)
        loop = asyncio.get_running_loop()
        if destination and loop.time() >= self.resume and self.random.random() >= 0.02:
            loop.call_later(0.035, self.transport.sendto, data, destination)


async def main():
    with tempfile.TemporaryDirectory() as temporary:
        folder = Path(temporary)
        client = folder / "client"
        shutil.copytree(ROOT, client, ignore=shutil.ignore_patterns(".git"))
        manager = client / "Scripts/GerenciadorMultiplayer.gd"
        source = manager.read_text()
        assert source.count("create_client(host, PORTA)") == 1
        manager.write_text(source.replace("create_client(host, PORTA)", "create_client(host, 24667)"))
        loop = asyncio.get_running_loop()
        relay = Relay()
        transport, _ = await loop.create_datagram_endpoint(lambda: relay, local_addr=("127.0.0.1", 24667))
        processes = []

        async def run(role, project):
            process = await asyncio.create_subprocess_exec(
                "godot", "--headless", "Tests/lobby_peer_integration.tscn", "--",
                "--lobby-role=" + role, "--boss-only", cwd=project,
                env=dict(os.environ, XDG_DATA_HOME=str(folder / ("data-" + role))),
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT,
            )
            processes.append(process)
            ok = False
            error = False
            async for line in process.stdout:
                message = line.decode(errors="replace").strip()
                print(role, message, flush=True)
                if role == "client" and message == "Amparo amostra 4":
                    relay.resume = loop.time() + 0.35
                if role == "client" and message == "Amparo amostra 5" and relay.resume:
                    print("Movimento observado após reabertura (ms):", round(1000 * (loop.time() - relay.resume)))
                ok |= message == "CHEFES " + role + " true"
                error |= "ERROR:" in message and "resources still in use at exit" not in message
            return await process.wait() == 0 and ok and not error

        try:
            results = await asyncio.wait_for(asyncio.gather(run("host", ROOT), run("client", client)), 70)
            return all(results) and relay.resume > 0
        finally:
            transport.close()
            for process in processes:
                if process.returncode is None:
                    process.kill()
                    await process.wait()


if __name__ == "__main__":
    raise SystemExit(0 if asyncio.run(main()) else 1)
