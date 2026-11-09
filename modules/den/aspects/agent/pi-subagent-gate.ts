import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let consulted = false;
  const pending = new Set<string>();

  pi.on("agent_start", () => {
    consulted = false;
    pending.clear();
  });

  pi.on("tool_call", (event: any) => {
    if (event.toolName === "Agent") {
      if (event.input?.run_in_background !== false) {
        return {
          block: true,
          reason: "Run a relevant subagent in the foreground and use its result before continuing. Do not run this consultation in the background.",
        };
      }
      // A foreground Agent call blocks the model until its result is returned.
      // Mark it as consulted here so the next model step can send the response.
      consulted = true;
      pending.add(event.toolCallId);
      return;
    }

    if (event.toolName !== "matrix_send_message" || consulted) return;
    return {
      block: true,
      reason: "Consult at least one relevant subagent in the foreground and use its result before sending the Matrix response.",
    };
  });

  pi.on("tool_result", (event: any) => {
    if (!pending.delete(event.toolCallId) || event.isError) return;
    consulted = true;
  });
}
