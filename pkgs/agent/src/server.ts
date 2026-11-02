import { createServer, type Socket } from "node:net";
import { mkdir, rm, chmod } from "node:fs/promises";
import { createInterface } from "node:readline";
import { randomUUID } from "node:crypto";
import { PiRpc } from "./pi-rpc.js";
import type { InputRequest, OutputEvent } from "./protocol.js";

const env = (name: string, fallback: string): string => process.env[name] ?? fallback;

export async function serve(): Promise<void> {
  const socketPath = env("AGENT_SOCKET", `${env("XDG_RUNTIME_DIR", "/tmp")}/agent.sock`);
  const socketDir = socketPath.slice(0, socketPath.lastIndexOf("/"));
  await mkdir(socketDir, { recursive: true, mode: 0o700 });
  await rm(socketPath, { force: true });
  const server = createServer((socket) => handleClient(socket));
  server.listen(socketPath, async () => chmod(socketPath, 0o600));
  const close = async () => {
    server.close();
    await rm(socketPath, { force: true });
  };
  process.once("SIGTERM", close);
  process.once("SIGINT", close);
}

let requestQueue = Promise.resolve();

async function handleClient(socket: Socket): Promise<void> {
  socket.on("error", (error) => {
    if ((error as NodeJS.ErrnoException).code !== "ECONNRESET") console.error(error);
  });
  const lines = createInterface({ input: socket });
  try {
    for await (const line of lines) {
      let request: InputRequest;
      try {
        request = JSON.parse(line) as InputRequest;
        if (request.type !== "input" || typeof request.text !== "string") throw new Error("Invalid input request");
        const requestId = request.requestId ?? randomUUID();
        send(socket, { type: "started", requestId });
        const run = requestQueue.then(async () => {
          const session = createSession();
          try {
            const text = await session.prompt(
              request.text,
              request.images,
              (delta) => send(socket, { type: "text_delta", requestId, text: delta }),
              (name) => send(socket, { type: "tool_start", requestId, name }),
            );
            send(socket, { type: "done", requestId, text });
          } finally {
            await session.close();
          }
        });
        requestQueue = run.catch(() => undefined);
        await run;
      } catch (error) {
        send(socket, { type: "error", requestId: "unknown", message: error instanceof Error ? error.message : String(error) });
      }
    }
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ECONNRESET") console.error(error);
  } finally {
    socket.end();
  }

}

function createSession(): PiRpc {
  const prefix = env("AGENT_SESSION_ID", `agent-${env("AGENT_NAME", "default")}`);
  const runId = `${prefix}-${Date.now()}-${randomUUID().slice(0, 8)}`;
  return new PiRpc({
    command: env("AGENT_PI_COMMAND", "pi"),
    cwd: env("AGENT_CWD", process.cwd()),
    sessionDir: env("AGENT_SESSION_DIR", `${env("XDG_STATE_HOME", `${process.env.HOME}/.local/state`)}/pi/sessions`),
    provider: process.env.AGENT_PROVIDER,
    model: process.env.AGENT_MODEL,
  }, runId);
}

function send(socket: Socket, event: OutputEvent): void {
  if (!socket.destroyed) socket.write(`${JSON.stringify(event)}\n`);
}
