import { Bot, type Context } from "grammy";
import { chmod, mkdir, rm } from "node:fs/promises";
import { connect, createServer, type Socket } from "node:net";
import { createInterface } from "node:readline";
import { randomInt, randomUUID } from "node:crypto";

const token = process.env.TELEGRAM_BOT_TOKEN;
const socketPath = process.env.TELEGRAM_AGENT_SOCKET ?? `${process.env.XDG_RUNTIME_DIR ?? "/tmp"}/agents/gaia/gaia.sock`;
const controlSocketPath = process.env.TELEGRAM_CONTROL_SOCKET ?? `${process.env.XDG_RUNTIME_DIR ?? "/tmp"}/agents/telegram/telegram.sock`;
const allowedUserId = Number(process.env.TELEGRAM_ALLOWED_USER_ID ?? "0");
if (!token || !allowedUserId) throw new Error("TELEGRAM_BOT_TOKEN and TELEGRAM_ALLOWED_USER_ID are required");

const bot = new Bot(token);
const authorized = (ctx: Context) => ctx.from?.id === allowedUserId && ctx.chat?.type === "private";
const chunks = (text: string, limit = 3900): string[] => {
  const result: string[] = [];
  while (text.length > limit) {
    const split = text.lastIndexOf("\n", limit);
    const at = split > limit / 2 ? split : limit;
    result.push(text.slice(0, at));
    text = text.slice(at).replace(/^\n+/, "");
  }
  result.push(text || "(no response)");
  return result;
};

function telegramHtml(markdown: string): string {
  const blocks: string[] = [];
  const escaped = markdown
    .replace(/```(?:[a-zA-Z0-9_+-]+)?\n?([\s\S]*?)```/g, (_, code: string) => {
      blocks.push(`<pre>${code.trimEnd().replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")}</pre>`);
      return `\u0000${blocks.length - 1}\u0000`;
    })
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/^#{1,6}\s+(.+)$/gm, "<b>$1</b>")
    .replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2">$1</a>')
    .replace(/`([^`\n]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*\n]+)\*\*/g, "<b>$1</b>")
    .replace(/(?<!\w)\*([^*\n]+)\*(?!\w)/g, "<i>$1</i>")
    .replace(/^\s*[-*]\s+/gm, "• ")
    .replace(/\u0000(\d+)\u0000/g, (_, index: string) => blocks[Number(index)]);
  return escaped;
}

type Event = { type: string; text?: string; message?: string; name?: string };
type Image = { type: "image"; data: string; mimeType: string };

function input(text: string, images?: Image[]): AsyncGenerator<Event> {
  const socket: Socket = connect(socketPath);
  const lines = createInterface({ input: socket });
  const requestId = randomUUID();
  socket.write(`${JSON.stringify({ type: "input", requestId, conversation: `telegram:${allowedUserId}`, text, images })}\n`);
  return (async function* () {
    try {
      for await (const line of lines) {
        const event = JSON.parse(line) as Event;
        yield event;
        if (event.type === "done" || event.type === "error") return;
      }
    } finally {
      socket.end();
    }
  })();
}

async function withTyping<T>(ctx: Context, task: () => Promise<T>): Promise<T> {
  await ctx.replyWithChatAction("typing");
  const heartbeat = setInterval(() => {
    void ctx.replyWithChatAction("typing").catch(() => undefined);
  }, 4000);
  try {
    return await task();
  } finally {
    clearInterval(heartbeat);
  }
}

