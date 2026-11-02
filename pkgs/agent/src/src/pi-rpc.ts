import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { createInterface } from "node:readline";
import type { Image } from "./protocol.js";

type RpcEvent = Record<string, unknown>;
type Pending = { resolve: (value: RpcEvent) => void; reject: (error: Error) => void };

type PiConfig = {
  command: string;
  cwd: string;
  sessionDir: string;
  provider?: string;
  model?: string;
};

export class PiRpc {
  private process?: ChildProcessWithoutNullStreams;
  private pending = new Map<string, Pending>();
  private events: RpcEvent[] = [];
  private waiters: Array<(event: RpcEvent) => void> = [];
  private nextId = 1;

  public constructor(private readonly config: PiConfig, private readonly session?: string) {}

  public async start(): Promise<void> {
    if (this.process) return;
    const args = ["--mode", "rpc", "--session-dir", this.config.sessionDir];
    if (this.session) args.push("--session", this.session);
    if (this.config.provider) args.push("--provider", this.config.provider);
    if (this.config.model) args.push("--model", this.config.model);
    this.process = spawn(this.config.command, args, {
      cwd: this.config.cwd,
      stdio: ["pipe", "pipe", "pipe"],
    });
    const lines = createInterface({ input: this.process.stdout });
    lines.on("line", (line) => this.receive(line));
    this.process.stderr.on("data", (data) => process.stderr.write(`[pi] ${data}`));
    this.process.on("exit", (code) => {
      const error = new Error(`Pi exited with code ${code ?? "unknown"}`);
      for (const pending of this.pending.values()) pending.reject(error);
      this.pending.clear();
      this.process = undefined;
    });
    await this.request({ type: "get_state" });
  }

  private receive(line: string): void {
    let event: RpcEvent;
    try {
      event = JSON.parse(line) as RpcEvent;
    } catch {
      return;
    }
    if (event.type === "response" && typeof event.id === "string") {
      const pending = this.pending.get(event.id);
      if (!pending) return;
      this.pending.delete(event.id);
      if (event.success === false) pending.reject(new Error(String(event.error ?? "Pi RPC failed")));
      else pending.resolve(event);
      return;
    }
    const waiter = this.waiters.shift();
    if (waiter) waiter(event);
    else this.events.push(event);
  }

  private async request(payload: Record<string, unknown>): Promise<RpcEvent> {
    await this.startWithoutState();
    const process = this.process;
    if (!process) throw new Error("Pi is not running");
    const id = `agent-${this.nextId++}`;
    const promise = new Promise<RpcEvent>((resolve, reject) => this.pending.set(id, { resolve, reject }));
    process.stdin.write(`${JSON.stringify({ ...payload, id })}\n`);
    return promise;
  }

  private async startWithoutState(): Promise<void> {
    if (this.process) return;
    const args = ["--mode", "rpc", "--session-dir", this.config.sessionDir];
    if (this.session) args.push("--session", this.session);
    if (this.config.provider) args.push("--provider", this.config.provider);
    if (this.config.model) args.push("--model", this.config.model);
    this.process = spawn(this.config.command, args, { cwd: this.config.cwd, stdio: ["pipe", "pipe", "pipe"] });
    const lines = createInterface({ input: this.process.stdout });
    lines.on("line", (line) => this.receive(line));
    this.process.stderr.on("data", (data) => process.stderr.write(`[pi] ${data}`));
  }

  private nextEvent(): Promise<RpcEvent> {
    const event = this.events.shift();
    if (event) return Promise.resolve(event);
    return new Promise((resolve) => this.waiters.push(resolve));
  }

  public async prompt(text: string, images?: Image[], onDelta?: (text: string) => void): Promise<string> {
    await this.startWithoutState();
    const requestId = `agent-${this.nextId++}`;
    const payload: Record<string, unknown> = { type: "prompt", id: requestId, message: text };
    if (images?.length) payload.images = images;
    const response = new Promise<RpcEvent>((resolve, reject) => this.pending.set(requestId, { resolve, reject }));
    this.process!.stdin.write(`${JSON.stringify(payload)}\n`);
    await response;
    let answer = "";
    while (true) {
      const event = await this.nextEvent();
      if (event.type === "message_update") {
        const update = event.assistantMessageEvent as { type?: string; delta?: string } | undefined;
        if (update?.type === "text_delta" && update.delta) {
          answer += update.delta;
          onDelta?.(update.delta);
        }
      } else if (event.type === "message_end") {
        const message = event.message as { role?: string; content?: unknown } | undefined;
        if (message?.role === "assistant" && typeof message.content === "string") answer = message.content;
      } else if (event.type === "agent_settled") {
        return answer;
      }
    }
  }
}
