import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export const DEFAULT_IDLE_MINUTES = 5;

export function idleTimeoutMs(value = process.env.PI_IDLE_SESSION_MINUTES): number {
  const minutes = Number(value);
  return Number.isSafeInteger(minutes) && minutes > 0 ? minutes * 60_000 : DEFAULT_IDLE_MINUTES * 60_000;
}

export default function (pi: ExtensionAPI): void {
  const timeout = idleTimeoutMs();
  let timer: ReturnType<typeof setTimeout> | undefined;
  let hadActivity = false;

  function clearTimer(): void {
    if (timer) clearTimeout(timer);
    timer = undefined;
  }

  function armTimer(ctx: Pick<ExtensionContext, "isIdle" | "hasPendingMessages">): void {
    clearTimer();
    if (!hadActivity) return;

    timer = setTimeout(() => {
      timer = undefined;
      if (!ctx.isIdle() || ctx.hasPendingMessages()) {
        armTimer(ctx);
        return;
      }
      hadActivity = false;
      pi.events.emit("pi_idle", { ctx });
    }, timeout);
  }

  pi.on("input", () => {
    hadActivity = true;
    clearTimer();
  });

  pi.on("agent_settled", (_event, ctx) => {
    armTimer(ctx);
  });

  pi.on("session_start", () => {
    clearTimer();
    hadActivity = false;
  });

  pi.on("session_shutdown", () => {
    clearTimer();
  });
}
