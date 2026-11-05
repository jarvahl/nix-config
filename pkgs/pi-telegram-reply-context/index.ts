import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const REMINDER =
  "<hint>For an unclear Telegram reply, search the quoted reply text, then inspect the matching session file and nearby messages recursively.</hint>";

export default function telegramReplyContext(pi: ExtensionAPI): void {
  pi.on("before_agent_start", (event) => {
    if (event.prompt.trimStart().startsWith("[telegram]") && event.prompt.includes("reply_to_message_id=")) {
      event.systemPromptOptions.sections.telegram_reply_context = REMINDER;
    } else {
      delete event.systemPromptOptions.sections.telegram_reply_context;
    }
  });
}
