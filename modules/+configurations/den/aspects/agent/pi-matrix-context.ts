import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const matrixHint = /\n?\[Matrix (?:event|thread): [^\]\r\n]+\]/g;

export default function (pi: ExtensionAPI) {
  pi.on("context", (event: any) => {
    // Matrix prompts already contain the room metadata and recent room history.
    // Do not expose previous Matrix turns (possibly from another room) to this
    // request. This gives every incoming Matrix message an isolated turn while
    // keeping the current turn's tool calls and continuations intact.
    const currentMatrixTurn = [...event.messages].findLastIndex((message: any) =>
      message.role === "user" && [...(message.content ?? [])].some(
        (part: any) => part.type === "text" && /\[Matrix (?:event|thread): room_id=/.test(part.text ?? ""),
      ),
    );
    if (currentMatrixTurn >= 0) event.messages = event.messages.slice(currentMatrixTurn);

    let total = 0;
    for (const message of event.messages) {
      for (const part of message.content ?? []) {
        if (part.type === "text" && typeof part.text === "string") {
          total += [...part.text.matchAll(matrixHint)].length;
        }
      }
    }
    let seen = 0;
    let latestTextPart: any;
    for (const message of event.messages) {
      for (const part of message.content ?? []) {
        if (part.type === "text" && typeof part.text === "string") {
          part.text = part.text.replace(matrixHint, (hint: string) => {
            if (++seen !== total) return "";
            latestTextPart = part;
            return hint;
          });
        }
      }
    }
    if (latestTextPart) {
      latestTextPart.text += "\n[Matrix reply: keep brief; split independent points.]";
    }
  });
}
