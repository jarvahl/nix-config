import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { mdgram } from "@borodin/mdgram";
import { fileTypeFromBuffer } from "file-type";
import {
  buildTelegramPrompt,
  createTelegramExtension,
  detectMimeType,
  extractFinalAssistantText,
  extractMessageText,
  isInlineImage,
  renderMarkdownForTelegram,
} from "./index.ts";

const Type = {
  Object: (properties: unknown) => properties,
  Optional: (schema: unknown) => schema,
  Boolean: () => ({ type: "boolean" }),
  String: () => ({ type: "string" }),
};

function setupExtension() {
  const handlers: Record<string, (...args: any[]) => any> = {};
  const tools: Record<string, any> = {};
  const sentMessages: any[] = [];
  const sentDocuments: any[] = [];
  const typingActions: any[] = [];
  const previews: any[] = [];
  const turns: any[] = [];
  const commands: string[] = [];
  const downloaded = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/xN8AAAAASUVORK5CYII=", "base64");

  const bot = {
    token: process.env.TELEGRAM_BOT_TOKEN,
    api: {
      config: { use: () => undefined },
      getFile: async () => ({
        file_path: "mock/path",
        file_size: downloaded.length,
        download: async (path: string) => writeFile(path, downloaded),
      }),
      raw: { sendMessageDraft: async (payload: unknown) => previews.push(payload) },
      sendChatAction: async (...args: unknown[]) => typingActions.push(args),
      sendDocument: async (...args: unknown[]) => sentDocuments.push(args),
      sendMessage: async (...args: unknown[]) => sentMessages.push(args),
    },
    catch: () => undefined,
    on: (_event: string, handler: (...args: any[]) => any) => { handlers.telegramMessage = handler; },
    start: async () => { handlers.started = true; },
    stop: async () => { handlers.stopped = true; },
  };
  const pi = {
    abort: () => { handlers.aborted = true; },
    on: (event: string, handler: (...args: any[]) => any) => { handlers[event] = handler; },
    registerCommand: (name: string) => commands.push(name),
    registerTool: (tool: any) => { tools[tool.name] = tool; },
    sendUserMessage: (content: unknown, options: unknown) => turns.push({ content, options }),
  };

  const oldEnv = {
    TELEGRAM_BOT_TOKEN: process.env.TELEGRAM_BOT_TOKEN,
    TELEGRAM_CHAT_ID: process.env.TELEGRAM_CHAT_ID,
    TELEGRAM_ALLOWED_USER_IDS: process.env.TELEGRAM_ALLOWED_USER_IDS,
    PI_CODING_AGENT_DIR: process.env.PI_CODING_AGENT_DIR,
  };
  process.env.TELEGRAM_BOT_TOKEN = "test-token";
  process.env.TELEGRAM_CHAT_ID = "1001";
  process.env.TELEGRAM_ALLOWED_USER_IDS = "42";

  const temporaryDirectory = mkdtemp(join(tmpdir(), "pi-telegram-test-"));
  const extension = temporaryDirectory.then((directory) => {
    process.env.PI_CODING_AGENT_DIR = directory;
    createTelegramExtension(pi as any, {
      Type,
      createBot: () => bot,
      createInputFile: (stream, fileName) => ({ stream, fileName }),
      createRetryTransformer: () => ({}),
      createFileDownloader: () => ({}),
      detectFileType: fileTypeFromBuffer,
      markdownToHtml: mdgram,
      waitBeforeSend: async () => undefined,
    });
    return directory;
  });

  return {
    cleanup: async () => {
      const directory = await extension;
      if (handlers.session_shutdown) await handlers.session_shutdown();
      await rm(directory, { recursive: true, force: true });
      for (const [name, value] of Object.entries(oldEnv)) {
        if (value === undefined) delete process.env[name];
        else process.env[name] = value;
      }
    },
    extension,
    handlers,
    previews,
    sentDocuments,
    sentMessages,
    tools,
    turns,
    typingActions,
    commands,
  };
}

test("normalizes and extracts Telegram/ Pi message content", () => {
  assert.equal(renderMarkdownForTelegram("Hello **world**"), "Hello <b>world</b>");
  assert.equal(renderMarkdownForTelegram("Status: **checking"), "Status: <b>checking</b>");
  assert.equal(extractMessageText({ content: [
    { type: "text", text: "First" },
    { type: "image", data: "ignored" },
    { type: "text", text: " second" },
  ] }), "First second");
  assert.equal(extractFinalAssistantText([
    { role: "assistant", content: [{ type: "text", text: "Stage result" }] },
    { role: "toolResult", content: [{ type: "text", text: "Tool output" }] },
    { role: "assistant", content: [{ type: "text", text: "Final result" }] },
  ]), "Final result");
});

