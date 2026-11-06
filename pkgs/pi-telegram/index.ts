import { autoRetry } from "@grammyjs/auto-retry";
import { hydrateFiles } from "@grammyjs/files";
import { mdgram } from "@borodin/mdgram";
import { fileTypeFromBuffer } from "file-type";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Bot, InputFile } from "grammy";
import { filter, join, last, map, pipe } from "remeda";
import { createReadStream } from "node:fs";
import { mkdir, readFile, realpath, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, extname, join as joinPath } from "node:path";
import { randomUUID } from "node:crypto";

const instructions = `For Telegram, keep preview updates to one or two useful sentences. Use telegram_update_preview to share a concise answer or meaningful progress for the current stage; do not send empty status updates or private reasoning. When a stage is complete, use telegram_send_message to send its short, standalone result. Finish with an overall conclusion of at most three sentences, without repeating earlier stage messages. Do not split simple tasks into artificial stages. In private chats, normally send plain messages; set reply=true on telegram_send_message or telegram_attach only when a reply bubble genuinely helps anchor the message to a specific earlier item.`;

export const renderMarkdownForTelegram = (markdown: string, convert = mdgram) =>
  pipe(markdown, (text) => text.trim(), convert);

export const extractMessageText = (message: any) => pipe(
  message.content ?? [],
  filter((part: any) => part.type === "text"),
  map((part: any) => part.text),
  join(""),
);

export const extractFinalAssistantText = (messages: any[]) => pipe(
  messages,
  filter((message: any) => message.role === "assistant"),
  last(),
  (message) => message ? extractMessageText(message) : "",
);

export const buildTelegramPrompt = (body: string, reply?: string, attachmentPath?: string) => {
  const context = reply ? `Replying to Telegram message:\n> ${reply}\n\n${body}` : body;
  return attachmentPath ? `${context}\n\nTelegram attachment saved at: ${attachmentPath}` : context;
};

export const detectMimeType = async (bytes: Uint8Array, detect = fileTypeFromBuffer) =>
  (await detect(bytes))?.mime ?? "application/octet-stream";

export const isInlineImage = (mimeType: string) => mimeType.startsWith("image/");

const waitHumanizedSendDelay = () => new Promise((resolve) =>
  setTimeout(resolve, 1000 + Math.floor(Math.random() * 2001)),
);

type QueuedTelegramMessage = {
  chatId: number;
  replyTo: number;
  prompt: string;
  images: { type: "image"; data: string; mimeType: string }[];
};

type Dependencies = {
  createBot: (token: string) => any;
  createInputFile: (stream: NodeJS.ReadableStream, fileName: string) => any;
  createRetryTransformer: () => any;
  createFileDownloader: (token: string) => any;
  detectFileType: (bytes: Uint8Array) => Promise<{ mime?: string } | undefined>;
  markdownToHtml: (markdown: string) => string;
  waitBeforeSend: () => Promise<void>;
  Type: any;
};

const defaultDependencies: Omit<Dependencies, "Type"> = {
  createBot: (token) => new Bot(token),
  createInputFile: (stream, fileName) => new InputFile(stream as any, fileName),
  createRetryTransformer: () => autoRetry(),
  createFileDownloader: (token) => hydrateFiles(token),
  detectFileType: fileTypeFromBuffer,
  markdownToHtml: mdgram,
  waitBeforeSend: waitHumanizedSendDelay,
};

const toTelegramHtml = (markdown: string, dependencies: Dependencies) =>
  renderMarkdownForTelegram(markdown, dependencies.markdownToHtml);