async function replyWithStream(ctx: Context, text: string, images?: Image[]): Promise<void> {
  let finalText: string | undefined;
  let statusBuffer = "";
  let currentStatus = "";
  let statusQueue = Promise.resolve();
  const draftId = randomInt(1, 2 ** 31 - 1);
  let lastUpdate = 0;
  let draftsDisabled = false;
  const render = () => currentStatus.slice(0, 4096);
  const enqueueStatus = (status: string) => {
    const text = status.trim();
    if (!text) return;
    statusQueue = statusQueue.then(async () => {
      currentStatus = text;
      await update(true);
      await new Promise((resolve) => setTimeout(resolve, 1200));
    });
  };
  const collectStatuses = (text: string) => {
    statusBuffer += text;
    const marker = /\[\[draft\]\]([\s\S]*?)\[\[\/draft\]\]/g;
    let match: RegExpExecArray | null;
    let consumed = 0;
    while ((match = marker.exec(statusBuffer))) {
      enqueueStatus(match[1]);
      consumed = marker.lastIndex;
    }
    if (consumed) statusBuffer = statusBuffer.slice(consumed);
  };
  const update = async (force = false) => {
    if (draftsDisabled) return;
    const rendered = render();
    if (!rendered || (!force && Date.now() - lastUpdate <= 1200)) return;
    const delay = Math.max(0, 1000 - (Date.now() - lastUpdate));
    if (delay) await new Promise((resolve) => setTimeout(resolve, delay));
    try {
      await ctx.api.sendMessageDraft(ctx.chat!.id, draftId, rendered);
      lastUpdate = Date.now();
    } catch (error) {
      draftsDisabled = true;
      console.error("Telegram draft streaming failed; sending final reply", error);
    }
  };

  for await (const event of input(text, images)) {
    if (event.type === "text_delta") collectStatuses(event.text ?? "");
    if (event.type === "error") throw new Error(event.message ?? "GAIA request failed");
    if (event.type === "done") finalText = event.text;
  }

  await statusQueue;
  const result = (finalText ?? "(no response)")
    .replace(/\[\[draft\]\][\s\S]*?\[\[\/draft\]\]/g, "")
    .trim();
  const html = telegramHtml(result);
  if (html.length <= 4096) await ctx.reply(html, { parse_mode: "HTML" });
  else for (const chunk of chunks(result)) await ctx.reply(chunk);
}

async function startControlSocket(): Promise<void> {
  await mkdir(controlSocketPath.slice(0, controlSocketPath.lastIndexOf("/")), { recursive: true, mode: 0o700 });
  await rm(controlSocketPath, { force: true });
  const server = createServer((socket) => {
    const lines = createInterface({ input: socket });
    lines.on("line", async (line) => {
      let request: { type?: string; requestId?: string; conversation?: string; text?: string } = {};
      try {
        request = JSON.parse(line) as typeof request;
        if (request.type !== "send" || !request.requestId || !request.conversation || typeof request.text !== "string") throw new Error("Invalid Telegram send request");
        const [transport, chatId] = request.conversation.split(":", 2);
        if (transport !== "telegram" || !chatId || !/^\d+$/.test(chatId)) throw new Error("Invalid Telegram conversation");
        await bot.api.sendMessage(Number(chatId), request.text);
        socket.end(`${JSON.stringify({ type: "sent", requestId: request.requestId })}\n`);
      } catch (error) {
        socket.end(`${JSON.stringify({ type: "error", requestId: request.requestId ?? "unknown", message: error instanceof Error ? error.message : String(error) })}\n`);
      }
    });
    socket.on("error", () => undefined);
  });
  server.listen(controlSocketPath, async () => chmod(controlSocketPath, 0o600));
}

await startControlSocket();

bot.on("message:text", async (ctx) => {
  if (!authorized(ctx)) return;
  await withTyping(ctx, () => replyWithStream(ctx, ctx.message.text));
});

bot.on("message:photo", async (ctx) => {
  if (!authorized(ctx)) return;
  const photo = ctx.message.photo.at(-1);
  if (!photo) return;
  const file = await ctx.getFile();
  const response = await fetch(`https://api.telegram.org/file/bot${token}/${file.file_path}`);
  const data = Buffer.from(await response.arrayBuffer()).toString("base64");
  await withTyping(ctx, () => replyWithStream(ctx, ctx.message.caption ?? "An image was attached. Respond naturally based on it and the conversation.", [
    { type: "image", data, mimeType: "image/jpeg" },
  ]));
});

await bot.start();