test("builds reply context and detects attachment MIME from contents", async () => {
  assert.equal(
    buildTelegramPrompt("Please explain", "Earlier answer", "/tmp/report.pdf"),
    "Replying to Telegram message:\n> Earlier answer\n\nPlease explain\n\nTelegram attachment saved at: /tmp/report.pdf",
  );
  assert.equal(await detectMimeType(Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/xN8AAAAASUVORK5CYII=", "base64")), "image/png");
  assert.equal(isInlineImage("image/png"), true);
  assert.equal(isInlineImage("application/pdf"), false);
});

test("lets the model choose a single contextual reply and disconnects automatically", async (t) => {
  const app = setupExtension();
  t.after(app.cleanup);

  await app.extension;
  app.handlers.session_start();
  await Promise.resolve();
  assert.equal(app.handlers.started, true);
  assert.deepEqual(app.commands, []);

  await app.handlers.telegramMessage({
    from: { id: 42 },
    message: {
      chat: { id: 1001, type: "private" },
      message_id: 17,
      text: "Please inspect this",
      reply_to_message: { text: "Earlier bot answer" },
    },
    reply: async () => undefined,
  });

  await app.handlers.telegramMessage({
    from: { id: 42 },
    message: { chat: { id: 1001, type: "private" }, message_id: 18, text: "Second request" },
  });

  assert.equal(app.turns.length, 1);
  assert.equal(app.turns[0].options.deliverAs, "followUp");
  assert.match(app.turns[0].content[0].text, /> Earlier bot answer/);

  app.handlers.message_update({ assistantMessageEvent: { type: "thinking_delta", delta: "private reasoning" } });
  assert.equal(app.typingActions.length, 0);
  app.handlers.message_update({ assistantMessageEvent: { type: "text_start" } });
  assert.deepEqual(app.typingActions, [[1001, "typing"]]);
  app.handlers.message_update({ assistantMessageEvent: { type: "text_delta", delta: "I found" } });
  assert.equal(app.typingActions.length, 1);
  app.handlers.message_update({ assistantMessageEvent: { type: "toolcall_start" } });

  await app.tools.telegram_update_preview.execute("call-1", { text: "I found the issue." });
  assert.match(app.previews[0].text, /I found the issue/);
  assert.equal(app.previews[0].chat_id, 1001);

  await app.tools.telegram_send_message.execute("call-2", { text: "The fix passes.", reply: true });
  assert.equal(app.sentMessages[0][2].reply_parameters.message_id, 17);

  await app.handlers.agent_end({ messages: [{ role: "assistant", content: [{ type: "text", text: "All done." }] }] });
  assert.equal(app.sentMessages[1][2].reply_parameters, undefined);
  assert.equal(app.turns.length, 2);
  assert.match(app.turns[1].content[0].text, /Second request/);

  await app.handlers.agent_end({ messages: [{ role: "assistant", content: [{ type: "text", text: "Second answer." }] }] });
  assert.equal(app.sentMessages[2][2].reply_parameters, undefined);

  await app.handlers.session_shutdown();
  assert.equal(app.handlers.stopped, true);
});

test("ignores messages from users outside the allowlist", async (t) => {
  const app = setupExtension();
  t.after(app.cleanup);

  await app.extension;
  app.handlers.session_start();
  await app.handlers.telegramMessage({
    from: { id: 99 },
    message: { chat: { id: 1001, type: "private" }, message_id: 19, text: "Not allowed" },
  });
  app.handlers.message_update({ assistantMessageEvent: { type: "text_delta", delta: "background" } });

  assert.equal(app.turns.length, 0);
  assert.equal(app.sentMessages.length, 0);
  assert.equal(app.typingActions.length, 0);
});

test("downloads image attachments and sends them to Pi as image content", async (t) => {
  const app = setupExtension();
  t.after(app.cleanup);

  await app.extension;
  app.handlers.session_start();
  await app.handlers.telegramMessage({
    from: { id: 42 },
    message: {
      chat: { id: 1001, type: "private" },
      message_id: 18,
      caption: "What is in this picture?",
      document: { file_id: "image-id", file_name: "picture.png", mime_type: "image/png" },
    },
  });

  assert.equal(app.turns[0].content[1].type, "image");
  assert.equal(app.turns[0].content[1].mimeType, "image/png");
  assert.ok(Buffer.from(app.turns[0].content[1].data, "base64").length > 0);
});

test("sends generated files through telegram_attach", async (t) => {
  const app = setupExtension();
  t.after(app.cleanup);

  const directory = await app.extension;
  await app.handlers.session_start();
  const filePath = join(directory, "report.txt");
  await writeFile(filePath, "report");

  await app.tools.telegram_attach.execute("call-3", { path: filePath, caption: "**Report**" });
  assert.equal(app.sentDocuments.length, 1);
  assert.equal(app.sentDocuments[0][0], 1001);
  assert.equal(app.sentDocuments[0][2].caption, "<b>Report</b>");
});
