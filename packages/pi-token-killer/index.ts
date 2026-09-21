import os from "node:os";
import path from "node:path";
import {
  isToolCallEventType,
  type ExtensionAPI,
} from "@mariozechner/pi-coding-agent";

const builtinDir = "@BUILTIN_DIR@";

function shellQuote(value: string): string {
  return `'${value.replaceAll("'", "'\\''")}'`;
}

export default function (pi: ExtensionAPI): void {
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;

    const configHome =
      process.env.XDG_CONFIG_HOME ?? path.join(os.homedir(), ".config");
    const inheritedPath = process.env.PATH ?? "";
    const tokenKillerPath = [
      path.join(ctx.cwd, ".pi", "token-killer"),
      path.join(configHome, "pi", "token-killer"),
      builtinDir,
      inheritedPath,
    ].join(":");

    event.input.command = `export PATH=${shellQuote(tokenKillerPath)}; ${event.input.command}`;
  });
}
