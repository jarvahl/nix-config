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
  const sessions = new Map<string, PiRpc>();
  const server = createServer((socket) => handleClient(socket, sessions));
  server.listen(socketPath, async () => chmod(socketPath, 0o600));
  const close = async () => {
    server.close();
    await rm(socketPath, { force: true });
  };
  process.once("SIGTERM", close);
  process.once("SIGINT", close);
}

async function handleClient(socket: Socket, sessions: Map<string, PiRpc>): Promise<void> {
  const lines = createInterface({ input: socket });
  for await (const line of lines) {
    let request: InputRequest;
    try {
      request = JSON.parse(line) as InputRequest;
      if (request.type !== "input" || typeof request.text !== "string") throw new Error("Invalid input request");
      const requestId = request.requestId ?? randomUUID();
      const conversation = request.conversation ?? "default";
      const session = sessions.get(conversation) ?? createSession();
      sessions.set(conversation, session);
      send(socket, { type: "started", requestId });
      const text = await session.prompt(request.text, request.images, (delta) => send(socket, { type: "text_delta", requestId, text: delta }));
      send(socket, { type: "done", requestId, text });
    } catch (error) {
      send(socket, { type: "error", requestId: "unknown", message: error instanceof Error ? error.message : String(error) });
    }
  }
  socket.end();

  function createSession(): PiRpc {
    return new PiRpc({
      command: env("AGENT_PI_COMMAND", "pi"),
      cwd: env("AGENT_CWD", process.cwd()),
      sessionDir: env("AGENT_SESSION_DIR", `${env("XDG_STATE_HOME", `${process.env.HOME}/.local/state`)}/pi/sessions`),
      provider: process.env.AGENT_PROVIDER,
      model: process.env.AGENT_MODEL,
    });
  }
}

function send(socket: Socket, event: OutputEvent): void {
  if (!socket.destroyed) socket.write(`${JSON.stringify(event)}\n`);
}
