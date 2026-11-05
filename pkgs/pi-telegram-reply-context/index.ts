import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const RECENT_REMINDER =
  "<hint>For a very short or ambiguous Telegram message, treat it as a continuation and inspect the latest messages from recent session files before answering.</hint>";
const REPLY_REMINDER =
  "<hint>For an unclear Telegram reply, search the quoted reply text, then inspect the matching session file and nearby messages recursively.</hint>";

export default function telegramReplyContext(pi: ExtensionAPI): void {
  pi.on("before_agent_start", (event) => {
    const prompt = event.prompt.trimStart();
    const isTelegram = prompt.startsWith("[telegram]");
    const message = prompt.replace(/^\[telegram\]\s+chat_id=\S+\s+message_id=\S+(?:\s+reply_to_message_id=\S+)?\s*/, "").trim();
    const isShort = message.length <= 24;

    delete event.systemPromptOptions.sections.telegram_reply_context;
    delete event.systemPromptOptions.sections.telegram_recent_context;
    if (!isTelegram) return;
    if (prompt.includes("reply_to_message_id=")) {
      event.systemPromptOptions.sections.telegram_reply_context = REPLY_REMINDER;
    }
    if (isShort) {
      event.systemPromptOptions.sections.telegram_recent_context = RECENT_REMINDER;
    }
  });
}
