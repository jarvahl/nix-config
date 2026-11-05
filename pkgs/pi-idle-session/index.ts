import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export const COLLECT_COMMAND = "collect-idle-session";
export const DEFAULT_IDLE_MINUTES = 5;

export function idleTimeoutMs(value = process.env.PI_IDLE_SESSION_MINUTES): number {
  const minutes = Number(value);
  return Number.isSafeInteger(minutes) && minutes > 0 ? minutes * 60_000 : DEFAULT_IDLE_MINUTES * 60_000;
}

export default function (pi: ExtensionAPI): void {
  const timeout = idleTimeoutMs();
  let timer: ReturnType<typeof setTimeout> | undefined;
  let hadActivity = false;
  let rotationRequested = false;

  function clearTimer(): void {
    if (timer) clearTimeout(timer);
    timer = undefined;
  }

  function armTimer(ctx: Pick<ExtensionContext, "isIdle" | "hasPendingMessages">): void {
    clearTimer();
    if (!hadActivity) return;

    timer = setTimeout(() => {
      timer = undefined;
      if (!ctx.isIdle() || ctx.hasPendingMessages()) return;
      rotationRequested = true;
      void pi.sendUserMessage(`/${COLLECT_COMMAND}`, { expandPromptTemplates: true }).catch((error: unknown) => {
        rotationRequested = false;
        armTimer(ctx);
        console.error("pi-idle-session: failed to dispatch session rotation", error);
      });
    }, timeout);
  }

  pi.registerCommand(COLLECT_COMMAND, {
    description: "Start a fresh session after an idle timeout",
    handler: async (_args, ctx) => {
      if (!rotationRequested) return;
      rotationRequested = false;
      if (!hadActivity || !ctx.isIdle() || ctx.hasPendingMessages()) {
        armTimer(ctx);
        return;
      }

      clearTimer();
      hadActivity = false;
      try {
        const result = await ctx.newSession();
        if (result.cancelled) {
          hadActivity = true;
          armTimer(ctx);
        }
      } catch (error) {
        hadActivity = true;
        armTimer(ctx);
        throw error;
      }
    },
  });

  pi.on("input", (event) => {
    if (event.text.trim() === `/${COLLECT_COMMAND}`) return;
    hadActivity = true;
    clearTimer();
  });

  pi.on("agent_settled", (_event, ctx) => {
    armTimer(ctx);
  });

  pi.on("session_start", () => {
    clearTimer();
    hadActivity = false;
    rotationRequested = false;
  });

  pi.on("session_shutdown", () => {
    clearTimer();
    rotationRequested = false;
  });
}
