import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const COMMAND = "pi-idle-new-session";

export default function idleNewSession(pi: ExtensionAPI): void {
  let rotationRequested = false;

  pi.events.on("pi_idle", () => {
    if (rotationRequested) return;
    rotationRequested = true;
    void pi.sendUserMessage(`/${COMMAND}`, { expandPromptTemplates: true }).catch(() => {
      rotationRequested = false;
    });
  });

  pi.registerCommand(COMMAND, {
    description: "Start a fresh session after an idle timeout",
    handler: async (_args, ctx: ExtensionContext) => {
      if (!rotationRequested) return;
      rotationRequested = false;
      if (!ctx.isIdle() || ctx.hasPendingMessages()) return;
      const result = await ctx.newSession();
      if (result.cancelled) rotationRequested = false;
    },
  });

  pi.on("session_start", () => {
    rotationRequested = false;
  });
}