export function createTelegramExtension(pi: ExtensionAPI, dependencies: Dependencies) {
  const token = process.env.TELEGRAM_BOT_TOKEN?.trim();
  const configuredChatId = Number(process.env.TELEGRAM_CHAT_ID);
  const allowedUsers = new Set(
    (process.env.TELEGRAM_ALLOWED_USER_IDS ?? String(configuredChatId)).split(",").map((id) => id.trim()),
  );
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? joinPath(homedir(), ".pi", "agent");
  const attachmentsDir = joinPath(agentDir, "tmp", "telegram");

  let bot: any;
  let active: QueuedTelegramMessage | undefined;
  let typingInterval: ReturnType<typeof setInterval> | undefined;
  let draftId = 1;
  const queue: QueuedTelegramMessage[] = [];

  const getConfiguredTelegramChatId = () => {
    if (!Number.isSafeInteger(configuredChatId) || configuredChatId === 0) {
      throw new Error("TELEGRAM_CHAT_ID is not configured");
    }

    return configuredChatId;
  };

  const getTelegramDestination = () => active?.chatId ?? getConfiguredTelegramChatId();

  const stopTyping = () => {
    if (typingInterval) clearInterval(typingInterval);
    typingInterval = undefined;
  };

  const sendTypingAction = () => {
    const client = bot;
    const chatId = active?.chatId;
    if (!client || chatId === undefined) return;

    void client.api.sendChatAction(chatId, "typing").catch((error: unknown) =>
      console.error("pi-telegram: typing status failed", error instanceof Error ? error.message : error),
    );
  };

  const startTyping = () => {
    if (typingInterval) return;
    sendTypingAction();
    typingInterval = setInterval(sendTypingAction, 3000);
  };

  const withTelegramErrorContext = async <T>(name: string, action: () => Promise<T>): Promise<T> => {
    try {
      return await action();
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      throw new Error(`Telegram ${name} failed: ${detail}`);
    }
  };

  const sendTelegramMessage = async (destination: number, markdown: string, replyTo?: number) => {
    if (!bot) throw new Error("Telegram bot is not connected");

    await dependencies.waitBeforeSend();
    const result = await withTelegramErrorContext("sendMessage", () => bot.api.sendMessage(
      destination,
      toTelegramHtml(markdown, dependencies),
      {
        parse_mode: "HTML",
        reply_parameters: replyTo ? { message_id: replyTo } : undefined,
      },
    ));
    return result;
  };

  const updateTelegramPreview = async (destination: number, markdown: string) => {
    if (!bot) throw new Error("Telegram bot is not connected");

    return withTelegramErrorContext("sendMessageDraft", () => (bot.api.raw as any).sendMessageDraft({
      chat_id: destination,
      draft_id: draftId,
      text: toTelegramHtml(markdown, dependencies),
      parse_mode: "HTML",
    }));
  };

  const downloadTelegramAttachment = async (fileId: string, fileName: string) => {
    if (!bot) throw new Error("Telegram bot is not connected");

    const file = await bot.api.getFile(fileId);
    if (!file.file_path || (file.file_size ?? 0) > 20 * 1024 * 1024) {
      throw new Error("Telegram attachment is missing or exceeds the 20 MB download limit");
    }

    await mkdir(attachmentsDir, { recursive: true, mode: 0o700 });
    const extension = extname(fileName).replace(/[^.\w-]/g, "").slice(0, 16);
    const path = joinPath(attachmentsDir, `${randomUUID()}${extension}`);
    await file.download(path);

    const bytes = await readFile(path);
    return { path, mimeType: await detectMimeType(bytes, dependencies.detectFileType), bytes };
  };

  const startTelegramTurn = (message: QueuedTelegramMessage) => {
    active = message;
    draftId = Math.floor(Math.random() * 2_000_000_000) + 1;

    const content = [
      { type: "text" as const, text: `[Telegram] ${message.prompt}` },
      ...message.images,
    ];

    pi.sendUserMessage(content, { deliverAs: "followUp" });
  };

  const processNextQueuedTelegramMessage = () => {
    if (active || queue.length === 0) return;
    startTelegramTurn(queue.shift()!);
  };

  const enqueueTelegramMessage = (message: QueuedTelegramMessage) => {
    queue.push(message);
    processNextQueuedTelegramMessage();
  };

  const handleIncomingTelegramMessage = async (ctx: any) => {
    const message = ctx.message;
    const sender = ctx.from;
    if (message.chat.type !== "private" || !sender || !allowedUsers.has(String(sender.id))) return;

    if (message.text === "/start") return ctx.reply("Pi is connected. Send me a message.");
    if (message.text === "/stop") {
      pi.abort();
      return ctx.reply("Stopped.");
    }

    const reply = message.reply_to_message?.text ?? message.reply_to_message?.caption;
    const body = message.text ?? message.caption ?? "Please inspect the attached file.";
    const pending: QueuedTelegramMessage = {
      chatId: message.chat.id,
      replyTo: message.message_id,
      prompt: buildTelegramPrompt(body, reply),
      images: [],
    };
    const media = message.photo?.at(-1)
      ?? message.document
      ?? message.audio
      ?? message.voice
      ?? message.video
      ?? message.animation;

    if (media) {
      const fileName = "file_name" in media ? media.file_name ?? "attachment" : "photo.jpg";
      const file = await downloadTelegramAttachment(media.file_id, fileName);
      if (isInlineImage(file.mimeType)) {
        pending.images.push({
          type: "image",
          data: Buffer.from(file.bytes).toString("base64"),
          mimeType: file.mimeType,
        });
      } else {
        pending.prompt = buildTelegramPrompt(body, reply, file.path);
      }
    }

    enqueueTelegramMessage(pending);
  };

  const startTelegramBot = () => {
    if (bot) return;
    if (!token) {
      console.error("pi-telegram: TELEGRAM_BOT_TOKEN is not set");
      return;
    }

    const client = dependencies.createBot(token);
    client.api.config.use(dependencies.createFileDownloader(token));
    client.api.config.use(dependencies.createRetryTransformer());
    client.catch(({ error }: any) => console.error("pi-telegram: update failed", error.message));
    client.on("message", handleIncomingTelegramMessage);
    bot = client;

    void client.start().catch((error: unknown) => {
      if (bot === client) bot = undefined;
      console.error("pi-telegram: polling stopped", error instanceof Error ? error.message : error);
    });
  };

  const stopTelegramBot = async () => {
    const client = bot;
    bot = undefined;
    stopTyping();
    active = undefined;
    queue.length = 0;
    if (client) await client.stop();
  };

  pi.registerTool({
    name: "telegram_update_preview",
    label: "Telegram preview",
    description: "Update the temporary Telegram draft with a short, useful answer or progress for the current stage.",
    parameters: dependencies.Type.Object({
      text: dependencies.Type.String({ description: "A concise update, at most two sentences" }),
    }),
    async execute(_id: string, { text }: { text: string }) {
      await updateTelegramPreview(getTelegramDestination(), text);
      return { content: [{ type: "text", text: "Telegram preview updated." }], details: undefined };
    },
  });

  pi.registerTool({
    name: "telegram_send_message",
    label: "Send Telegram message",
    description: "Send a permanent, concise stage result or cron notification.",
    parameters: dependencies.Type.Object({
      reply: dependencies.Type.Optional(dependencies.Type.Boolean({ description: "Reply to the current Telegram message when context benefits from a reply bubble" })),
      text: dependencies.Type.String({ description: "A complete user-facing message" }),
    }),
    async execute(_id: string, { text, reply }: { text: string; reply?: boolean }) {
      await sendTelegramMessage(getTelegramDestination(), text, reply ? active?.replyTo : undefined);
      return { content: [{ type: "text", text: "Telegram message sent." }], details: undefined };
    },
  });

  pi.registerTool({
    name: "telegram_attach",
    label: "Send Telegram file",
    description: "Send a local file to the configured Telegram chat, optionally as a reply to the current message.",
    parameters: dependencies.Type.Object({
      path: dependencies.Type.String({ description: "Path to the file to send" }),
      caption: dependencies.Type.Optional(dependencies.Type.String({ description: "Optional short caption" })),
      reply: dependencies.Type.Optional(dependencies.Type.Boolean({ description: "Reply to the current Telegram message when the attachment is specifically about it" })),
    }),
    async execute(_id: string, { path, caption, reply }: { path: string; caption?: string; reply?: boolean }) {
      if (!bot) throw new Error("Telegram bot is not connected");
      const filePath = await realpath(path);
      const info = await stat(filePath);
      if (!info.isFile() || info.size > 50 * 1024 * 1024) {
        throw new Error("File must be regular and smaller than 50 MB");
      }

      await dependencies.waitBeforeSend();
      const replyTo = reply ? active?.replyTo : undefined;
      await withTelegramErrorContext("sendDocument", () => bot.api.sendDocument(
        getTelegramDestination(),
        dependencies.createInputFile(createReadStream(filePath), basename(filePath)),
        {
          caption: caption ? toTelegramHtml(caption, dependencies) : undefined,
          parse_mode: caption ? "HTML" : undefined,
          reply_parameters: replyTo ? { message_id: replyTo } : undefined,
        },
      ));

      return { content: [{ type: "text", text: "Telegram file sent." }], details: undefined };
    },
  });

  pi.on("session_start", startTelegramBot);
  pi.on("session_shutdown", stopTelegramBot);
  pi.on("message_update", (event: any) => {
    const update = event.assistantMessageEvent;
    if (active && (update.type === "text_start" || (update.type === "text_delta" && update.delta))) {
      startTyping();
    } else {
      stopTyping();
    }
  });
  pi.on("message_end", stopTyping);
  pi.on("before_agent_start", (event: any) => {
    event.systemPromptOptions.sections.telegram = instructions;
  });
  pi.on("agent_end", async (event: any) => {
    stopTyping();
    if (!active) return;

    const destination = active.chatId;
    const text = extractFinalAssistantText(event.messages);
    try {
      if (text) await sendTelegramMessage(destination, text);
    } finally {
      active = undefined;
      processNextQueuedTelegramMessage();
    }
  });
}

export default async function (pi: ExtensionAPI) {
  const { Type } = await import("@earendil-works/pi-ai");
  createTelegramExtension(pi, { ...defaultDependencies, Type });
}
