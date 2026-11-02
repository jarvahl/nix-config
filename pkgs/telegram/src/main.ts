import { Bot, type Context } from "grammy";
import { connect, type Socket } from "node:net";
import { createInterface } from "node:readline";
import { randomUUID } from "node:crypto";

const token = process.env.TELEGRAM_BOT_TOKEN;
const socketPath = process.env.TELEGRAM_AGENT_SOCKET ?? `${process.env.XDG_RUNTIME_DIR ?? "/tmp"}/agents/gaia.sock`;
const allowedUserId = Number(process.env.TELEGRAM_ALLOWED_USER_ID ?? "0");
if (!token || !allowedUserId) throw new Error("TELEGRAM_BOT_TOKEN and TELEGRAM_ALLOWED_USER_ID are required");

const bot = new Bot(token);
const authorized = (ctx: Context) => ctx.from?.id === allowedUserId && ctx.chat?.type === "private";

type Event = { type: string; text?: string; message?: string };
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
  let output = "";
  let messageId: number | undefined;
  let lastEdit = 0;
  for await (const event of input(text, images)) {
      if (event.type === "text_delta") output += event.text ?? "";
      if (event.type === "error") throw new Error(event.message ?? "GAIA request failed");
      if (output && Date.now() - lastEdit > 700) {
        if (messageId === undefined) {
          messageId = (await ctx.reply(output.slice(0, 4096))).message_id;
        } else {
          await ctx.api.editMessageText(ctx.chat!.id, messageId, output.slice(0, 4096));
        }
        lastEdit = Date.now();
      }
      if (event.type === "done") output = event.text ?? output;
    }
    const finalText = (output || "(no response)").slice(0, 4096);
    if (messageId === undefined) {
      await ctx.reply(finalText);
    } else {
      await ctx.api.editMessageText(ctx.chat!.id, messageId, finalText);
    }
}

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
