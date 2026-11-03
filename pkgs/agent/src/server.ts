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

const IDLE_TIMEOUT_MS = Number.parseInt(process.env.AGENT_IDLE_TIMEOUT_MS ?? "300000", 10);
if (!Number.isFinite(IDLE_TIMEOUT_MS) || IDLE_TIMEOUT_MS <= 0) throw new Error("AGENT_IDLE_TIMEOUT_MS must be a positive integer");

type ActiveSession = {
  session: PiRpc;
  lastInputAt: number;
  busy: boolean;
};

let activeSession: ActiveSession | undefined;
let idleTimer: ReturnType<typeof setTimeout> | undefined;
let requestQueue = Promise.resolve();

function scheduleIdleClose(): void {
  if (idleTimer) clearTimeout(idleTimer);
  if (!activeSession || activeSession.busy) return;
  const session = activeSession;
  const delay = Math.max(0, IDLE_TIMEOUT_MS - (Date.now() - session.lastInputAt));
  idleTimer = setTimeout(() => {
    if (activeSession !== session || session.busy) return;
    activeSession = undefined;
    idleTimer = undefined;
    void session.session.close().catch((error) => console.error("Failed to close idle session", error));
  }, delay);
}

function touchActiveSession(receivedAt: number): void {
  if (!activeSession) return;
  activeSession.lastInputAt = receivedAt;
  if (idleTimer) {
    clearTimeout(idleTimer);
    idleTimer = undefined;
  }
}

function sessionForInput(receivedAt: number): ActiveSession {
  if (!activeSession) {
    activeSession = { session: createSession(), lastInputAt: receivedAt, busy: false };
  } else {
    touchActiveSession(receivedAt);
  }
  return activeSession;
}

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
        const receivedAt = Date.now();
        touchActiveSession(receivedAt);
        send(socket, { type: "started", requestId });
        const run = requestQueue.then(async () => {
          const active = sessionForInput(receivedAt);
          active.busy = true;
          try {
            const text = await active.session.prompt(
              request.text,
              request.images,
              (delta) => send(socket, { type: "text_delta", requestId, text: delta }),
              (name) => send(socket, { type: "tool_start", requestId, name }),
            );
            send(socket, { type: "done", requestId, text });
          } catch (error) {
            if (activeSession === active) {
              activeSession = undefined;
              await active.session.close();
            }
            throw error;
          } finally {
            if (activeSession === active) {
              active.busy = false;
              scheduleIdleClose();
            }
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
