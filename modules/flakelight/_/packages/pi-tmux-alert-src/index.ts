import { execFileSync } from "node:child_process";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const pane = process.env.TMUX_PANE;

function tmux(...args: string[]): string {
  return execFileSync("tmux", args, { encoding: "utf8" }).trim();
}

function updateWindow(): void {
  if (!pane) return;

  try {
    const window = tmux("display-message", "-p", "-t", pane, "#{window_id}");
    const statuses = tmux(
      "list-panes",
      "-t",
      window,
      "-F",
      "#{@pi_agent}:#{@pi_status}",
    )
      .split("\n")
      .filter((status) => status.startsWith("1:"))
      .map((status) => status.slice(2));
    const status = statuses.includes("working")
      ? "working"
      : statuses.includes("unread")
        ? "unread"
        : statuses.length > 0
          ? "idle"
          : "";

    tmux("set-option", "-w", "-t", window, "@pi_window_status", status);
    tmux("refresh-client", "-S");
  } catch {
    // Pi can also run outside tmux or while its pane is being destroyed.
  }
}

function setStatus(status: "working" | "unread" | "idle"): void {
  if (!pane) return;

  try {
    tmux("set-option", "-p", "-t", pane, "@pi_agent", "1");
    tmux("set-option", "-p", "-t", pane, "@pi_status", status);
    updateWindow();
  } catch {
    // Pi can also run outside tmux or while its pane is being destroyed.
  }
}

export default function (pi: ExtensionAPI): void {
  if (!pane) return;

  setStatus("idle");
  pi.on("agent_start", async () => setStatus("working"));
  pi.on("agent_settled", async () => setStatus("unread"));
  pi.on("session_shutdown", async () => {
    try {
      tmux("set-option", "-p", "-u", "-t", pane, "@pi_agent");
      tmux("set-option", "-p", "-u", "-t", pane, "@pi_status");
      updateWindow();
    } catch {
      // The pane may already be gone during shutdown.
    }
  });
}
